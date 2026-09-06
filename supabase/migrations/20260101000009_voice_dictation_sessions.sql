-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 009 - HINDI COURT VOICE DICTATION & AUDIO INTAKE SESSIONS
-- STATUTORY COMPLIANCE: DPDP Act 2023 Sec 6 & 8(7) (Strict Ephemeral Audio Storage)
-- ============================================================================

create table if not exists public.voice_dictation_sessions (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    case_id uuid references public.cases(id) on delete set null,
    
    -- Audio Processing Metadata
    audio_format text not null default 'audio/m4a',
    duration_seconds integer not null default 0,
    audio_file_size_bytes bigint not null default 0,
    
    -- Verbatim & Structured Transcripts (Devanagari)
    verbatim_transcript_hindi text not null,
    cleaned_factual_matrix text not null,
    
    -- Extracted Structured Legal Entities
    extracted_fir_number text,
    extracted_police_station text,
    extracted_sections text[],
    extracted_accused_names text[],
    extracted_custody_status text,
    
    -- DPDP Statutory Data Minimization Status
    raw_audio_purged_immediately boolean not null default true,
    processed_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_voice_dictation_advocate on public.voice_dictation_sessions(advocate_id);

-- Enable Row Level Security
alter table public.voice_dictation_sessions enable row level security;

create policy "Advocates have exclusive access to own voice dictations"
    on public.voice_dictation_sessions for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
