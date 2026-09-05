-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- SEED DATA: SYNTHETIC TEST FIXTURES (DEVELOPMENT SANDBOX ONLY)
-- PRIVACY NOTE: ZERO REAL LITIGANT OR CASE DATA (DPDP COMPLIANT)
-- ============================================================================

-- 1. Test Advocate Profile (Linked to Dummy Firebase UID)
insert into public.advocate_profiles (
    id,
    email,
    full_name,
    bar_council_number,
    enrolled_state,
    primary_court_name,
    court_type,
    chamber_address,
    dpdp_consent_accepted,
    dpdp_consent_timestamp
) values (
    'TEST_FIREBASE_UID_ADVOCATE_01',
    'advocate.test@asiverticals.me',
    'अधिवक्ता राजेश कुमार (परीक्षण प्रोफ़ाइल)',
    'UP/9999/2020',
    'Uttar Pradesh',
    'जिला एवं सत्र न्यायालय, लखनऊ',
    'DISTRICT_SUBORDINATE',
    'चैंबर संख्या 42, सिविल कोर्ट परिसर, लखनऊ',
    true,
    timezone('utc'::text, now())
) on conflict (id) do nothing;

-- 2. Initial AI Quota for Test Advocate
insert into public.advocate_ai_quotas (
    advocate_id,
    subscription_tier,
    daily_drafts_remaining,
    ad_rewarded_drafts
) values (
    'TEST_FIREBASE_UID_ADVOCATE_01',
    'FREE',
    3,
    0
) on conflict (advocate_id) do nothing;

-- 3. Synthetic Criminal Case (Section 379/411 IPC - Stolen Property Recovery)
insert into public.cases (
    id,
    advocate_id,
    fir_number,
    police_station,
    district,
    state,
    accused_name,
    accused_custody_status,
    complainant_name,
    statute_system,
    under_sections,
    court_designation,
    case_number,
    stage_of_case,
    next_hearing_date,
    last_court_order
) values (
    'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
    'TEST_FIREBASE_UID_ADVOCATE_01',
    '124/2026',
    'कोतवाली नगर',
    'लखनऊ',
    'Uttar Pradesh',
    'श्यामू उर्फ़ श्याम (डमी अभियुक्त)',
    'JUDICIAL_CUSTODY',
    'राम प्रकाश (काल्पनिक वादी)',
    'HYBRID',
    ARRAY['379 IPC', '411 IPC', '303 BNS', '317(2) BNS'],
    'मुख्य न्यायिक मजिस्ट्रेट (CJM)',
    'जमानत प्रार्थना पत्र सं. 102/2026',
    'BAIL_HEARING',
    (current_date + interval '3 days'),
    'अधिवक्ता आवेदक उपस्थित। राज्य को केस डायरी प्रस्तुत करने हेतु आदेशित।'
) on conflict (id) do nothing;

-- 4. Synthetic Verified Precedent for Grounding Tests (Section 411 IPC)
insert into public.verified_precedents (
    id,
    citation_id,
    case_title,
    court_name,
    bench_type,
    judgment_date,
    act_name,
    section_numbers,
    headnote_hindi,
    verbatim_text,
    paragraph_number,
    verified_source_url,
    embedding
) values (
    'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
    'TEST_2024_ALHC_411_DUMMY',
    'रमेश बनाम उत्तर प्रदेश राज्य (डमी मिसाल)',
    'इलाहाबाद उच्च न्यायालय',
    'SINGLE_BENCH',
    '2024-02-15',
    'IPC',
    ARRAY['379', '411'],
    'केवल कथित बरामदगी के आधार पर धारा 411 का अपराध सिद्ध नहीं होता, जब तक कि चुराई हुई संपत्ति होने का ज्ञान या विश्वास साबित न हो। स्वतंत्र गवाहों के अभाव में जब्ती संदेहास्पद हो जाती है।',
    'यह स्थापित विधिक सिद्धांत है कि धारा 411 भा.दं.वि. के तहत दोषसिद्धि हेतु मात्र जब्ती पर्याप्त नहीं है। अभियोजन पक्ष को यह सिद्ध करना अनिवार्य है कि अभियुक्त जानता था या उसके पास यह विश्वास करने का कारण था कि संपत्ति चोरी की है। स्वतंत्र साक्षियों की अनुपस्थिति जब्ती को संदेहास्पद बनाती है।',
    14,
    'https://judgments.ecourts.gov.in/dummy_verified_record_411',
    array_fill(0.0125::float, ARRAY[768])::extensions.vector
) on conflict (citation_id) do nothing;
