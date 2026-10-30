# SkyLink Airways: Airport Management System

A seat reservation system for a fictional domestic airline, built for a Database Systems course project.
PostgreSQL (hosted on Supabase) with a plain HTML, CSS and JavaScript website.

**Live site:** https://YOUR-GITHUB-USERNAME.github.io/skylink-airways/
**Report:** [report/skylink_ieee.pdf](report/skylink_ieee.pdf) (IEEE conference format)

## Features

- 3NF schema: airport, aircraft_model, aircraft, seat, flight, passenger, booking, admin_user
- 2,620 seats generated with one `generate_series` query
- Double booking impossible: a partial unique index on confirmed bookings
- Two `BEFORE` triggers for rules that span tables
- Row Level Security, column-level `GRANT`s and `SECURITY DEFINER` functions
- Passenger accounts with Supabase Auth and a "My bookings" page
- Live seat map with Supabase Realtime
- Admin dashboard running 8 analytical SQL reports in one call
- Transactions demo: `COMMIT` vs `ROLLBACK` with two sessions

## Pages

| Page | Purpose |
|---|---|
| `index.html` | All flights with seats left |
| `seat.html` | Live seat map and booking |
| `login.html` | Sign in or create an account |
| `my-bookings.html` | The signed-in passenger's bookings |
| `manage.html` | Find or cancel a booking with PNR and email |
| `admin.html` | Admin dashboard (admins only) |

## Database setup

Run the files in `sql/` in the Supabase SQL editor, in number order:
`01` to `09`, `11`, `13`, `14`, `15`, `16`, `17`.

- `10_transactions_demo.sql` and `tests_and_demos.sql` are demonstrations, run by hand.
- `12_audit_log.sql` is a design that is not deployed.

To make an account an administrator, sign up on the site, then run:

```sql
INSERT INTO admin_user (user_id) SELECT id FROM auth.users WHERE email = 'their.email@example.com';
```

## Tech

PostgreSQL 15+ on Supabase (Auth, PostgREST, Realtime), `supabase-js` v2, HTML, CSS, JavaScript. No build step.
