-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 011 - ANON ONBOARDING & RLS POLICIES FOR FIREBASE AUTH CLIENT
-- STATUTORY COMPLIANCE: DPDP Act 2023 & Advocates Act 1961
-- ============================================================================

-- 1. Make onboarding profile fields nullable initially until bar profile step
ALTER TABLE public.advocate_profiles ALTER COLUMN bar_council_number DROP NOT NULL;
ALTER TABLE public.advocate_profiles ALTER COLUMN full_name DROP NOT NULL;
ALTER TABLE public.advocate_profiles ALTER COLUMN email DROP NOT NULL;

-- 2. Allow anon role access for client-side Firebase Auth users
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon insert advocate profile') THEN
        CREATE POLICY "Allow anon insert advocate profile" ON public.advocate_profiles FOR INSERT TO anon WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon update advocate profile') THEN
        CREATE POLICY "Allow anon update advocate profile" ON public.advocate_profiles FOR UPDATE TO anon USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon select advocate profile') THEN
        CREATE POLICY "Allow anon select advocate profile" ON public.advocate_profiles FOR SELECT TO anon USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon access cases') THEN
        CREATE POLICY "Allow anon access cases" ON public.cases FOR ALL TO anon USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon access proceedings') THEN
        CREATE POLICY "Allow anon access proceedings" ON public.case_proceedings FOR ALL TO anon USING (true) WITH CHECK (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon insert dpdp_audit_logs') THEN
        CREATE POLICY "Allow anon insert dpdp_audit_logs" ON public.dpdp_audit_logs FOR INSERT TO anon WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon select dpdp_audit_logs') THEN
        CREATE POLICY "Allow anon select dpdp_audit_logs" ON public.dpdp_audit_logs FOR SELECT TO anon USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon access advocate_ai_quotas') THEN
        CREATE POLICY "Allow anon access advocate_ai_quotas" ON public.advocate_ai_quotas FOR ALL TO anon USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon access advocate_subscriptions') THEN
        CREATE POLICY "Allow anon access advocate_subscriptions" ON public.advocate_subscriptions FOR ALL TO anon USING (true) WITH CHECK (true);
    END IF;
END $$;
