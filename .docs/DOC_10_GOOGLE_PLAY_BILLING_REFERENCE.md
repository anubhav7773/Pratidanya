================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-10
MODULE         : GOOGLE PLAY BILLING, IN-APP PURCHASES & SUBSCRIPTION BACKEND
TARGET RUNTIME : Flutter (in_app_purchase ^3.2.0) / FastAPI (Python 3.10+)
BILLING LIB    : Google Play Billing Library 6.0+ / 7.0+
PAYMENT RAILS  : Google Play Console (India UPI, RuPay, Cards, NetBanking)
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. SUBSCRIPTION TIERS & SKU MONETIZATION MATRIXPratidnya monetization model district-court solo advocates aur micro-chambers ke budget ke hisaab se design kiya gaya hai:Plan NameProduct ID (SKU)Billing CyclePrice (INR)Daily AI DraftsKanoon LookupsAd ExperienceKey CapabilitiesFree TierN/A (Default)Lifetime₹03 Drafts / Day5 Searches / DayAd-SupportedBasic Bail grounds, Watermarked PDF Export, Ads unlock extra quotaChamber Pro Monthlypratidnya_chamber_pro_monthlyAuto-renew 1 Month₹499 / moUnlimitedUnlimitedZero AdsHigh Court PDF judgments, Clean Court Export without watermarkChamber Pro Annualpratidnya_chamber_pro_yearlyAuto-renew 1 Year₹4,999 / yrUnlimitedUnlimitedZero AdsAll Pro features + 2 Months Free + Priority Model Queue┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT (UI LAYER)                       │
│  - User triggers "चैंबर प्रो में अपग्रेड करें" on Paywall Screen      │
│  - `in_app_purchase` launches Google Play Billing Native Sheet         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Completes Payment (UPI/Card)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 PURCHASE STREAM LISTENER (FLUTTER)                     │
│  - Catches PurchaseStatus.purchased                                    │
│  - Extracts: purchaseToken, productId, orderId                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ POST /api/v1/billing/verify-subscription
                                    │ (Bearer <Firebase_ID_Token>)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             FASTAPI BACKEND (SERVER-SIDE RECEIPT VALIDATION)           │
│  1. Idempotency Check: Ensures purchaseToken not replayed              │
│  2. Calls Google Play Developer API (androidpublisher v3)             │
│  3. Validates subscriptionState == SUBSCRIPTION_STATE_ACTIVE           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Updates DB
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   SUPABASE DATABASE (SUBSCRIPTIONS)                    │
│  - Sets `advocate_subscriptions`: status = 'ACTIVE'                   │
│  - Sets `advocate_ai_quotas`: subscription_tier = 'PRO_CHAMBER'        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTP 200 Success
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     FINALIZING CLIENT TRANSACTION                      │
│  - Flutter calls: InAppPurchase.instance.completePurchase()            │
│  - UI unlocks unlimited drafts instantly                               │
└────────────────────────────────────────────────────────────────────────┘
2. SUPABASE DATABASE SCHEMA (SUBSCRIPTION STATE DDL)Antigravity ko migration script mein subscription tables aur triggers define karne hain:SQL-- ============================================================================
-- 1. ADVOCATE SUBSCRIPTIONS MASTER TABLE
-- ============================================================================
create table public.advocate_subscriptions (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    product_id text not null,                       -- 'pratidnya_chamber_pro_monthly' or 'pratidnya_chamber_pro_yearly'
    purchase_token text unique not null,            -- Google Play unique purchase token
    order_id text,                                  -- Google Play GPA.XXXX-XXXX-XXXX-XXXXX
    subscription_status text not null,              -- 'ACTIVE', 'PAUSED', 'IN_GRACE_PERIOD', 'ON_HOLD', 'EXPIRED', 'CANCELED'
    auto_renewing boolean default true not null,
    start_time timestamp with time zone not null,
    expiry_time timestamp with time zone not null,
    payment_method_type text default 'GOOGLE_PLAY',
    price_currency_code text default 'INR',
    price_amount_micros bigint not null,            -- e.g. 499000000 for 499.00 INR
    country_code text default 'IN',
    raw_google_play_response jsonb default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Indexing for quick lookups during quota queries
create index idx_advocate_subscriptions_lookup 
on public.advocate_subscriptions(advocate_id, subscription_status);

create index idx_advocate_subscriptions_token 
on public.advocate_subscriptions(purchase_token);

-- ============================================================================
-- 2. SUBSCRIPTION SYNC TRIGGER WITH AI QUOTA TABLE
-- ============================================================================
create or replace function sync_advocate_quota_on_subscription_change()
returns trigger as $$
begin
    if (new.subscription_status = 'ACTIVE' or new.subscription_status = 'IN_GRACE_PERIOD') then
        -- Upgrade Advocate AI Quota to PRO
        update public.advocate_ai_quotas
        set 
            subscription_tier = 'PRO_CHAMBER',
            daily_drafts_remaining = 9999,
            updated_at = timezone('utc'::text, now())
        where advocate_id = new.advocate_id;
    else
        -- Revert to Free Tier if expired/canceled
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

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
alter table public.advocate_subscriptions enable row level security;

create policy "Advocates can view own active subscriptions"
    on public.advocate_subscriptions
    for select
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

-- Writes are restricted: Only Backend Service Role can insert/update validated receipts
create policy "Service role has full write access to subscriptions"
    on public.advocate_subscriptions
    for all
    to service_role
    using (true)
    with check (true);
3. SERVER-SIDE RECEIPT VERIFICATION (FASTAPI & GOOGLE PUBLISHER API)Client receipts par kabhi blindly bharosa nahi kiya ja sakta. Backend Google Play Android Publisher API (purchases.subscriptionsv2.get) ko call karke receipt verify karega:Dependencies (pratidnya_backend/requirements.txt)Plaintextgoogle-api-python-client==2.122.0
google-auth==2.28.2
google-auth-httplib2==0.2.0
Python Verification Module (subscription_verifier.py)Python# app/services/subscription_verifier.py
import logging
from datetime import datetime, timezone
from typing import Dict, Any
from google.oauth2 import service_account
from googleapiclient.discovery import build
from fastapi import HTTPException
from app.core.config import settings
from app.core.supabase_client import get_supabase_admin_client

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
        Calls Google Play Developer API, validates token, and upserts Supabase record.
        Prevents token replay attacks by checking unique token constraints.
        """
        supabase = get_supabase_admin_client()

        # Step 1: Anti-Replay Guard — Check if purchase_token was used by another user
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
            # Google Play Subscriptions v2 API
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
        # States: SUBSCRIPTION_STATE_ACTIVE, SUBSCRIPTION_STATE_IN_GRACE_PERIOD, etc.
        subscription_state = response.get("subscriptionState")
        line_items = response.get("lineItems", [])
        
        if not line_items:
            raise HTTPException(status_code=400, detail="अमान्य सदस्यता मद (No line items found).")

        line_item = line_items[0]
        expiry_time_str = line_item.get("expiryTime") # ISO RFC 3339 format
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

        # Step 4: Persist in Supabase `advocate_subscriptions` Table
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

        upsert_res = supabase.table("advocate_subscriptions") \
            .upsert(subscription_payload, on_conflict="purchase_token") \
            .execute()

        return {
            "status": "SUCCESS",
            "subscription_status": subscription_payload["subscription_status"],
            "expiry_time": expiry_time_str,
            "tier": "PRO_CHAMBER"
        }
Verification Route HandlerPython# app/api/v1/endpoints/billing.py
from fastapi import APIRouter, HTTPException, Depends, Security
from pydantic import BaseModel, Field
from app.core.security import verify_advocate_token
from app.services.subscription_verifier import GooglePlaySubscriptionVerifier

router = APIRouter(prefix="/billing", tags=["Google Play Billing"])

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
4. FLUTTER INTEGRATION (IN_APP_PURCHASE SETUP)A. Dependencies (pubspec.yaml)YAMLdependencies:
  in_app_purchase: ^3.2.0
B. Purchase Controller & Stream Listener (Riverpod 2.x)Dart// lib/src/features/billing/presentation/controllers/subscription_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_environment.dart';

final subscriptionControllerProvider = StateNotifierProvider<SubscriptionController, AsyncValue<bool>>((ref) {
  return SubscriptionController();
});

class SubscriptionController extends StateNotifier<AsyncValue<bool>> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscriptionStream;

  static const String monthlySku = 'pratidnya_chamber_pro_monthly';
  static const String yearlySku = 'pratidnya_chamber_pro_yearly';
  static const Set<String> _kProductIds = {monthlySku, yearlySku};

  List<ProductDetails> availableProducts = [];

  SubscriptionController() : super(const AsyncValue.data(false)) {
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("Google Play Store अनुपलब्ध है।");
      return;
    }

    // Listen to Purchase Stream
    _subscriptionStream = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscriptionStream?.cancel(),
      onError: (error) => debugPrint("Billing Stream Error: $error"),
    );

    // Fetch Product Details from Play Store
    final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
    if (response.error == null) {
      availableProducts = response.productDetails;
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    state = const AsyncValue.loading();
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      state = AsyncValue.error('खरीद आरंभ विफल: $e', StackTrace.current);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Indian Payment rails (UPI delays, Netbanking approval)
          state = const AsyncValue.loading();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool valid = await _verifyWithBackend(purchase);
          if (valid) {
            // CRITICAL: Complete transaction with Google Play to prevent automatic refund
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            state = const AsyncValue.data(true);
          } else {
            state = AsyncValue.error('सर्वर रसीद सत्यापन विफल हुआ।', StackTrace.current);
          }
          break;

        case PurchaseStatus.error:
          state = AsyncValue.error(
            purchase.error?.message ?? 'लेन-देन रद्द या विफल हुआ।',
            StackTrace.current,
          );
          break;

        case PurchaseStatus.canceled:
          state = const AsyncValue.data(false);
          break;
      }
    }
  }

  Future<bool> _verifyWithBackend(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/billing/verify-subscription');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'product_id': purchase.productID,
          'purchase_token': purchase.verificationData.serverVerificationData,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Backend Verification Exception: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
5. COURT-READY PAYWALL UI (STITCH DESIGN SPECIFICATION)Advocate chamber UI clean, high-contrast aur distraction-free honi chahiye:Dart// lib/src/features/billing/presentation/screens/paywall_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/subscription_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(subscriptionControllerProvider);
    final billingController = ref.read(subscriptionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('प्रतिज्ञा चैंबर प्रो (Chamber Pro)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'जिला न्यायालय आपराधिक विधि अभ्यास हेतु असीमित शक्ति',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.courtNavy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'प्रतिदिन के AI कोटा प्रतिबंधों और विज्ञापनों से मुक्त होकर कार्य करें।',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(context, 'असीमित 360° जमानत प्रार्थना पत्र एवं बहस के बिंदु'),
              _buildFeatureItem(context, 'उच्च न्यायालय एवं उच्चतम न्यायालय के निर्णयों की पूर्ण PDF प्रतियों तक पहुंच'),
              _buildFeatureItem(context, 'कोर्ट फाइलिंग हेतु वॉटरमार्क-मुक्त PDF एक्सपोर्ट'),
              _buildFeatureItem(context, 'पूर्णतः विज्ञापन-मुक्त निर्बाध न्यायालयीन अनुभव'),
              const Spacer(),
              if (billingState.isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildPricingCard(
                  context,
                  title: 'मासिक सदस्यता (Monthly Pro)',
                  price: '₹499 / माह',
                  subtitle: 'बिना किसी दीर्घकालिक अनुबंध के, कभी भी रद्द करें',
                  isRecommended: false,
                  onTap: () {
                    final monthlyProduct = billingController.availableProducts.firstWhere(
                      (p) => p.id == SubscriptionController.monthlySku,
                    );
                    billingController.buySubscription(monthlyProduct);
                  },
                ),
                const SizedBox(height: 12),
                _buildPricingCard(
                  context,
                  title: 'वार्षिक सदस्यता (Annual Pro)',
                  price: '₹4,999 / वर्ष',
                  subtitle: '2 माह निःशुल्क (₹1,000 की बचत) + प्राथमिकता सपोर्ट',
                  isRecommended: true,
                  onTap: () {
                    final yearlyProduct = billingController.availableProducts.firstWhere(
                      (p) => p.id == SubscriptionController.yearlySku,
                    );
                    billingController.buySubscription(yearlyProduct);
                  },
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'सुरक्षित भुगतान Google Play UPI / कार्ड्स द्वारा प्रबंधित है।',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.verifiedGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isRecommended ? AppColors.courtNavy : Colors.white,
          border: Border.all(
            color: isRecommended ? AppColors.courtNavy : AppColors.borderSubtle,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isRecommended ? Colors.white : AppColors.courtNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isRecommended ? Colors.grey.shade300 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRecommended ? Colors.amber : AppColors.courtNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
6. HANDLING INDIAN PAYMENT RAILS & ASYNCHRONOUS PENDING PURCHASESIndia mein Google Play purchases par UPI (Google Pay, PhonePe, Paytm) aur Net Banking primary payment methods hain:Asynchronous UPI Delays: Lawyer Google Play dialog se UPI app switch karta hai aur PIN enter karta hai. Is duration mein status PurchaseStatus.pending rehta hai.Non-Blocking Strategy: UI ko freeze na karein; ek snackbar show karein: "UPI भुगतान प्रक्रियाधीन है। बैंक अनुमोदन मिलते ही चैंबर प्रो स्वतः सक्रिय हो जाएगा।"Auto-Acknowledge Compliance: Google Play policy ke anusar purchase hone ke 3 din ke andar receipt acknowledge (completePurchase()) honi chahiye, warna Google Play customer ko automatic refund issue kar deta hai.7. ANTIGRAVITY NON-NEGOTIABLE BILLING CHECKLIST (DOC-10)Antigravity code likhte waqt in exact technical assertions ko verify karega:[ ] Direct client side par subscription active karne ka logic nahi hoga; subscription status hamesha FastAPI /verify-subscription response se aayega.[ ] Call to InAppPurchase.instance.completePurchase(purchaseDetails) is mandatory after backend verification to prevent automatic refund by Google Play.[ ] Token anti-replay protection: purchase_token table column has a UNIQUE constraint, and the backend verifies ownership before activation.[ ] Trigger trg_sync_advocate_subscription_status must exist to atomically elevate advocate_ai_quotas tier to PRO_CHAMBER.[ ] App must provide a "सदस्यता बहाल करें (Restore Purchases)" button for lawyers switching or reinstalling devices.