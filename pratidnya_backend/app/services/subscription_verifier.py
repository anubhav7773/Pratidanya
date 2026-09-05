import logging
from datetime import datetime, timezone
from typing import Dict, Any
from google.oauth2 import service_account
from googleapiclient.discovery import build
from fastapi import HTTPException
from app.core.config import settings
from app.core.database import get_supabase_admin_client

logger = logging.getLogger("pratidnya.billing")

class GooglePlaySubscriptionVerifier:
    def __init__(self):
        self.package_name = "me.asiverticals.pratidnya"
        self._publisher_service = None

    def _get_publisher_service(self):
        if self._publisher_service is None:
            creds_dict = settings.get_firebase_credentials_dict()
            if not creds_dict:
                raise RuntimeError("Google Service Account credentials missing in backend configuration.")
            
            credentials = service_account.Credentials.from_service_account_info(
                creds_dict,
                scopes=["https://www.googleapis.com/auth/androidpublisher"]
            )
            self._publisher_service = build("androidpublisher", "v3", credentials=credentials)
        return self._publisher_service

    async def verify_and_activate_subscription(
        self,
        advocate_id: str,
        product_id: str,
        purchase_token: str
    ) -> Dict[str, Any]:
        """
        Anti-Replay Validation & Server-Side Google Play Receipt Verification.
        Atomically updates advocate_subscriptions and triggers AI quota elevation.
        """
        supabase = get_supabase_admin_client()

        # Step 1: Anti-Replay Guard
        existing_token = supabase.table("advocate_subscriptions") \
            .select("advocate_id, subscription_status") \
            .eq("purchase_token", purchase_token) \
            .maybe_single() \
            .execute()

        if existing_token and existing_token.data:
            if existing_token.data["advocate_id"] != advocate_id:
                logger.warning(f"Security Alert: Replay attack detected for token {purchase_token}")
                raise HTTPException(
                    status_code=403,
                    detail="सुरक्षा उल्लंघन: यह खरीद रसीद पहले से किसी अन्य खाते में सक्रिय है।"
                )

        # Step 2: Query Google Play Android Publisher API
        try:
            service = self._get_publisher_service()
            request = service.purchases().subscriptionsv2().get(
                packageName=self.package_name,
                token=purchase_token
            )
            response = request.execute()
        except Exception as e:
            logger.error(f"Google Play Publisher API Call Failed: {e}")
            raise HTTPException(
                status_code=502,
                detail=f"Google Play सर्वर से रसीद सत्यापन विफल: {str(e)}"
            )

        # Step 3: Parse Subscription State
        subscription_state = response.get("subscriptionState")
        line_items = response.get("lineItems", [])
        
        if not line_items:
            raise HTTPException(status_code=400, detail="अमान्य सदस्यता मद (No line items found).")

        line_item = line_items[0]
        expiry_time_str = line_item.get("expiryTime")
        auto_renewing_plan = line_item.get("autoRenewingPlan", {})
        is_auto_renewing = auto_renewing_plan.get("autoRenewEnabled", False)

        is_active = subscription_state in [
            "SUBSCRIPTION_STATE_ACTIVE",
            "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
        ]

        if not is_active:
            raise HTTPException(
                status_code=400,
                detail=f"सदस्यता सक्रिय नहीं है। वर्तमान स्थिति: {subscription_state}"
            )

        # Step 4: Persist in Supabase advocate_subscriptions Table
        subscription_payload = {
            "advocate_id": advocate_id,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "order_id": response.get("latestOrderId", f"GPA.LOCAL-{int(datetime.now().timestamp())}"),
            "subscription_status": "ACTIVE" if subscription_state == "SUBSCRIPTION_STATE_ACTIVE" else "IN_GRACE_PERIOD",
            "auto_renewing": is_auto_renewing,
            "start_time": response.get("startTime", datetime.now(timezone.utc).isoformat()),
            "expiry_time": expiry_time_str,
            "payment_method_type": "GOOGLE_PLAY",
            "price_currency_code": "INR",
            "price_amount_micros": 499000000 if "monthly" in product_id else 4999000000,
            "country_code": response.get("regionCode", "IN"),
            "raw_google_play_response": response,
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

        supabase.table("advocate_subscriptions") \
            .upsert(subscription_payload, on_conflict="purchase_token") \
            .execute()

        # Step 5: Elevate AI Quota tier to PRO_CHAMBER
        supabase.table("advocate_ai_quotas") \
            .update({
                "subscription_tier": "PRO_CHAMBER",
                "updated_at": datetime.now(timezone.utc).isoformat()
            }) \
            .eq("advocate_id", advocate_id) \
            .execute()

        return {
            "status": "SUCCESS",
            "subscription_status": subscription_payload["subscription_status"],
            "expiry_time": expiry_time_str,
            "tier": "PRO_CHAMBER"
        }
