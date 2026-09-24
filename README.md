# Job Recruitment / Applicant Tracking System

A secure applicant tracking system for **Nowshera Digital**.

## Roles

- **Candidate** — signs up, uploads a CV, and can view only their own applications.
- **Recruiter** — reviews applications only for jobs assigned to them.
- **Admin** — manages jobs, recruiters, and candidate records.

## Stack

- React + TypeScript frontend
- Supabase Auth, Postgres, and Storage
- Server-side API / Edge Functions for privileged actions
- n8n for email notifications and optional AI CV summaries

## Authentication and security

Email/password authentication is provided by Supabase Auth. The browser holds only the Supabase session; all authorization is enforced by database Row Level Security (RLS) and server-side checks.

- Role is read from `profiles.role`, never trusted from the browser.
- Candidate CVs are stored in a private bucket.
- The AI/n8n automation key stays in server or n8n environment variables only.
- No production secret, access token, password, or API key is committed.

Read [Authentication documentation](docs/authentication.md) and the [database security policies](supabase/schema.sql).

## Environment setup

Copy `.env.example` to `.env.local` and set only public Supabase project values in the frontend. Configure service-role keys and automation secrets in a protected server/n8n environment, never in `.env.local` exposed to the browser.

## Main request flow

`Browser → Supabase Auth → access token → API/RLS → database & private CV storage`

For notification work:

`Server → n8n production webhook → email service`
