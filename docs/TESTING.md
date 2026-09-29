# Manual acceptance checks
Run with a configured Supabase project and two browser profiles.
1. Public visitor sees active jobs, searches, and filters by department.
2. Candidate signs up; a profile is created automatically with candidate role.
3. Candidate uploads a PDF under 8 MB and submits one application for an active job.
4. Candidate cannot submit twice to the same role (unique constraint).
5. Candidate sees only their own applications and can get a short-lived CV link.
6. Candidate cannot read another candidate's application or CV by changing IDs.
7. Recruiter sees applications only for jobs assigned to their profile; can update application status.
8. Recruiter cannot change roles or delete application/CV records.
9. Admin can manage jobs and profiles, see applications, and remove application plus CV.
10. Anonymous user can read active jobs but cannot read profiles, applications, or private CVs.
11. With n8n configured, new applications notify recruiting inbox; missing/bad shared secret is rejected.
12. At mobile width, the page and candidate forms remain usable.
