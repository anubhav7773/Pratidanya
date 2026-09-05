-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 004 - DPDP AUDIT TRAIL, QUOTA ENGINE & BILLING INTEGRATION
-- STATUTORY COMPLIANCE: DPDP Act 2023 Sec 5, 6, 8(5), 8(6) & 8(7)
-- ============================================================================

-- Table 1: Immutable Statutory Audit Log
create table public.dpdp_audit_logs (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    action_type text not null,                      -- 'CONSENT_GRANTED', 'CONSENT_WITHDRAWN', 'CASE_EXPORTED', 'STATUTORY_RIGHT_TO_ERASURE_EXECUTED'
    ip_address text,
    user_agent text,
    metadata jsonb default '{}'::jsonb,
    recorded_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Trigger: Prevent update or deletion of statutory audit records
create or replace function prevent_audit_log_mutation()
returns trigger as $$
begin
    raise exception 'DPDP Audit Logs are strictly immutable under DPDP Act 2023.';
end;
$$ language plpgsql;

create trigger trg_protect_dpdp_audit_logs
before update or delete on public.dpdp_audit_logs
for each row execute function prevent_audit_log_mutation();

-- Trigger: Statutory Right to Erasure cascade audit logging
create or replace function execute_statutory_data_erasure()
returns trigger as $$
begin
    insert into public.dpdp_audit_logs (
        advocate_id,
        action_type,
        metadata
    ) values (
        old.advocate_id,
        'STATUTORY_RIGHT_TO_ERASURE_EXECUTED',
        jsonb_build_object(
            'deleted_case_id', old.id,
            'fir_number', old.fir_number,
            'erasure_timestamp', timezone('utc'::text, now())
        )
    );
    return old;
end;
$$ language plpgsql;

create trigger trg_statutory_case_erasure
after delete on public.cases
for each row execute function execute_statutory_data_erasure();

-- Table 2: AI Quota Management & Monetization
create table public.advocate_ai_quotas (
    advocate_id text primary key references public.advocate_profiles(id) on delete cascade,
    subscription_tier text not null default 'FREE', -- 'FREE', 'PRO_CHAMBER'
    daily_drafts_remaining integer not null default 3,
    ad_rewarded_drafts integer not null default 0,
    total_tokens_consumed bigint not null default 0,
    last_quota_reset_date date not null default current_date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table 3: Google Play In-App Subscriptions
create table public.advocate_subscriptions (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    product_id text not null,                       -- 'pratidnya_chamber_pro_monthly' or 'pratidnya_chamber_pro_yearly'
    purchase_token text unique not null,
    order_id text,
    subscription_status text not null,              -- 'ACTIVE', 'IN_GRACE_PERIOD', 'EXPIRED', 'CANCELED'
    auto_renewing boolean default true not null,
    start_time timestamp with time zone not null,
    expiry_time timestamp with time zone not null,
    payment_method_type text default 'GOOGLE_PLAY',
    price_currency_code text default 'INR',
    price_amount_micros bigint not null,
    country_code text default 'IN',
    raw_google_play_response jsonb default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index idx_advocate_subscriptions_lookup on public.advocate_subscriptions(advocate_id, subscription_status);

-- Trigger: Synchronize AI Quota Tier on Subscription Status Change
create or replace function sync_advocate_quota_on_subscription_change()
returns trigger as $$
begin
    if (new.subscription_status = 'ACTIVE' or new.subscription_status = 'IN_GRACE_PERIOD') then
        update public.advocate_ai_quotas
        set 
            subscription_tier = 'PRO_CHAMBER',
            daily_drafts_remaining = 9999,
            updated_at = timezone('utc'::text, now())
        where advocate_id = new.advocate_id;
    else
        update public.advocate_ai_quotas
        set 
            subscription_tier = 'FREE',
            daily_drafts_remaining = 3,
            updated_at = timezone('utc'::text, now())
        where advocate_id = new.advocate_id;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_advocate_subscription_status
after insert or update of subscription_status on public.advocate_subscriptions
for each row execute function sync_advocate_quota_on_subscription_change();

-- Enable Row Level Security
alter table public.dpdp_audit_logs enable row level security;
alter table public.advocate_ai_quotas enable row level security;
alter table public.advocate_subscriptions enable row level security;

create policy "Advocates can read own audit logs"
    on public.dpdp_audit_logs for select
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocates can view own quotas"
    on public.advocate_ai_quotas for select
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocates can view own subscriptions"
    on public.advocate_subscriptions for select
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
