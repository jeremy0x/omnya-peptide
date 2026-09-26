-- ==============================================================================
-- Omnya Peptide Database Schema for Supabase PostgreSQL
-- ==============================================================================

-- 1. Profiles Table (Anonymous and claimed users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    device_id TEXT UNIQUE,
    email TEXT UNIQUE,
    goals TEXT[] DEFAULT '{}',
    selected_compounds TEXT[] DEFAULT '{}',
    experience_level TEXT DEFAULT 'First month',
    has_cycle BOOLEAN DEFAULT TRUE,
    day_90_goal TEXT,
    photo_tracking_type TEXT DEFAULT 'both',
    sunday_photo_prompt_enabled BOOLEAN DEFAULT TRUE,
    is_pro BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Compounds / Inventory Table
CREATE TABLE IF NOT EXISTS public.compounds (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    nickname TEXT,
    category TEXT NOT NULL CHECK (category IN ('body', 'glowAndSkin', 'healAndRecover')),
    dose_mg NUMERIC(6, 2) NOT NULL,
    frequency_days INT NOT NULL DEFAULT 1,
    injection_site TEXT NOT NULL,
    vial_mg NUMERIC(6, 2) NOT NULL,
    bac_water_ml NUMERIC(6, 2) NOT NULL,
    doses_left INT NOT NULL DEFAULT 0,
    cost_per_dose NUMERIC(6, 2) DEFAULT 0.0,
    total_monthly_cost NUMERIC(8, 2) DEFAULT 0.0,
    start_date TIMESTAMPTZ DEFAULT NOW(),
    runout_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Dose Logs Table (1-Tap logging)
CREATE TABLE IF NOT EXISTS public.dose_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    compound_id TEXT NOT NULL REFERENCES public.compounds(id) ON DELETE CASCADE,
    compound_name TEXT NOT NULL,
    dose_mg NUMERIC(6, 2) NOT NULL,
    injection_site TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Daily Check-Ins Table (3-Tap check-in + ImgBB photo URL)
CREATE TABLE IF NOT EXISTS public.check_ins (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date TIMESTAMPTZ NOT NULL,
    energy_level INT NOT NULL CHECK (energy_level BETWEEN 1 AND 5),
    appetite_level INT NOT NULL CHECK (appetite_level BETWEEN 1 AND 5),
    weight_lbs NUMERIC(5, 2),
    waist_inches NUMERIC(5, 2),
    cycle_phase TEXT CHECK (cycle_phase IN ('follicular', 'ovulatory', 'luteal', 'menstrual')),
    is_period_day BOOLEAN DEFAULT FALSE,
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Circles Table (Accountability groups capped at 5)
CREATE TABLE IF NOT EXISTS public.circles (
    id TEXT PRIMARY KEY,
    invite_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    max_members INT NOT NULL DEFAULT 5,
    owner_user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Circle Members Table
CREATE TABLE IF NOT EXISTS public.circle_members (
    id TEXT PRIMARY KEY,
    circle_id TEXT NOT NULL REFERENCES public.circles(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    avatar_letter TEXT NOT NULL,
    checked_in_today BOOLEAN DEFAULT FALSE,
    weekly_doses_logged INT DEFAULT 0,
    weekly_doses_target INT DEFAULT 7,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (circle_id, user_id)
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_compounds_user ON public.compounds(user_id);
CREATE INDEX IF NOT EXISTS idx_dose_logs_user ON public.dose_logs(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_check_ins_user ON public.check_ins(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_circle_members_circle ON public.circle_members(circle_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dose_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circle_members ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- RLS Policies & Security
-- Uses anonymous auth with individual auth.uid() scoping.
-- Service role retains full bypass capability for server operations.
-- ==============================================================================

-- Helper function to check circle membership without recursive RLS trigger
CREATE OR REPLACE FUNCTION public.is_circle_member(_circle_id text, _user_id text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members
    WHERE circle_id = _circle_id AND user_id = _user_id
  );
$$;

REVOKE ALL ON FUNCTION public.is_circle_member(text, text) FROM PUBLIC, anon, authenticated;

-- Profiles: scoped to owner
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid()::text = id);

CREATE POLICY "profiles_upsert" ON public.profiles
  FOR ALL TO authenticated
  USING (auth.uid()::text = id)
  WITH CHECK (auth.uid()::text = id);

-- Compounds: scoped to owner
CREATE POLICY "compounds_select" ON public.compounds
  FOR SELECT TO authenticated
  USING (auth.uid()::text = user_id);

CREATE POLICY "compounds_upsert" ON public.compounds
  FOR ALL TO authenticated
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

-- Dose Logs: scoped to owner
CREATE POLICY "dose_logs_select" ON public.dose_logs
  FOR SELECT TO authenticated
  USING (auth.uid()::text = user_id);

CREATE POLICY "dose_logs_upsert" ON public.dose_logs
  FOR ALL TO authenticated
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

-- Check-Ins: scoped to owner
CREATE POLICY "check_ins_select" ON public.check_ins
  FOR SELECT TO authenticated
  USING (auth.uid()::text = user_id);

CREATE POLICY "check_ins_upsert" ON public.check_ins
  FOR ALL TO authenticated
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

-- Circles: readable by members, manageable by owner
CREATE POLICY "circles_select" ON public.circles
  FOR SELECT TO authenticated
  USING (public.is_circle_member(id, auth.uid()::text));

CREATE POLICY "circles_insert" ON public.circles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid()::text = owner_user_id);

CREATE POLICY "circles_update" ON public.circles
  FOR UPDATE TO authenticated
  USING (auth.uid()::text = owner_user_id)
  WITH CHECK (auth.uid()::text = owner_user_id);

-- Circle Members: readable by fellow members, insert/update own membership
CREATE POLICY "circle_members_select" ON public.circle_members
  FOR SELECT TO authenticated
  USING (public.is_circle_member(circle_id, auth.uid()::text));

CREATE POLICY "circle_members_insert" ON public.circle_members
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "circle_members_update" ON public.circle_members
  FOR UPDATE TO authenticated
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

-- Service role full access policies
CREATE POLICY "service_role_full_profiles" ON public.profiles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_full_compounds" ON public.compounds FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_full_dose_logs" ON public.dose_logs FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_full_check_ins" ON public.check_ins FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_full_circles" ON public.circles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_full_circle_members" ON public.circle_members FOR ALL TO service_role USING (true) WITH CHECK (true);
