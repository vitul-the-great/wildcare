# Wildcare — Wildlife Rescue & Rehabilitation

React + TypeScript frontend, persistent HTTP API, and MySQL local backend matching WildlifeDB. The privately hosted Site uses Cloudflare D1 (SQLite) with the same entities; it is a separate database and does not connect to your laptop's MySQL.

## Run with your MySQL database

Requires Node.js 22.13+ and MySQL 8.0.16+.

1. If your original SQL already ran successfully, keep that database. Otherwise run `mysql -u root -p < local/schema.sql`. This creates empty tables and the health audit trigger; it does not delete your data. The file also works against the supplied schema to install/replace its audit trigger.
2. Use a MySQL account with SELECT, INSERT, UPDATE, DELETE rights on WildlifeDB. Do not put DB credentials in frontend files.
3. `cd local`, then `npm install`.
4. Copy `.env.example` to `.env` and enter your MySQL connection settings.
5. `npm run build`, then `npm start`.
6. Open http://127.0.0.1:3001. On an empty database, click **Load sample data**. This loads the supplied rows, including Animal 101 age 6 after the supplied COMMIT example.

For development, keep `npm start` running and run `npm run dev` in a second terminal inside local/. Open http://127.0.0.1:5173. Vite proxies /api to port 3001. Update vite.config.mjs if changing the API port.

The local server binds only to loopback. It is a classroom/local application without an application login system. The hosted Site is private through Sites access control. Add authentication and authorization before deploying the local server to a shared network.

## Features

- Dashboard computed from actual database rows, with empty/loading/error states.
- Search and health filtering; CSV export with formula-prefix protection.
- Animal profiles with rescue, treatment, rehabilitation and audit history.
- Create/edit/delete all eight domain entities. Deletes respect foreign keys and need confirmation.
- Register an existing animal rescue, or create animal + rescue in one transaction.
- Parameterized SQL and table/column allowlists, integer/date/length validation.
- Trigger-based health history; updating other fields does not add an audit entry.
- Required completion dates and chronological rehabilitation date validation.
- Responsive layout, labeled fields, keyboard dialog handling.

IDs remain explicit to work with the original schema. Suggested IDs are editable; collisions return a clear conflict instead of overwriting data. Programs use duration in days. Active rehabilitation means End_Date is null. Historical seed records are synthetic classroom data, not real current cases.

## API

GET /api/data: all nine tables. Intended for this small classroom dataset; large installations should add server pagination and specific resource endpoints.

POST /api/data JSON actions:
- `{ "action":"create", "table":"Animal", "record":{ "Animal_ID":106, "Tag_No":"A106", "Species_ID":1 } }`
- `{ "action":"update", "table":"Animal", "id":106, "record":{ "Health_Status":"Healthy" } }`
- `{ "action":"delete", "table":"Animal", "id":106 }`
- `{ "action":"rescue", "record":{ "Rescue_ID":6,"Animal_ID":106,"Team_ID":1,"Rescue_Date":"2026-11-02" }, "animal":{ "Animal_ID":106,"Tag_No":"A106","Species_ID":1 } }`
- `{ "action":"seed" }`: inserts missing seed IDs; never updates existing seed IDs. A conflicting tag/name causes the transaction to roll back.

Animal_Audit is read-only through the API. Errors return `{ "error":"..." }` with 400, 404, 409 or 500 status.

## Source structure

- `app/`: hosted React interface and D1 API route.
- `lib/model.mjs`: table fields and sample records.
- `lib/service.mjs`: shared validation and database operations.
- `db/schema.ts`, `drizzle/`: hosted relational schema and migrations.
- `local/`: standalone React/Vite + Node/MySQL app, schema, and environment template.
- `tests/service.test.mjs`: meaningful transaction, constraint, audit and validation tests.

Hosted and local UI sources are copies so the local app has no dependency on Next/Vinext. When changing the hosted UI, copy app/page.tsx to local/src/App.tsx (adjust model import) and app/globals.css to local/src/style.css.

## Verification

`node tests/service.test.mjs` uses Node's in-memory SQLite to check seeding, audit, invalid ages/dates, foreign-key protections, atomic rescue rollback, duplicate tags and table allowlists. The hosted production build is checked separately. The MySQL adapter requires a running MySQL server and your credentials for an end-to-end MySQL test.
