import express from "express";
import twilio from "twilio";

const app = express();
app.use(express.json());

const {
  TWILIO_ACCOUNT_SID,
  TWILIO_AUTH_TOKEN,
  TWILIO_API_KEY_SID,
  TWILIO_API_KEY_SECRET,
  TWILIO_FROM_NUMBER,
  ALERTS_API_KEY,
  PORT = 8787,
} = process.env;

if (!TWILIO_ACCOUNT_SID || !TWILIO_FROM_NUMBER) {
  console.warn("Missing required env vars. Set TWILIO_ACCOUNT_SID and TWILIO_FROM_NUMBER.");
}

const hasAuthToken = Boolean(TWILIO_AUTH_TOKEN);
const hasApiKeyPair = Boolean(TWILIO_API_KEY_SID && TWILIO_API_KEY_SECRET);

if (!hasAuthToken && !hasApiKeyPair) {
  console.warn("Set either TWILIO_AUTH_TOKEN or TWILIO_API_KEY_SID + TWILIO_API_KEY_SECRET.");
}

const client = hasAuthToken
  ? twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
  : twilio(TWILIO_API_KEY_SID, TWILIO_API_KEY_SECRET, { accountSid: TWILIO_ACCOUNT_SID });

app.get("/health", (_req, res) => res.json({ ok: true }));

app.post("/api/alerts/sms", async (req, res) => {
  try {
    if (ALERTS_API_KEY) {
      const provided = req.header("x-alerts-key");
      if (provided !== ALERTS_API_KEY) return res.status(401).json({ ok: false, error: "unauthorized" });
    }

    const { to, message } = req.body ?? {};
    if (!to || !message) return res.status(400).json({ ok: false, error: "missing to/message" });

    const out = await client.messages.create({
      to,
      from: TWILIO_FROM_NUMBER,
      body: message,
    });

    return res.json({ ok: true, sid: out.sid, status: out.status });
  } catch (err) {
    return res.status(500).json({ ok: false, error: String(err) });
  }
});

app.listen(PORT, () => {
  console.log(`check-in backend listening on :${PORT}`);
});
