# PRATIDNYA LEGAL TECH (ASIVERTICALS) — PRIVACY POLICY

**Effective Date:** September 6, 2026  
**Last Updated:** September 6, 2026  
**Application:** प्रतिज्ञा (Pratidnya) — जिला न्यायालय आपराधिक विधिक सहायक  
**Developer & Data Fiduciary:** Asiverticals (support@asiverticals.me / legal@asiverticals.me)  
**Governing Statutory Framework:**  
1. Digital Personal Data Protection Act, 2023 (DPDP Act, Act No. 22 of 2023, India)
2. Advocates Act, 1961 (Section 30, Right of Advocates to Practise; Section 35, Disciplinary Standards; Section 126, Professional Privilege)
3. Bar Council of India (BCI) Rules, Part VI, Chapter II, Section IV, Rule 36 (Prohibition against Solicitation & Advertising)

---

## 1. Statutory Purpose & Scope
प्रतिज्ञा (Pratidnya) is a private, confidential, closed-loop legal research and drafting assistant engineered strictly for practicing advocates enrolled with State Bar Councils in India. The application does not solicit clients, publish advocate contact listings to the public, or facilitate client acquisition.

---

## 2. Categories of Data Collected & Processed

| Category | Data Elements | Lawful Basis & Purpose | Storage / Retention |
|---|---|---|---|
| **Advocate Identity** | Name, Bar Council Enrollment Number, State Bar Council, Email | Sections 5 & 6 DPDP Act; Advocates Act Sec 30 statutory verification | Retained until self-service account erasure under Section 8(7) DPDP. |
| **Case Docket Metadata** | FIR Number, Police Station, District, Under-Sections, Hearing Dates, Accused Name | Advocate Chamber Practice Management | Encrypted at rest (AES-256) within advocate-isolated Supabase PostgreSQL schema with Row-Level Security. |
| **Voice Dictation** | Audio recordings of court arguments or case facts | Ephemeral Court Intake (Speech-to-Text) | **Ephemeral Processing:** Transcribed via API and immediately discarded from memory. Never used for public AI training. |
| **Judicial Documents** | Certified judgment PDFs, FIR copies | OCR & Precedent Grounding (Rule 1 & Rule 3 zero-hallucination) | Encrypted within advocate's private chamber vault. |
| **Financial & Subscriptions** | Google Play Purchase Tokens, Razorpay Order IDs | Section 6 DPDP Act (Subscription activation & 18% GST invoice compliance) | Securely hashed; no raw credit card or net banking PINs are ever collected or stored by Pratidnya. |

---

## 3. Advocates Act Sec 126 Professional Privilege & DPDP Sec 8 Compliance
1. **No Third-Party AI Model Training:** Under our enterprise configuration (`GEMINI_PAID_TIER=true`), client case facts, accused names, and legal notes are never retained or used by Google Gemini or third-party providers to train foundational models.
2. **Right to Erasure (Sec 8(7)):** Advocates retain absolute ownership of all docket entries. Tapping "केस हटाएं" triggers a cryptographic hard delete across all databases and local device caches.
3. **Immutable Consent Audit Logs:** Every grant or withdrawal of statutory consent is recorded in `dpdp_audit_logs` with UTC timestamps and device fingerprints for Bar Council regulatory review.

---

## 4. Google Play Store Data Safety Disclosures
- **Encryption in Transit:** All traffic is strictly transmitted using TLS 1.3 cryptographic transport security.
- **Data Deletion:** Self-service deletion is accessible at any time within the Compliance & Privacy Audit screen.
- **Children's Privacy:** This enterprise legal application is designed solely for enrolled advocates aged 18 and older.

---

## 5. Contact & Data Protection Officer (DPO)
For inquiries, statutory access requests, or consent revocation under the DPDP Act 2023:
- **Data Protection Officer (DPO):** Legal Compliance Cell, Asiverticals
- **Email:** dpo@asiverticals.me / compliance@asiverticals.me
- **Office:** Asiverticals Legal Tech, Gomti Nagar, Lucknow, Uttar Pradesh 226010, India
