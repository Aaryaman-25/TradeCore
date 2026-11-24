# Deploying TradeCore online

TradeCore has two parts:

| Part | What it is | Where it runs |
|---|---|---|
| **Engine** | The C program: order book, bots, accounts, live stream | **Render** (a host that keeps a program running) |
| **Website** | `frontend/`: HTML, CSS, JavaScript | **Vercel** (static hosting) |

The engine cannot run on Vercel itself. Vercel's containers (in beta) shut
down after 5 idle minutes and can run as several separate copies, while
TradeCore keeps the whole order book in one running program's memory, and its
bots must keep trading in the background.

## 1. Put the project on GitHub

From the unzipped `tradecore-backend` folder on your Mac:

```sh
git init -b main            # skip if the folder is already a git repo
git add -A
git commit -m "TradeCore"
git remote add origin https://github.com/Aaryaman-25/TradeCore.git
git push -u origin main
```

When git asks for a password, paste a GitHub *personal access token*
(GitHub → Settings → Developer settings → Personal access tokens), not your
account password. GitHub Desktop (“Add existing repository” → “Publish”) is
an easier alternative.

## 2. Deploy the engine on Render

1. Go to https://render.com and sign up with your GitHub account.
2. Click **New → Blueprint**, pick the **TradeCore** repository and click
   **Apply**. Render reads `render.yaml` and creates a free Docker web service
   called `tradecore-engine`.
   (Manual alternative: **New → Web Service** → TradeCore repo →
   Language **Docker** → Instance type **Free** → **Create Web Service**.)
3. Wait for the first build (a few minutes). The log ends with
   `TradeCore engine listening on http://0.0.0.0:...`.
4. Copy the service address shown at the top, e.g.
   `https://tradecore-engine.onrender.com`.
5. Check it: open `https://<your-address>/api/health`; you should see
   `{"ok":true,"name":"TradeCore",...}`.

That address is already a complete working website (the engine also serves
the dashboard). The next steps put the website on Vercel as well.

## 3. Point the website at the engine

Edit `frontend/config.js`:

```js
window.TRADECORE_API_URL = "https://tradecore-engine.onrender.com";   // your Render address, no slash at the end
```

Then push the change:

```sh
git add frontend/config.js
git commit -m "Point website at Render engine"
git push
```

## 4. Deploy the website on Vercel

1. Go to https://vercel.com and sign up with GitHub.
2. Click **Add New… → Project** and **Import** the TradeCore repository.
3. Set:
   - **Framework Preset:** `Other`
   - **Root Directory:** `frontend` (click *Edit*, choose the folder)
   - **Build Command / Output Directory / Install Command:** leave them off/empty
4. Click **Deploy**. After about a minute you get an address such as
   `https://tradecore-xyz.vercel.app`.

## 5. Try it

Open the Vercel address and sign in with **demo / demo1234**.

## What to expect on the free plans

- **Render free services sleep after 15 minutes without visitors.** The next
  visit wakes the engine, which can take up to about a minute. Meanwhile the
  sign-in page shows “Engine offline”; wait and refresh.
- **Waking up starts a fresh market.** The order book, trades and any accounts
  you created are gone; 3 hours of new history are generated and the demo
  accounts come back. Data is kept only in memory, by design.
- **To keep it awake** for a presentation, open the site a few minutes before,
  or use a free uptime pinger (for example cron-job.org) to request
  `https://<your-address>/api/health` every 10 minutes. Render's paid
  Starter plan never sleeps.
- **Updates:** every `git push` redeploys both Render and Vercel automatically.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Vercel site says “Engine offline” for more than ~2 minutes | Check `frontend/config.js` has the exact Render address (https, no trailing slash), and that `/api/health` works on Render. |
| Render build fails | Open the Render logs. The Dockerfile runs all tests during the build, and a failing test stops the deploy on purpose. |
| “Your session expired” after a while | The engine restarted (sleep or redeploy). Sign in again. |
| Want to change the engine address without redeploying | Settings → Engine & API → Engine URL (saved in that browser only). |
