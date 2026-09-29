# Job Recruitment / Applicant Tracking System
A responsive careers site and applicant tracking starter for **Nowshera Digital**. Candidates can discover roles, create an account, upload a private CV, and track applications. Recruiters see applications for their assigned jobs. Admins manage profiles/jobs and remove applications. Optional n8n email notifications are included.
## What is included
- React + TypeScript + Vite careers website with search, department filters, responsive layout, and preview mode.
- Supabase Auth email/password flow and automatic candidate profiles.
- Private CV bucket with file type/size restrictions and ownership/assigned-recruiter RLS.
- Application submission, duplicate prevention, signed CV viewing, application status, and admin removal.
- SQL schema, role setup, environment example, authentication/security documentation, testing checklist, and n8n workflow JSON.
## Run it
See [Setup and deployment](docs/SETUP.md). Fast start: configure `.env.local`, run SQL from `supabase/schema.sql`, then `npm install && npm run dev`.
## Roles
- **Candidate:** register, apply, access own applications and CVs.
- **Recruiter:** read applications and CVs only for assigned jobs; update review status.
- **Admin:** manage jobs and profiles; read/remove applications.
Roles are never selected by the public signup form. The first admin is assigned by a trusted project owner in Supabase SQL Editor.
## Security
Browser bundle uses only Supabase URL and publishable/anon key. RLS enforces data access; CV bucket is private. Service-role keys, Gmail credentials and n8n shared secrets must stay in protected server/n8n secrets. Read [authentication architecture](docs/authentication.md).
## Email automation
Optional workflow: [n8n/application-notification.workflow.json](n8n/application-notification.workflow.json). Configure it by following the setup guide. No CV or file URL is sent to n8n.
## Acceptance checklist
See [manual checks](docs/TESTING.md). Real sign-in, uploads and end-to-end email require your own Supabase and n8n credentials, which are intentionally not included in this public repository.
