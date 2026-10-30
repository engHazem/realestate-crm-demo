# Real Estate CRM — client demo

EspoCRM 10 configured for a real estate sales team, deployable for free on Render.

## What the demo includes
- **Leads:** 16 sales stages (New Client → Done / Refund), sources, tags, next follow-up date, follow-up group set automatically, Kanban board.
- **Real estate records:** Sites → Projects → Units (code, floor, column, area, rooms, price, features, images, availability status).
- **Reservations:** reserving a unit marks it *Reserved*; cancelling or expiring frees it.
- **Contracts:** remaining amount = total − down payment; *Active* marks the unit *Contracted*, *Completed* marks it *Sold* and records the buyer.
- English and Arabic labels; currency EGP; time zone Africa/Cairo.

## Deploy on Render (free)
1. Push this repo to GitHub.
2. In Render: **New → Blueprint**, pick the repo, click **Apply**. This creates the web service and a free PostgreSQL 15 database from `render.yaml`.
3. First start takes 5–10 minutes (installation). The admin username is `admin`; the password is in Render → the web service → **Environment → ESPOCRM_ADMIN_PASSWORD**.

Free tier limits: the service sleeps after 15 minutes idle (first visit takes about a minute), uploaded files are lost on restart, and the free database expires after 30 days.

## How it works
- `demo/custom/` — EspoCRM customizations (entities, fields, layouts, labels, formulas), copied in on every start.
- `start.sh` — restores the config from the database after a restart (Render's disk is not persistent), applies demo settings, and runs the background job worker.
- Configuration changes made in the admin UI are lost on restart; make them in `demo/custom/` instead.
