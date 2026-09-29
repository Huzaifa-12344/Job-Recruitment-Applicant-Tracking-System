# Setup and deployment
## 1. Install
Use Node.js 20 or newer. Clone the repository, run `npm install`, copy `.env.example` to `.env.local`, then run `npm run dev`.
## 2. Configure Supabase
Create a Supabase project. In **Project Settings → API**, copy the project URL and publishable key to `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. Never use the service-role key in a `VITE_*` variable.
Run `supabase/schema.sql` once in the SQL Editor. It creates the tables, profile trigger, RLS, private `candidate-cvs` bucket, and four sample roles.
In **Authentication → URL Configuration**, set the local Site URL to `http://localhost:5173` during development and add your deployed domain to Redirect URLs. Enable email/password sign-in.
## 3. Create the first admin
Sign up through the site using your own email and confirm it. In Supabase SQL Editor, promote that account using its exact auth user UUID:
```sql
update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';
```
This SQL must be run by a trusted project owner. The app has no public role selector. Add recruiters from Supabase after confirming their identity; assign a job's `recruiter_id` to the recruiter's profile UUID. Only admins may create or edit roles.
## 4. Run locally
```sh
npm install
cp .env.example .env.local
# Add the two public Supabase values to .env.local
npm run dev
```
If Supabase is not configured, the public careers page runs in preview mode with sample jobs; sign-in and applications stay disabled.
## 5. Deploy frontend
Build with `npm run build`. Deploy the generated `dist/` directory to any static host (Netlify, Vercel, Cloudflare Pages). Configure the two `VITE_*` public Supabase values in the host's environment settings. Set a history fallback to `/index.html` if needed.
## 6. Optional n8n notifications
Import `n8n/application-notification.workflow.json` into n8n. Add SMTP credentials in n8n and set workflow variables `ATS_WEBHOOK_SECRET`, `RECRUITING_FROM_EMAIL`, and `RECRUITING_TEAM_EMAIL`. Activate it and copy the **production** webhook URL.
Set the Supabase Edge Function secrets `N8N_WEBHOOK_URL` and `N8N_WEBHOOK_SECRET`; deploy `supabase/functions/notify-application` with JWT verification enabled. After successful application insert, invoke that function with `{applicationId}`. Do not put the webhook secret in browser code.
> Notifications are optional. Email is sent to the recruiting inbox only. CV files and signed links are never sent to n8n.
## 7. Recruiter application access
In Supabase, set a verified staff profile role to `recruiter`; assign jobs by UUID. RLS limits that account to assigned applications and their CVs.
