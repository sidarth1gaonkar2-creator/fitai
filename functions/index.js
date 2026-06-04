/**
 * AtlasFit / DrillFit — server-side AI proxy.
 *
 * Why this exists: the Anthropic API key must NEVER ship inside the mobile app
 * bundle (anyone can unzip an IPA/APK and extract it). This Cloud Function holds
 * the key in Google Secret Manager and is the only thing that ever sees it. The
 * app calls THIS endpoint with its Firebase Auth ID token; we verify the user is
 * a real signed-in app user, then forward the request to Anthropic and stream
 * the response straight back (works for both SSE streaming and one-shot JSON).
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

      // 1. Require a valid Firebase ID token. This is what stops a stranger who
      //    finds the URL from spending your Anthropic credits.
      const authz = req.get("authorization") || "";
      const match = authz.match(/^Bearer (.+)$/i);
      if (!match) {
        res.status(401).json({error: {message: "Missing auth token"}});
        return;
      }
      try {
        await admin.auth().verifyIdToken(match[1]);
      } catch (err) {
        logger.warn("Rejected request with invalid ID token");
        res.status(401).json({error: {message: "Invalid auth token"}});
        return;
      }

      // 2. Forward to Anthropic with the server-side key, streaming the body
      //    through unchanged so the client's existing SSE parser just works.
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
        res.status(502).json({error: {message: "Upstream request failed"}});
        return;
      }

      res.status(upstream.status);
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
