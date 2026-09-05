import re
from typing import List, Dict, Any
from difflib import SequenceMatcher

class GroundingValidator:
    @staticmethod
    def calculate_similarity(a: str, b: str) -> float:
        return SequenceMatcher(None, a.lower().strip(), b.lower().strip()).ratio()

    @classmethod
    def verify_precedent_citations(
        cls,
        generated_citations: List[Dict[str, Any]],
        retrieved_precedents: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Rule 1 & Rule 2 Enforcement:
        Strips out any citation not found in the verified database pool
        or lacking a live, verifiable URL.
        """
        verified_list = []
        retrieved_ids = {p.get("citation_id"): p for p in retrieved_precedents}

        for citation in generated_citations:
            cit_id = citation.get("citation_id")
            if cit_id not in retrieved_ids:
                continue

            matched_source = retrieved_ids[cit_id]
            source_url = matched_source.get("verified_source_url") or matched_source.get("pdf_download_url")

            if not source_url or not (source_url.startswith("http://") or source_url.startswith("https://")):
                continue

            quoted_text = citation.get("quoted_passage", "").strip()
            source_full_text = matched_source.get("verbatim_text", "")

            is_grounded = True
            if quoted_text and source_full_text:
                if quoted_text.lower() not in source_full_text.lower():
                    best_ratio = 0.0
                    words = source_full_text.split()
                    quote_len = len(quoted_text.split())
                    for i in range(0, max(1, len(words) - quote_len + 1)):
                        window = " ".join(words[i:i + quote_len])
                        sim = cls.calculate_similarity(quoted_text, window)
                        if sim > best_ratio:
                            best_ratio = sim
                    if best_ratio < 0.85:
                        is_grounded = False

            if is_grounded:
                citation["verified_source_url"] = source_url
                citation["court_name"] = matched_source.get("court_name")
                citation["is_grounded_in_record"] = True
                verified_list.append(citation)

        return verified_list
