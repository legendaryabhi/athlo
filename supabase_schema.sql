-- Create tables for Athlo app

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  full_name text,
  avatar_url text,
  calisthenics_level text default 'Beginner',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Sessions Table
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  duration_seconds integer not null,
  skills_worked text,
  photo_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- 3. Likes Table
CREATE TABLE IF NOT EXISTS public.likes (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.sessions(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(session_id, user_id)
);

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

-- 4. Comments Table
CREATE TABLE IF NOT EXISTS public.comments (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.sessions(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Set up Row Level Security Policies
-- (For development purposes, you might want to allow more open access initially, 
-- but these are basic restrictive policies)

-- Profiles: Anyone can view profiles, only user can update their own
CREATE POLICY "Public profiles are viewable by everyone." 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Sessions: Anyone can view sessions, only user can insert their own
CREATE POLICY "Sessions are viewable by everyone." 
ON public.sessions FOR SELECT USING (true);

CREATE POLICY "Users can insert their own sessions." 
ON public.sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Add age column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age integer;

-- Add is_private column to sessions
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS is_private boolean default false;

-- Setup Storage buckets
INSERT INTO storage.buckets (id, name, public) 
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies for 'photos' bucket
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING ( bucket_id = 'photos' );

CREATE POLICY "Authenticated users can upload photos" 
ON storage.objects FOR INSERT 
WITH CHECK ( bucket_id = 'photos' AND auth.role() = 'authenticated' );

CREATE POLICY "Users can update their own photos"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'photos' AND auth.uid() = owner );

CREATE POLICY "Users can delete their own photos"
ON storage.objects FOR DELETE
USING ( bucket_id = 'photos' AND auth.uid() = owner );



-- 5. RLS Policies for Likes
CREATE POLICY "Likes are viewable by everyone." 
ON public.likes FOR SELECT USING (true);

CREATE POLICY "Users can insert their own likes." 
ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes." 
ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- 6. RLS Policies for Comments
CREATE POLICY "Comments are viewable by everyone." 
ON public.comments FOR SELECT USING (true);

CREATE POLICY "Users can insert their own comments." 
ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments." 
ON public.comments FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments." 
ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- till here executed in supabase
