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

// ---------------------------------------------------------------------------
// AI Coach tool use (Build 75)
//
// Two tools the model may PROPOSE — never auto-applied. The app renders a
// confirmation card and only an explicit user tap writes data. Definitions live
// here, server-side, so the schema is single-sourced and the client never holds
// it. Injected into every request below.
// ---------------------------------------------------------------------------
const TOOLS = [
  {
    name: "update_nutrition_goals",
    description:
      "Propose new daily nutrition targets for the user to review. NEVER " +
      "applied automatically — the app shows a confirmation card and only an " +
      "explicit user tap saves them. Call this only when the user asks to " +
      "change their goals/targets.",
    input_schema: {
      type: "object",
      properties: {
        calories: {type: "integer", description: "Daily calorie target (kcal)"},
        proteinG: {type: "integer", description: "Daily protein target (g)"},
        carbsG: {type: "integer", description: "Daily carbohydrate target (g)"},
        fatG: {type: "integer", description: "Daily fat target (g)"},
        rationale: {
          type: "string",
          description: "Short, in-character reason for the change.",
        },
      },
      required: ["calories", "proteinG", "carbsG", "fatG", "rationale"],
    },
  },
  {
    name: "create_workout",
    description:
      "Propose a workout for the user to review and start. NEVER applied " +
      "automatically. Derive suggestedWeightKg from the user's actual lift " +
      "history (~80-90% of a recent best for the rep range); use null when " +
      "there is no history for an exercise. Call this only when the user asks " +
      "for a workout or plan.",
    input_schema: {
      type: "object",
      properties: {
        name: {type: "string"},
        focus: {type: "string"},
        exercises: {
          type: "array",
          items: {
            type: "object",
            properties: {
              exerciseName: {type: "string"},
              sets: {type: "integer"},
              reps: {type: "integer"},
              suggestedWeightKg: {type: ["number", "null"]},
              restSeconds: {type: "integer"},
              notes: {type: ["string", "null"]},
            },
            required: ["exerciseName", "sets", "reps", "restSeconds"],
          },
        },
        rationale: {type: "string"},
      },
      required: ["name", "focus", "exercises", "rationale"],
    },
  },
];

const TOOL_NAMES = new Set(TOOLS.map((t) => t.name));

// update_nutrition_goals clamp bounds: [min, max].
const NUTRITION_BOUNDS = {
  calories: [1200, 6000],
  proteinG: [30, 400],
  carbsG: [0, 800],
  fatG: [20, 300],
};
const MAX_EXERCISES = 12;
const MAX_SETS = 10;
const MAX_REPS = 50;

// Shown (as plain assistant text) when a tool_use is rejected, so the user gets
// a graceful reply instead of a broken/blocked card. Stays in character.
const TOOL_REJECTED_TEXT =
  "Belay that — those numbers were out of safe range, so I won't push that " +
  "change. Tell me what you're after and I'll redraw it.";

function clampInt(value, bounds) {
  const n = Math.round(Number(value));
  if (!Number.isFinite(n)) return null;
  return Math.min(bounds[1], Math.max(bounds[0], n));
}

// Validates + sanitizes a completed tool_use input. Returns {ok:true, input}
// with the cleaned input to forward, or {ok:false, reason} to reject (→ apology
// text). Nutrition values are CLAMPED into range; workouts are REJECTED when
// structurally out of bounds.
function validateToolInput(name, input) {
  if (!TOOL_NAMES.has(name)) return {ok: false, reason: "unknown tool"};
  if (input == null || typeof input !== "object") {
    return {ok: false, reason: "non-object input"};
  }

  if (name === "update_nutrition_goals") {
    const out = {};
    for (const key of ["calories", "proteinG", "carbsG", "fatG"]) {
      const c = clampInt(input[key], NUTRITION_BOUNDS[key]);
      if (c === null) return {ok: false, reason: `missing/invalid ${key}`};
      out[key] = c;
    }
    out.rationale = typeof input.rationale === "string" ? input.rationale : "";
    return {ok: true, input: out};
  }

  // create_workout
  const exercises = Array.isArray(input.exercises) ? input.exercises : null;
  if (!exercises || exercises.length === 0) {
    return {ok: false, reason: "no exercises"};
  }
  if (exercises.length > MAX_EXERCISES) {
    return {ok: false, reason: ">12 exercises"};
  }
  for (const ex of exercises) {
    if (!ex || typeof ex.exerciseName !== "string" || !ex.exerciseName.trim()) {
      return {ok: false, reason: "bad exerciseName"};
    }
    const sets = Number(ex.sets);
    const reps = Number(ex.reps);
    if (!Number.isInteger(sets) || sets < 1 || sets > MAX_SETS) {
      return {ok: false, reason: "sets out of range"};
    }
    if (!Number.isInteger(reps) || reps < 1 || reps > MAX_REPS) {
      return {ok: false, reason: "reps out of range"};
    }
  }
  return {ok: true, input};
}

// Write one Anthropic-style SSE data line. The client parses only `data:` lines
// (keyed by the `type` field inside), so this is all it needs.
function sseData(res, obj) {
  res.write(`data: ${JSON.stringify(obj)}\n\n`);
}

// Emits a validated tool_use as a normalized 3-event sequence carrying the
// SANITIZED input in one input_json_delta — so the client receives exactly the
// clamped/validated values, not the model's raw ones.
function emitToolUse(res, index, id, name, input) {
  sseData(res, {
    type: "content_block_start",
    index,
    content_block: {type: "tool_use", id, name, input: {}},
  });
  sseData(res, {
    type: "content_block_delta",
    index,
    delta: {type: "input_json_delta", partial_json: JSON.stringify(input)},
  });
  sseData(res, {type: "content_block_stop", index});
}

// Emits the rejection apology as a normal text delta so it lands in the chat
// like any other assistant text.
function emitApology(res, index) {
  sseData(res, {
    type: "content_block_delta",
    index,
    delta: {type: "text_delta", text: TOOL_REJECTED_TEXT},
  });
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

      // 4. Forward to Anthropic with the server-side key. Tool definitions are
      //    injected here (not trusted from the client). disable_parallel_tool_use
      //    enforces at most one proposal per turn.
      const forwardBody = {
        ...req.body,
        tools: TOOLS,
        tool_choice: {type: "auto", disable_parallel_tool_use: true},
      };
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
          body: JSON.stringify(forwardBody),
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

      // 6. Stream the 200 response. Text deltas pass straight through (live),
      //    but each tool_use block is accumulated until its content_block_stop
      //    so the completed input is validated BEFORE the client ever sees it —
      //    rejected tools become a plain text apology. Only the tool_use block
      //    is buffered, never the whole response.
      res.status(200);
      const upstreamCt = upstream.headers.get("content-type") || "";
      const isSse = upstreamCt.includes("text/event-stream");
      res.set("content-type",
          isSse ? "text/event-stream" : (upstreamCt || "application/json"));
      res.set("cache-control", "no-cache");
      if (typeof res.flushHeaders === "function") res.flushHeaders();

      if (upstream.body && !isSse) {
        // Non-streaming JSON (the client's sendMessage fallback). Pass through
        // raw; any tool_use here is validated client-side.
        const reader = upstream.body.getReader();
        try {
          for (;;) {
            const {done, value} = await reader.read();
            if (done) break;
            res.write(Buffer.from(value));
          }
        } catch (err) {
          logger.error("Error streaming upstream JSON body", err);
        }
      } else if (upstream.body) {
        const reader = upstream.body.getReader();
        const decoder = new TextDecoder();
        const openTools = {}; // index -> { id, name, json }
        let buffer = "";

        const handleEvent = (event) => {
          const type = event && event.type;
          const index = event && event.index;

          if (type === "content_block_start") {
            const cb = event.content_block || {};
            if (cb.type === "tool_use") {
              // Hold the whole block until stop so we can validate it.
              openTools[index] = {id: cb.id, name: cb.name, json: ""};
              return;
            }
            sseData(res, event);
            return;
          }

          if (type === "content_block_delta") {
            const open = openTools[index];
            if (open) {
              if (event.delta && event.delta.type === "input_json_delta") {
                open.json += event.delta.partial_json || "";
              }
              return; // hold tool input until stop
            }
            sseData(res, event);
            return;
          }

          if (type === "content_block_stop") {
            const open = openTools[index];
            if (open) {
              delete openTools[index];
              let parsed = null;
              try {
                parsed = open.json ? JSON.parse(open.json) : {};
              } catch (_) {
                parsed = null;
              }
              const result = parsed == null ?
                {ok: false, reason: "unparseable input"} :
                validateToolInput(open.name, parsed);
              if (result.ok) {
                emitToolUse(res, index, open.id, open.name, result.input);
              } else {
                logger.warn("Rejected tool_use", {
                  name: open.name,
                  reason: result.reason,
                });
                emitApology(res, index);
              }
              return;
            }
            sseData(res, event);
            return;
          }

          // message_start / message_delta / message_stop / ping / error
          sseData(res, event);
        };

        try {
          for (;;) {
            const {done, value} = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, {stream: true});
            let nl;
            while ((nl = buffer.indexOf("\n")) !== -1) {
              const line = buffer.slice(0, nl).trim();
              buffer = buffer.slice(nl + 1);
              if (!line.startsWith("data:")) continue;
              const data = line.slice(5).trim();
              if (!data || data === "[DONE]") continue;
              let event;
              try {
                event = JSON.parse(data);
              } catch (_) {
                continue; // ignore non-JSON keep-alives
              }
              handleEvent(event);
            }
          }
        } catch (err) {
          logger.error("Error streaming upstream body", err);
        }
      }
      res.end();
    },
);
