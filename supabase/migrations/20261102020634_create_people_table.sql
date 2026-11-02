create table public.people (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text not null unique,
  stage text not null default 'applicant'
    check (stage in ('applicant', 'student', 'alumnus')),
  created_at timestamptz not null default now()
);