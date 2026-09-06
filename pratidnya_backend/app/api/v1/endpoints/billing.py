from fastapi import APIRouter, HTTPException, Security
from pydantic import BaseModel, Field
from typing import Dict, Any
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.services.subscription_verifier import GooglePlaySubscriptionVerifier

router = APIRouter(prefix="/billing", tags=["Billing, Quotas & Subscriptions"])

MAX_REWARDED_ADS_PER_DAY = 3

class VerifySubscriptionRequest(BaseModel):
    product_id: str = Field(..., description="e.g., pratidnya_chamber_pro_monthly")
    purchase_token: str = Field(..., description="Google Play Purchase Token string")

class VerifySubscriptionResponse(BaseModel):
    status: str
    subscription_status: str
    expiry_time: str
    tier: str

@router.post("/verify-subscription", response_model=VerifySubscriptionResponse)
async def verify_subscription_endpoint(
    payload: VerifySubscriptionRequest,
    current_user: dict = Security(verify_advocate_token)
):
    advocate_id = current_user["uid"]
    verifier = GooglePlaySubscriptionVerifier()

    result = await verifier.verify_and_activate_subscription(
        advocate_id=advocate_id,
        product_id=payload.product_id,
        purchase_token=payload.purchase_token
    )
    return VerifySubscriptionResponse(**result)

@router.post("/claim-ad-reward")
async def claim_ad_reward_endpoint(current_user: dict = Security(verify_advocate_token)):
    """
    BCI Rule 36 Compliant Ad-Reward Engine:
    Validates advocate daily ceiling and unlocks +1 AI Draft.
    """
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    quota_res = supabase.table("advocate_ai_quotas") \
        .select("ad_rewarded_drafts, daily_drafts_remaining, subscription_tier") \
        .eq("advocate_id", advocate_id) \
        .single() \
        .execute()

    quota = quota_res.data
    if quota["subscription_tier"] == "PRO_CHAMBER":
        return {"status": "ALREADY_PRO", "message": "प्रो चैंबर में असीमित कोटा पहले से सक्रिय है।"}

    current_rewarded = quota.get("ad_rewarded_drafts", 0)

    if current_rewarded >= MAX_REWARDED_ADS_PER_DAY:
        raise HTTPException(
            status_code=429,
            detail=f"दैनिक विज्ञापन सीमा समाप्त: आप प्रतिदिन अधिकतम {MAX_REWARDED_ADS_PER_DAY} बार ही विज्ञापन द्वारा ड्राफ्ट अनलॉक कर सकते हैं।"
        )

    new_count = current_rewarded + 1
    supabase.table("advocate_ai_quotas") \
        .update({
            "ad_rewarded_drafts": new_count,
            "updated_at": "now()"
        }) \
        .eq("advocate_id", advocate_id) \
        .execute()

    return {
        "status": "SUCCESS",
        "ad_rewarded_drafts_available": new_count,
        "message": "1 अतिरिक्त AI विधिक ड्राफ्ट सफलतापूर्वक अनलॉक किया गया।"
    }

@router.get("/status")
async def get_billing_status_endpoint(current_user: dict = Security(verify_advocate_token)):
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    quota_res = supabase.table("advocate_ai_quotas") \
        .select("subscription_tier, daily_drafts_remaining, ad_rewarded_drafts") \
        .eq("advocate_id", advocate_id) \
        .single() \
        .execute()

    sub_res = supabase.table("advocate_subscriptions") \
        .select("product_id, subscription_status, expiry_time, auto_renewing") \
        .eq("advocate_id", advocate_id) \
        .order("created_at", desc=True) \
        .limit(1) \
        .execute()

    active_sub = sub_res.data[0] if sub_res.data else None

    return {
        "quota": quota_res.data,
        "subscription": active_sub,
        "is_pro": quota_res.data.get("subscription_tier") == "PRO_CHAMBER"
    }

@router.get("/quota-status")
async def get_quota_status_endpoint(current_user: dict = Security(verify_advocate_token)):
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    quota_res = supabase.table("advocate_ai_quotas") \
        .select("*") \
        .eq("advocate_id", advocate_id) \
        .single() \
        .execute()

    return quota_res.data
