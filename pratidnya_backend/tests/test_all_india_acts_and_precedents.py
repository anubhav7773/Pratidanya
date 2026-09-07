import json
import os
import pytest
from app.api.v1.endpoints.drafts import (
    LIVE_PRECEDENT_URLS,
    extract_statutory_section_tokens,
)
from app.services.llm_gateway import LLMGateway


def test_real_criminal_precedents_integrity():
    """Verify all 35 verified criminal precedents exist with real URLs and valid structures."""
    corpus_path = os.path.join(
        os.path.dirname(__file__), "..", "data", "corpus", "real_criminal_precedents.json"
    )
    assert os.path.exists(corpus_path), f"File {corpus_path} does not exist"

    with open(corpus_path, "r", encoding="utf-8") as f:
        precedents = json.load(f)

    assert len(precedents) == 35, f"Expected 35 precedents, got {len(precedents)}"

    found_acts = set()
    for p in precedents:
        assert p.get("citation_id"), f"Missing citation_id in {p}"
        assert p.get("case_title"), f"Missing case_title in {p}"
        assert p.get("court_name"), f"Missing court_name in {p}"
        assert p.get("act_name"), f"Missing act_name in {p}"
        assert p.get("section_numbers"), f"Missing section_numbers in {p}"
        assert len(p["section_numbers"]) > 0
        assert p.get("headnote_hindi"), f"Missing headnote_hindi in {p}"
        assert p.get("verbatim_text"), f"Missing verbatim_text in {p}"
        assert p.get("verified_source_url"), f"Missing verified_source_url in {p}"
        assert p["verified_source_url"].startswith("https://"), (
            f"Invalid URL for {p['citation_id']}: {p['verified_source_url']}"
        )
        found_acts.add(p["act_name"])

    # Ensure all target acts are covered
    assert "ARMS_ACT" in found_acts
    assert "GANGSTERS_ACT" in found_acts
    assert "EXCISE_ACT" in found_acts
    assert "SC_ST_ACT" in found_acts
    assert "CrPC / BNSS / PMLA" in found_acts
    assert "UAPA" in found_acts
    assert "PC_ACT" in found_acts
    assert "NI_ACT" in found_acts
    assert "MMDR_ACT" in found_acts
    assert "COW_SLAUGHTER_ACT" in found_acts
    assert "NDPS" in found_acts
    assert "POCSO / JJ_ACT" in found_acts
    assert "IT_ACT" in found_acts
    assert "IPC / BNS" in found_acts
    assert "BSA / IEA" in found_acts


def test_live_precedent_urls_coverage():
    """Verify LIVE_PRECEDENT_URLS has at least 35 real HTTPS URLs with valid hosts."""
    assert len(LIVE_PRECEDENT_URLS) >= 35
    for citation, url in LIVE_PRECEDENT_URLS.items():
        assert url.startswith("https://"), f"URL for {citation} must start with https://: {url}"
        assert "indiankanoon.org" in url or "digiscr" in url or "ecourts.gov.in" in url


def test_extract_statutory_section_tokens_for_all_acts():
    """Verify the detector extracts numeric tokens and statutory keywords for all Indian Acts."""
    scenarios = [
        (["25", "27 Arms Act"], "ARMS_ACT"),
        (["Section 2/3 UP Gangsters Act"], "GANGSTERS_ACT"),
        (["60 UP Excise Act"], "EXCISE_ACT"),
        (["3(1)(r)", "3(1)(s) SC/ST Act"], "SC_ST_ACT"),
        (["45 PMLA", "3 PMLA"], "PMLA"),
        (["43D(5) UAPA", "18 UAPA"], "UAPA"),
        (["66D IT Act"], "IT_ACT"),
        (["3/5/8 Cow Slaughter Act"], "गोवध_अधिनियम"),
        (["7 PC Act", "13(1)(b)"], "PC_ACT"),
        (["138 NI Act"], "NI_ACT"),
        (["4/21 MMDR Act"], "MMDR_ACT"),
        (["8 POCSO", "354 IPC"], "POCSO"),
        (["50 NDPS", "20 NDPS Act"], "NDPS"),
        (["302 IPC"], "103_BNS"),
        (["379 IPC"], "303_BNS"),
        (["498A IPC"], "85_BNS"),
        (["420 IPC"], "318_BNS"),
    ]

    for sections_input, expected_token in scenarios:
        tokens = extract_statutory_section_tokens(sections_input)
        assert expected_token in tokens, f"Expected {expected_token} in {tokens} for {sections_input}"


def test_llm_gateway_emergency_statutory_draft_all_acts():
    """Verify LLMGateway emergency statutory draft generates custom legal grounds for various acts."""
    scenarios = [
        ("एफ.आई.आर. संख्या : 101/2026\nथाना एवं जिला : कोतवाली, लखनऊ\nधारा : 25/27 Arms Act (आयुध अधिनियम)", "Conscious Possession"),
        ("एफ.आई.आर. संख्या : 102/2026\nथाना एवं जिला : सिविल लाइन्स, प्रयागराज\nधारा : 2/3 UP Gangsters Act गिरोहबंद अधिनियम", "गैंग चार्ट"),
        ("एफ.आई.आर. संख्या : 103/2026\nथाना एवं जिला : सदर, वाराणसी\nधारा : 60 Excise Act आबकारी अधिनियम शराब", "मदिगा बूसेन्ना"),
        ("एफ.आई.आर. संख्या : 104/2026\nथाना एवं जिला : नौबस्ता, कानपुर\nधारा : 3(1)(r) SC/ST Act अत्याचार अधिनियम", "सार्वजनिक दृष्टिगोचर"),
        ("एफ.आई.आर. संख्या : 105/2026\nथाना एवं जिला : कोतवाली, मेरठ\nधारा : 7/8 POCSO Act पोक्सो नाबालिग", "धारा 94"),
        ("एफ.आई.आर. संख्या : 106/2026\nथाना एवं जिला : कैंट, बरेली\nधारा : 8/20 NDPS Act गांजा चरस", "धारा 50"),
        ("एफ.आई.आर. संख्या : 107/2026\nथाना एवं जिला : हजरतगंज, लखनऊ\nधारा : 3/4 PMLA ईडी धन शोधन", "विजय मदनलाल"),
        ("एफ.आई.आर. संख्या : 108/2026\nथाना एवं जिला : गोमती नगर, लखनऊ\nधारा : 420/467 धोखाधड़ी कूटकरण", "मोहम्मद इब्राहिम"),
        ("एफ.आई.आर. संख्या : 109/2026\nथाना एवं जिला : ट्रांस यमुना, आगरा\nधारा : 498A/304B दहेज विवाहिता", "कहकशां कौसर"),
        ("एफ.आई.आर. संख्या : 110/2026\nथाना एवं जिला : सदर, गोरखपुर\nधारा : 302 हत्या कत्ल murder", "परिस्थितिजन्य साक्ष्य"),
    ]

    for prompt, expected_keyword in scenarios:
        draft = LLMGateway._build_emergency_statutory_draft(prompt)
        assert "court_header" in draft
        assert "case_title" in draft
        assert "statutory_grounds" in draft
        assert len(draft["statutory_grounds"]) >= 3
        all_text = " ".join(draft["statutory_grounds"]) + " ".join(draft["prosecution_weaknesses"])
        assert expected_keyword in all_text, (
            f"Expected '{expected_keyword}' in draft for prompt:\n{prompt}\nGot:\n{all_text}"
        )
