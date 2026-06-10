/**
 * AtlasFit / DrillFit — server-side AI proxy.
 *
 * Why this exists: the Anthropic API key must NEVER ship inside the mobile app
 * bundle (anyone can unzip an IPA/APK and extract it). This Cloud Function holds
 * the key in Google Secret Manager and is the only thing that ever sees it. The
 * app calls THIS endpoint with its Firebase Auth ID token; we verify the user is
 * a real signed-in app user, meter their usage, then forward the request to
 * Anthropic and stream the response straight back (works for both SSE streaming
 * and one-shot JSON).
 *
 * Guard rails on every request:
 *   1. Firebase ID token required (a stranger who finds the URL can't spend
 *      your Anthropic credits).
 *   2. Payload validation — non-empty messages array, combined content
 *      <= 50,000 chars, system prompt <= 10,000 chars.
 *   3. Per-user daily rate limit (30/day) enforced in a Firestore transaction
 *      BEFORE the upstream call, so concurrent requests can't race past the cap.
 *   4. Anthropic errors are logged server-side but NEVER forwarded raw to the
 *      client — the app only ever sees a generic message.
 *
 * Deploy:
 *   1. Blaze (pay-as-you-go) plan is required — Functions can't call external
 *      APIs on the free Spark plan.
 *   2. cd functions && npm install
 *   3. firebase functions:secrets:set ANTHROPIC_API_KEY   (paste the NEW key)
 *   4. firebase deploy --only functions:aiProxy
 *   5. Put the printed URL into assets/.env as AI_PROXY_URL=... and rebuild.
 */

const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

// Abuse / cost controls.
const DAILY_LIMIT = 30; // max AI Coach calls per user per UTC day
const MAX_TOTAL_CONTENT_CHARS = 50000; // combined length of all message content
const MAX_SYSTEM_CHARS = 10000;

// Sentinel so the rate-limit transaction can distinguish "user hit their daily
// cap" (a 429 we surface to the client) from any other Firestore failure (a 500
// we keep generic).
class RateLimitError extends Error {}

// UTC calendar day, e.g. "2026-06-10". UTC keeps the reset boundary
// deterministic and matches our rule of storing timestamps in UTC.
function utcDay() {
  return new Date().toISOString().slice(0, 10);
}

exports.aiProxy = onRequest(
    {
      secrets: [ANTHROPIC_API_KEY],
      region: "us-central1",
      timeoutSeconds: 120,
      memory: "256MiB",
      // Mobile clients only — no browser, so no CORS surface to open up.
      cors: false,
      // Cap fan-out so a runaway client can't rack up unbounded cost.
      maxInstances: 10,
    },
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).json({error: {message: "Method not allowed"}});
        return;
      }

      // 1. Require a valid Firebase ID token, and capture the uid so we can
      //    meter usage per user. This is what stops a stranger who finds the
      //    URL from spending your Anthropic credits.
      const authz = req.get("authorization") || "";
      const match = authz.match(/^Bearer (.+)$/i);
      if (!match) {
        res.status(401).json({error: {message: "Missing auth token"}});
        return;
      }
      let uid;
      try {
        const decoded = await admin.auth().verifyIdToken(match[1]);
        uid = decoded.uid;
      } catch (err) {
        logger.warn("Rejected request with invalid ID token");
        res.status(401).json({error: {message: "Invalid auth token"}});
        return;
      }

      // 2. Validate the payload BEFORE spending a rate-limit slot or any
      //    Anthropic credits. The body is the Anthropic Messages request; never
      //    trust it just because the caller authenticated.
      const body = req.body || {};
      const messages = body.messages;
      if (!Array.isArray(messages) || messages.length === 0) {
        res.status(400)
            .json({error: {message: "messages must be a non-empty array"}});
        return;
      }
      let totalContent = 0;
      for (const m of messages) {
        const content = m && m.content;
        if (typeof content === "string") {
          totalContent += content.length;
        } else if (content != null) {
          // Client only ever sends strings, but be defensive about the wire.
          totalContent += JSON.stringify(content).length;
        }
      }
      if (totalContent > MAX_TOTAL_CONTENT_CHARS) {
        res.status(400).json({
          error: {
            message: `Combined message content exceeds ` +
              `${MAX_TOTAL_CONTENT_CHARS} characters`,
          },
        });
        return;
      }
      if (typeof body.system === "string" &&
          body.system.length > MAX_SYSTEM_CHARS) {
        res.status(400).json({
          error: {message: `system prompt exceeds ${MAX_SYSTEM_CHARS} characters`},
        });
        return;
      }

      // 3. Per-user daily rate limit. The read-check-increment runs inside a
      //    Firestore transaction so two concurrent requests can't both observe
      //    count=29 and both proceed — the cap holds under parallelism. We
      //    increment BEFORE calling Anthropic so the slot is consumed up front.
      const db = admin.firestore();
      const usageRef = db.collection("aiUsage").doc(uid);
      const today = utcDay();
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(usageRef);
          const sameDay = snap.exists && snap.get("date") === today;
          const count = sameDay ? (snap.get("count") || 0) : 0;
          if (count >= DAILY_LIMIT) {
            throw new RateLimitError();
          }
          // Plain set (no merge): on a new day this overwrites the stale date
          // and resets the counter to 1 in the same write.
          tx.set(usageRef, {date: today, count: count + 1});
        });
      } catch (err) {
        if (err instanceof RateLimitError) {
          res.status(429).json({
            error: {message: "Daily AI Coach limit reached. Resets at midnight."},
          });
          return;
        }
        logger.error("aiUsage rate-limit transaction failed", err);
        res.status(500)
            .json({error: {message: "AI Coach is temporarily unavailable."}});
        return;
      }

      // 4. Forward to Anthropic with the server-side key.
      let upstream;
      try {
        upstream = await fetch(ANTHROPIC_URL, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-api-key": ANTHROPIC_API_KEY.value(),
            "anthropic-version": "2023-06-01",
            ...(req.get("accept") ? {accept: req.get("accept")} : {}),
          },
          body: JSON.stringify(req.body),
        });
      } catch (err) {
        logger.error("Upstream Anthropic request failed", err);
        res.status(502)
            .json({error: {message: "AI Coach is temporarily unavailable."}});
        return;
      }

      // 5. On a non-200 from Anthropic, log the real status/body server-side but
      //    return ONLY a generic error to the client — never leak raw Anthropic
      //    error details downstream.
      if (upstream.status !== 200) {
        let errBody = "";
        try {
          errBody = await upstream.text();
        } catch (_) {
          // Body unreadable — the status alone is still useful in logs.
        }
        logger.error("Anthropic returned a non-200 response", {
          status: upstream.status,
          body: errBody.slice(0, 2000),
        });
        res.status(502)
            .json({error: {message: "AI Coach is temporarily unavailable."}});
        return;
      }

      // 6. Happy path: stream the 200 body straight through so the client's SSE
      //    parser sees tokens live (one-shot JSON passes through unchanged too).
      res.status(200);
      const contentType = upstream.headers.get("content-type");
      if (contentType) res.set("content-type", contentType);
      // Start the response immediately so SSE chunks aren't buffered.
      if (typeof res.flushHeaders === "function") res.flushHeaders();

      if (upstream.body) {
        const reader = upstream.body.getReader();
        try {
          for (;;) {
            const {done, value} = await reader.read();
            if (done) break;
            res.write(Buffer.from(value));
          }
        } catch (err) {
          logger.error("Error streaming upstream body", err);
        }
      }
      res.end();
    },
);
