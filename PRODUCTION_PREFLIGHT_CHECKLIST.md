# Pratidnya Legal Tech — Production Pre-Flight Checklist

Before deploying Pratidnya Legal Tech (Asiverticals) to production, verify the following 5 statutory & architectural constraints:

| Layer | Verification Target | Production Value | Failure Consequence if Missed |
|---|---|---|---|
| **Backend Environment** | `GEMINI_PAID_TIER` | `true` | Real client case facts processing is blocked by Rule 6. |
| **Backend Environment** | `ENFORCE_DUMMY_DATA` | `false` | Real advocate data cannot be processed in live mode. |
| **Flutter Dart Defines** | `APP_ENV` | `PRODUCTION` | Security assertions trigger `StateError` on launch if unconfigured. |
| **AdMob Ads** | Ad Unit IDs | Real Asiverticals Unit IDs | Google test ads remain visible in production release. |
| **Google Play Console** | SKU Products | `pratidnya_chamber_pro_monthly`, `pratidnya_chamber_pro_yearly` | Subscriptions fail to load from Play Store billing sheets. |

---

## 1. Statutory Compliance Verification
- **DPDP Act 2023 Sec 5/6 & Advocates Act 1961 Sec 30:** Mandatory gate consent and bar enrollment verification must be active.
- **BCI Rule 5:** Zero hallucinated citations; verify all citations contain verifiable URLs and meet the $\ge 0.65$ similarity threshold or trigger the Abstain Engine.
- **Section 35 Gate:** 100% manual advocate verification required before PDF export.
- **Court Petition Format:** 1.5" left margin binding space (`left: 108.0 pt`) enforced on Legal-size paper.

## 2. Pre-Flight Verification Commands
```bash
# 1. Run full backend test suite (including E2E pipeline)
cd pratidnya_backend
python -m pytest -v

# 2. Run full Flutter analysis and test suite
cd ../frontend
flutter analyze lib
flutter test
```
