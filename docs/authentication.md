# Authentication Architecture

## Components

| Component | Responsibility | Secrets it may access |
|---|---|---|
| React client | Sign-in form, session-aware UI, candidate actions | Public Supabase URL and publishable/anon key only |
| Supabase Auth | Verifies password and issues signed access/refresh tokens | Password hashes and signing keys |
| API / Edge Function | Sensitive admin actions, role changes, n8n trigger | Service-role key and automation secret |
| Postgres + RLS | Enforces per-user/per-role data access | None supplied by browser |
| Private Storage | Keeps candidate CVs private | Enforced through signed session + RLS |
| n8n | Sends email / runs approved automation | Its own protected Gmail and webhook credentials |

## Request flow

1. Candidate enters email and password in the app.
2. The client calls Supabase Auth with TLS; the password is never saved by the app.
3. Supabase returns a short-lived access token and refresh token through its SDK session.
4. The SDK sends the access token with each authenticated request.
5. Supabase verifies the token and exposes `auth.uid()` to RLS policies.
6. RLS permits a candidate only to read/write their own application and CV path. A recruiter may read applications only for their assigned jobs.
7. Any action that changes a role, deletes someone else's CV, or calls n8n goes through a protected server function. It checks the authenticated user and role before using server-only credentials.

## Role rules

- Candidate: own profile, own CV, own applications.
- Recruiter: applications belonging to jobs assigned to that recruiter.
- Admin: privileged operations only through a server-side route/function after role verification.
- UI visibility is not a security control; RLS and server checks are required.

## Credential and token handling

### Safe in browser

- Supabase project URL
- Supabase publishable/anon key
- Supabase access/refresh session managed by the official SDK

### Server / n8n only

- Supabase **service-role key**
- n8n webhook secret / `X-Automation-Key`
- Gmail credential
- AI provider key
- JWT signing material or any database password

Never expose server-only values in React source, `VITE_*` variables, commits, GitHub Issues, screenshots, or n8n request logs.

## Token protection

- Use HTTPS in production.
- Use Supabase SDK session handling; do not build a custom localStorage token scheme.
- Call `getUser()` server-side before privileged work; never accept a supplied user ID or role as proof.
- Expire sessions on sign-out and rotate refresh tokens through Supabase.
- Do not log Authorization headers, tokens, passwords, CV URLs, or secrets.
- Keep CV storage bucket private and generate time-limited signed download URLs only after authorization.

## Server-side privileged action example

```ts
// This belongs in an Edge Function or backend, never in React.
const user = await supabase.auth.getUser(request.headers.get("Authorization") ?? "");
if (!user.data.user) return new Response("Unauthorized", { status: 401 });

const { data: profile } = await adminClient
  .from("profiles").select("role").eq("id", user.data.user.id).single();

if (profile?.role !== "admin") return new Response("Forbidden", { status: 403 });

// Only after authorization may the server use its service-role or n8n secret.
```

## Repository safety checklist

- [x] `.env` is ignored.
- [x] `.env.example` contains placeholders only.
- [x] No Gmail, AI, n8n, service-role, password, or token value is committed.
- [x] Client code uses only public Supabase configuration.
- [x] Database schema enables RLS with ownership/assignment policies.
