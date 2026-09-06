from datetime import date, timedelta
from typing import Dict, Any
from app.schemas.limitation_and_stay_schema import (
    LimitationCheckRequest,
    LimitationEvaluationResponse
)

class LimitationCalculator:
    """
    Statutory Limitation Computation Engine under the Limitation Act, 1963:
    1. Article 115(b), Schedule I: Criminal Appeal to High Court from Sessions Court = 60 Days.
    2. Article 131, Schedule I: Criminal Revision to High Court = 90 Days.
    3. Section 12(2) & 12(3): Mandatory exclusion of the day judgment was pronounced
       AND the requisite period for obtaining a certified copy of the impugned judgment.
    """

    STATUTORY_LIMITS: Dict[str, int] = {
        "CRIMINAL_APPEAL": 60,
        "CRIMINAL_REVISION": 90,
        "SECTION_482_APPLICATION": 90
    }

    @classmethod
    def evaluate_limitation(cls, req: LimitationCheckRequest) -> LimitationEvaluationResponse:
        statutory_days = cls.STATUTORY_LIMITS.get(req.pleading_type, 60)

        # Sanity Check on Certified Copy Dates
        if req.certified_copy_ready_date < req.certified_copy_applied_date:
            raise ValueError("प्रमाणित प्रति तैयार होने की तिथि आवेदन तिथि से पूर्व की नहीं हो सकती।")

        if req.certified_copy_applied_date < req.judgment_date:
            raise ValueError("नकल आवेदन की तिथि निर्णय सुनाए जाने की तिथि से पूर्व की नहीं हो सकती।")

        # Section 12 Exclusion: (Ready Date - Applied Date) + 1 day for application delivery
        excluded_copy_days = (req.certified_copy_ready_date - req.certified_copy_applied_date).days + 1

        # Total Elapsed Days from Judgment to Proposed Filing
        total_gross_days = (req.proposed_filing_date - req.judgment_date).days

        # Effective Days Consumed after Section 12 Exclusion
        effective_days_taken = max(0, total_gross_days - excluded_copy_days)

        # Limitation Expiry Date = Judgment Date + Statutory Limit + Excluded Copy Days
        limitation_expiry = req.judgment_date + timedelta(days=(statutory_days + excluded_copy_days))

        # Delay Calculation
        delay_days = max(0, effective_days_taken - statutory_days)
        is_delayed = delay_days > 0

        return LimitationEvaluationResponse(
            pleading_id=req.pleading_id,
            pleading_type=req.pleading_type,
            statutory_limitation_days=statutory_days,
            certified_copy_excluded_days=excluded_copy_days,
            effective_days_taken=effective_days_taken,
            is_delayed=is_delayed,
            delay_days=delay_days,
            limitation_expiry_date=limitation_expiry,
            must_file_section_5_application=is_delayed
        )
