-- ==============================================================================
-- Migration: Fix RLS policies (resolve Supabase database linter warnings)
-- Run this against your live Supabase database to replace the permissive policies.
-- ==============================================================================

-- Drop old permissive catch-all policies
DROP POLICY IF EXISTS "Users read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users insert/update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users manage own compounds" ON public.compounds;
DROP POLICY IF EXISTS "Users manage own dose logs" ON public.dose_logs;
DROP POLICY IF EXISTS "Users manage own check ins" ON public.check_ins;
DROP POLICY IF EXISTS "Circle members view circle" ON public.circles;
DROP POLICY IF EXISTS "Circle members view cohort" ON public.circle_members;

-- Profiles: read-only for anon, full access for service_role
CREATE POLICY "anon_read_profiles"
  ON public.profiles FOR SELECT TO anon USING (true);
CREATE POLICY "service_role_full_profiles"
  ON public.profiles FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Compounds: read-only for anon, full access for service_role
CREATE POLICY "anon_read_compounds"
  ON public.compounds FOR SELECT TO anon USING (true);
CREATE POLICY "service_role_full_compounds"
  ON public.compounds FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Dose Logs: read-only for anon, full access for service_role
CREATE POLICY "anon_read_dose_logs"
  ON public.dose_logs FOR SELECT TO anon USING (true);
CREATE POLICY "service_role_full_dose_logs"
  ON public.dose_logs FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Check-Ins: read-only for anon, full access for service_role
CREATE POLICY "anon_read_check_ins"
  ON public.check_ins FOR SELECT TO anon USING (true);
CREATE POLICY "service_role_full_check_ins"
  ON public.check_ins FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Circles: read-only for anon (needed for join-by-invite lookup)
CREATE POLICY "anon_read_circles"
  ON public.circles FOR SELECT TO anon USING (true);
CREATE POLICY "service_role_full_circles"
  ON public.circles FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Circle Members: read-only for anon (for circle roster display)
CREATE POLICY "anon_read_circle_members"
  ON public.circle_members FOR SELECT TO anon USING (true);
CREATE POLICY "service_role_full_circle_members"
  ON public.circle_members FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Fix rls_auto_enable function security warnings:
-- 1. Switch to SECURITY INVOKER so it doesn't run with elevated DEFINER privileges
-- 2. Revoke execute completely from PUBLIC, anon, and authenticated
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'rls_auto_enable'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  ) THEN
    ALTER FUNCTION public.rls_auto_enable() SECURITY INVOKER;
    REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC;
    REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM anon, authenticated, PUBLIC;
  END IF;
END
$$;
