# Deploy runbook — Cloudflare Pages, sustaintimer.com, Google Search Console

Everything below is founder-run: **`wrangler login` is an interactive browser OAuth**, so it cannot be done
from an agent session. Commands are copy-paste ready from the repo root (`d:\Dev\Trilumos\hourglass`).

**Do the steps in this order.** The custom domain (Step 3) needs the zone to already be on Cloudflare, and
the GSC TXT record (Step 5) needs Cloudflare DNS to be live.

---

## 0. One-time — authenticate

```bash
npx wrangler login
```

Opens a browser, asks you to authorise Wrangler on your Cloudflare account. Confirm it worked:

```bash
npx wrangler whoami
```

> Log in with the account you want to own these projects. Everything here fits inside Cloudflare's **free**
> plan — Pages gives unlimited bandwidth and 500 builds/month.

---

## 1. Move DNS from Hostinger to Cloudflare

The domain stays **registered at Hostinger**; only the nameservers change, which hands DNS to Cloudflare.

1. Cloudflare dashboard → **Add a site** → enter `sustaintimer.com` → choose the **Free** plan.
2. Cloudflare scans the existing DNS and shows you the records it found. **Check this list before
   continuing.**
3. Cloudflare gives you **two nameservers**, e.g. `dana.ns.cloudflare.com` / `rick.ns.cloudflare.com`.
4. In **Hostinger** → *Domains* → `sustaintimer.com` → **DNS / Nameservers** → choose *Change nameservers* /
   *Use custom nameservers* → paste both Cloudflare nameservers → save.
5. Back in Cloudflare, click **Check nameservers now**. Propagation is usually minutes, but the official
   window is **up to 24 hours**.

> ### ⚠️ The one thing that actually breaks people here
> Changing nameservers moves **all** DNS for the domain, not just the website. **If you have email on
> `@sustaintimer.com`, its `MX` (and any `SPF`/`DKIM` `TXT`) records must exist in Cloudflare before you
> switch**, or mail stops being delivered. Cloudflare's scan usually imports them, but it misses records
> sometimes — compare Cloudflare's DNS list against Hostinger's *before* step 4 and add anything missing by
> hand. If the domain has no email set up yet, ignore all of this.

Verify from a terminal once it is live:

```bash
nslookup -type=NS sustaintimer.com
```

---

## 2. Deploy the site

```bash
cd web-astro
npm run build
npx wrangler pages deploy dist --project-name sustain-web --commit-dirty=true
```

First run asks to create the project and for a production branch — accept `main`. It prints a
`https://sustain-web.pages.dev` URL. **Open it and check the site works before attaching the domain.**

Redeploys are the same two commands (`npm run build` then `wrangler pages deploy dist …`).

> `dist/` is ~8.4 MB, four pages: `/`, `/privacy`, `/terms`, `/stage`.
> **`/stage` ships publicly but carries `noindex, nofollow`** — that is intentional (master spec §18.7); it
> is the capture surface, and OBS needs to reach it over https.

---

## 3. Attach sustaintimer.com

Cloudflare dashboard → **Workers & Pages** → `sustain-web` → **Custom domains** → **Set up a domain**:

1. Add `sustaintimer.com` → **Activate domain**.
2. Add `www.sustaintimer.com` the same way.

Because the zone is already on Cloudflare, it creates the DNS records and issues the TLS certificate itself —
nothing to configure. Certificate issuance is typically a few minutes.

Then **redirect www → apex** so you have one canonical host (the canonical tags already point at the apex):

Cloudflare dashboard → **Rules → Redirect Rules → Create rule**
- *If* — Hostname **equals** `www.sustaintimer.com`
- *Then* — **Dynamic** redirect, **301**, expression:
  `concat("https://sustaintimer.com", http.request.uri.path)`

Check all three:

```bash
curl -sSI https://sustaintimer.com | head -1
curl -sSI https://www.sustaintimer.com | head -1     # expect 301
curl -sS  https://sustaintimer.com/robots.txt
```

---

## 4. Deploy the video directory (separate project)

Internal tool — keep it **off** the product domain. It already carries `noindex, nofollow`.

```bash
cd d:/Dev/Trilumos/hourglass
npx wrangler pages deploy tools/video-directory --project-name sustain-directory --commit-dirty=true
```

Lives at `https://sustain-directory.pages.dev`. No custom domain needed.

> Ticks are stored in **that browser's** `localStorage`, so use one browser for it and hit **Export ticks**
> periodically — keep the JSON in the repo so a cleared cache cannot wipe the record of what has been made.

---

## 5. Google Search Console

Use a **Domain property** — it covers apex, `www` and every subdomain in one, and DNS is now on Cloudflare
so verification is easy.

1. [search.google.com/search-console](https://search.google.com/search-console) → property selector →
   **Add property** → **Domain** → `sustaintimer.com`.
2. It shows a **TXT** record, `google-site-verification=…`.
3. Cloudflare → `sustaintimer.com` → **DNS → Records → Add record**:
   - Type **TXT** · Name **`@`** · Content — paste the whole `google-site-verification=…` string · TTL Auto
4. Back in the still-open GSC popup → **Verify**.
5. GSC → **Sitemaps** → enter `sitemap.xml` → **Submit**.

`robots.txt` already carries `Sitemap: https://sustaintimer.com/sitemap.xml`, so Google would find it
anyway — submitting just gets you the processing/error report.

Finally, **URL Inspection** on `https://sustaintimer.com/` → **Request indexing** for the homepage.

> **Judgement call before you submit.** None of the mobile work is device-verified yet (Iron Rule), and
> submitting to GSC invites Google to index whatever is live now. Options: submit immediately and fix
> forward — indexing takes days anyway, so small fixes will land first — or test on a real phone against the
> `.pages.dev` URL first, then submit. **Recommended: test on the phone against `sustain-web.pages.dev`
> today, then do Step 5.** It costs you one day and avoids a first impression built on an unverified layout.

---

## 6. After deploying — update the video descriptions

The deep link now works, so descriptions can stop pointing at the bare domain:

```
https://sustaintimer.com/?mode=pomodoro&work=50&break=10&hours=4&phase=sunset&sound=ocean
```

Params: `mode` `work` `break` `blocks` `hours` `min` `phase` `cycle` `sound` (comma list; **empty =
bell-only**) `vis` `place` `fill` `font` (`serif`/`jost`) `sep` `sunmoon` `color`.

They **seed the Setup screen** — the visitor still sees it and still presses Begin, so nothing auto-starts.
Check one before pasting it into a description.
