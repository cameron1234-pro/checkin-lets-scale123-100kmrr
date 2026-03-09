# Backend SMS Alerts Setup

The iOS app now attempts backend SMS first, then falls back to iOS SMS handoff.

## 1) Set backend endpoint in app

The app reads `UserDefaults` key:
- `backendAlertsURL`

Expected endpoint format:
- `POST https://<your-domain>/api/alerts/sms`

JSON body:
```json
{
  "to": "+15551234567",
  "message": "Check In Alert: ...",
  "source": "checkin-ios"
}
```

## 2) Minimal Twilio backend (Node/Express)

A ready backend is now in `backend/` in this repo.

Run:
```bash
cd backend
npm install
cp .env.example .env
# fill .env values
npm start
```

```js
import express from "express";
import twilio from "twilio";

const app = express();
app.use(express.json());

const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
const from = process.env.TWILIO_FROM_NUMBER;

app.post("/api/alerts/sms", async (req, res) => {
  try {
    const { to, message } = req.body || {};
    if (!to || !message) return res.status(400).json({ ok: false, error: "missing to/message" });

    const out = await client.messages.create({ to, from, body: message });
    return res.json({ ok: true, sid: out.sid });
  } catch (e) {
    return res.status(500).json({ ok: false, error: String(e) });
  }
});

app.listen(process.env.PORT || 3000);
```

Required env vars:
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_FROM_NUMBER`

## 3) Recommended hardening

- Add API key auth header from app
- Rate limit endpoint
- Validate phone format and allowed destinations
- Log delivery statuses and retries
