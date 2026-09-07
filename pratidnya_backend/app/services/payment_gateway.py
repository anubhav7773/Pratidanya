import hmac
import hashlib
import logging
from abc import ABC, abstractmethod
from datetime import datetime, timedelta, timezone
from typing import Dict, Any
from fastapi import HTTPException, status
from app.core.config import settings

logger = logging.getLogger("pratidnya.payment")

class PaymentGateway(ABC):
    """Abstract Strategy for Payment Processing."""

    @abstractmethod
    async def create_subscription_order(
        self,
        advocate_id: str,
        plan_id: str,
        amount_inr: int
    ) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def verify_payment_and_activate(
        self,
        advocate_id: str,
        order_id: str,
        payment_id: str,
        signature: str,
        supabase_client: Any
    ) -> Dict[str, Any]:
        pass


class SandboxDummyPaymentGateway(PaymentGateway):
    """
    Testing / Sandbox Gateway:
    Provides deterministic simulated payments without bank or Play Store charges.
    Activated whenever PAYMENT_MODE='SANDBOX_DUMMY'.
    """

    async def create_subscription_order(
        self,
        advocate_id: str,
        plan_id: str,
        amount_inr: int
    ) -> Dict[str, Any]:
        timestamp = int(datetime.now(timezone.utc).timestamp())
        mock_order_id = f"order_sandbox_{timestamp}_{advocate_id[:6]}"
        logger.info(f"[Payment Sandbox] Created simulated order: {mock_order_id} for advocate {advocate_id}")

        return {
            "order_id": mock_order_id,
            "amount_inr": amount_inr,
            "currency": "INR",
            "key_id": "rzp_test_sandbox_dummy_key",
            "plan_id": plan_id,
            "is_sandbox": True
        }

    async def verify_payment_and_activate(
        self,
        advocate_id: str,
        order_id: str,
        payment_id: str,
        signature: str,
        supabase_client: Any
    ) -> Dict[str, Any]:
        logger.info(f"[Payment Sandbox] Verifying simulated transaction: {order_id} / {payment_id}")

        # Deterministic check for simulated signatures
        if not (signature.startswith("sig_sandbox_") or signature in ["sandbox_valid_test_signature", "mock_checkout_signature"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="सैंडबॉक्स भुगतान सत्यापन विफल: अमान्य परीक्षण सिग्नेचर।"
            )

        now = datetime.now(timezone.utc)
        expiry = now + timedelta(days=30)

        # 1. Record subscription in Supabase
        sub_payload = {
            "advocate_id": advocate_id,
            "product_id": "pratidnya_chamber_pro_monthly",
            "purchase_token": f"sandbox_token_{order_id}",
            "order_id": order_id,
            "subscription_status": "ACTIVE",
            "auto_renewing": True,
            "start_time": now.isoformat(),
            "expiry_time": expiry.isoformat(),
            "payment_method_type": "SANDBOX_SIMULATOR",
            "price_currency_code": "INR",
            "price_amount_micros": 499000000,
            "country_code": "IN",
            "raw_google_play_response": {"mode": "SANDBOX_DUMMY", "payment_id": payment_id},
            "updated_at": now.isoformat()
        }

        try:
            supabase_client.table("advocate_subscriptions") \
                .upsert(sub_payload, on_conflict="purchase_token") \
                .execute()
        except Exception as e:
            logger.warning(f"Could not persist subscription record: {e}")

        # 2. Elevate Advocate AI Quota (Fixes BIL-03: handles missing quota via upsert)
        quota_payload = {
            "advocate_id": advocate_id,
            "subscription_tier": "PRO_CHAMBER",
            "daily_drafts_remaining": 9999,
            "ad_rewarded_drafts": 999,
            "updated_at": now.isoformat()
        }

        try:
            supabase_client.table("advocate_ai_quotas") \
                .upsert(quota_payload, on_conflict="advocate_id") \
                .execute()
        except Exception as e:
            logger.warning(f"Could not elevate quota record: {e}")

        return {
            "status": "SUCCESS",
            "subscription_status": "ACTIVE",
            "tier": "PRO_CHAMBER",
            "expiry_time": expiry.isoformat(),
            "message": "सैंडबॉक्स परीक्षण: प्रो चैंबर सदस्यता सफलतापूर्वक सक्रिय की गई।"
        }


class RazorpayLivePaymentGateway(PaymentGateway):
    """
    100% Production Razorpay Gateway:
    Integrates live HMAC-SHA256 signature verification and rejects all synthetic bypasses.
    Activated whenever PAYMENT_MODE='PRODUCTION'.
    """

    def __init__(self):
        if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
            raise RuntimeError("CRITICAL: RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET are mandatory in PRODUCTION mode.")

    async def create_subscription_order(
        self,
        advocate_id: str,
        plan_id: str,
        amount_inr: int
    ) -> Dict[str, Any]:
        import httpx
        url = "https://api.razorpay.com/v1/orders"
        auth = (settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
        payload = {
            "amount": amount_inr * 100, # Razorpay expects paise
            "currency": "INR",
            "receipt": f"rcpt_{advocate_id[:8]}_{int(datetime.now().timestamp())}",
            "notes": {
                "advocate_id": advocate_id,
                "plan_id": plan_id
            }
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(url, auth=auth, json=payload)
            if res.status_code not in [200, 201]:
                logger.error(f"Razorpay live order creation failed ({res.status_code}): {res.text}")
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="रेजरपे पेमेंट गेटवे से संपर्क स्थापित नहीं हो सका।"
                )
            data = res.json()
            return {
                "order_id": data["id"],
                "amount_inr": amount_inr,
                "currency": "INR",
                "key_id": settings.RAZORPAY_KEY_ID,
                "plan_id": plan_id,
                "is_sandbox": False
            }

    async def verify_payment_and_activate(
        self,
        advocate_id: str,
        order_id: str,
        payment_id: str,
        signature: str,
        supabase_client: Any
    ) -> Dict[str, Any]:
        # Strict HMAC-SHA256 signature verification (Eliminates BIL-01 bypass)
        message = f"{order_id}|{payment_id}"
        expected_signature = hmac.new(
            key=settings.RAZORPAY_KEY_SECRET.encode("utf-8"),
            msg=message.encode("utf-8"),
            digestmod=hashlib.sha256
        ).hexdigest()

        if not hmac.compare_digest(expected_signature, signature):
            logger.error(f"Security Alert: Signature mismatch for order {order_id}. Possible tampering.")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="भुगतान सत्यापन विफल: अमान्य डिजिटल हस्ताक्षर।"
            )

        now = datetime.now(timezone.utc)
        expiry = now + timedelta(days=30)

        # Record in Supabase
        sub_payload = {
            "advocate_id": advocate_id,
            "product_id": "pratidnya_chamber_pro_monthly",
            "purchase_token": payment_id,
            "order_id": order_id,
            "subscription_status": "ACTIVE",
            "auto_renewing": True,
            "start_time": now.isoformat(),
            "expiry_time": expiry.isoformat(),
            "payment_method_type": "RAZORPAY",
            "price_currency_code": "INR",
            "price_amount_micros": 499000000,
            "country_code": "IN",
            "updated_at": now.isoformat()
        }

        try:
            supabase_client.table("advocate_subscriptions") \
                .upsert(sub_payload, on_conflict="purchase_token") \
                .execute()
        except Exception as e:
            logger.warning(f"Could not persist subscription record: {e}")

        # Elevate Quota via upsert (Fixes BIL-03)
        quota_payload = {
            "advocate_id": advocate_id,
            "subscription_tier": "PRO_CHAMBER",
            "daily_drafts_remaining": 9999,
            "ad_rewarded_drafts": 999,
            "updated_at": now.isoformat()
        }

        try:
            supabase_client.table("advocate_ai_quotas") \
                .upsert(quota_payload, on_conflict="advocate_id") \
                .execute()
        except Exception as e:
            logger.warning(f"Could not elevate quota record: {e}")

        return {
            "status": "SUCCESS",
            "subscription_status": "ACTIVE",
            "tier": "PRO_CHAMBER",
            "expiry_time": expiry.isoformat(),
            "message": "प्रो चैंबर सदस्यता सफलतापूर्वक सक्रिय की गई।"
        }


def get_payment_gateway() -> PaymentGateway:
    """Factory returning appropriate gateway based on configuration."""
    if getattr(settings, "PAYMENT_MODE", "SANDBOX_DUMMY").upper() == "PRODUCTION":
        return RazorpayLivePaymentGateway()
    return SandboxDummyPaymentGateway()
