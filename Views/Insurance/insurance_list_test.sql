-- ============================================================================
-- PetWell Insurance Database Schema
-- For: Pet insurance comparison & coverage analysis (HK market)
-- ============================================================================

-- ============================================================================
-- TABLE 1: insurance_companies
-- Stores insurance providers/brands in Hong Kong market
-- ============================================================================
CREATE TABLE IF NOT EXISTS insurance_companies (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  name_en         TEXT NOT NULL,
  name_zh         TEXT,
  brand_type      TEXT NOT NULL,     -- 'insurer', 'bank_partner', 'platform'
  website         TEXT,
  contact_phone   TEXT,
  notes           TEXT               -- free text about brand / reputation
);

-- ============================================================================
-- TABLE 2: insurance_products
-- Each product line under a company (e.g. "Pawfect Care", "Happy Tails")
-- ============================================================================
CREATE TABLE IF NOT EXISTS insurance_products (
  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
  company_id              INTEGER NOT NULL,
  name_en                 TEXT NOT NULL,
  name_zh                 TEXT,
  description             TEXT,      -- short marketing description
  target_segment          TEXT,      -- e.g. 'dog', 'cat', 'both'
  is_active               INTEGER NOT NULL DEFAULT 1,  -- 0/1
  notes                   TEXT,
  FOREIGN KEY (company_id) REFERENCES insurance_companies(id)
);

-- Index for joins
CREATE INDEX IF NOT EXISTS idx_products_company
  ON insurance_products(company_id);

-- ============================================================================
-- TABLE 3: product_coverage_profiles
-- Core coverage vs real vet costs dimensions
-- One row per product capturing important coverage details
-- ============================================================================
CREATE TABLE IF NOT EXISTS product_coverage_profiles (
  id                          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id                  INTEGER NOT NULL UNIQUE,

  -- Coverage vs real vet costs
  typical_surgery_covered     INTEGER,      -- 0/1: big surgeries generally covered
  chronic_illness_supported   INTEGER,      -- 0/1: can keep claiming chronic illness
  coverage_vs_cost_notes      TEXT,         -- description of how well it matches real bills

  -- Limits / sub-limits
  annual_limit_amount         INTEGER,      -- e.g. 60000, 100000 (in HKD)
  has_sub_limits              INTEGER,      -- 0/1
  sub_limit_structure         TEXT,         -- e.g. "per-incident 10k; hospitalization 20k"
  no_sub_limit_marketing_tag  INTEGER,      -- 0/1: explicitly "no sub-limit" plan
  chronic_multi_year_limit    TEXT,         -- notes on multi-year chronic coverage

  -- Exclusions & fine print
  preexisting_excluded        INTEGER,      -- 0/1
  hereditary_disease_policy   TEXT,         -- short text summary
  breed_age_restrictions      TEXT,
  waiting_period_description  TEXT,
  inpatient_surgery_included  INTEGER,      -- 0/1: surgery + hospitalization covered?
  exclusions_notes            TEXT,         -- general highlight of important exclusions

  -- Price vs out-of-pocket
  typical_monthly_premium     INTEGER,      -- store in HKD, for "typical" pet profile
  reimbursement_percent       INTEGER,      -- e.g. 70, 80, 90
  has_deductible              INTEGER,      -- 0/1
  deductible_amount           INTEGER,      -- NULL if none / variable
  copay_percent               INTEGER,      -- owner's share, e.g. 20
  price_value_notes           TEXT,         -- narrative about balance premium vs OOP

  -- Claim experience & brand perception
  online_claim_supported      INTEGER,      -- 0/1
  claim_process_speed_note    TEXT,         -- e.g. "usually 5–7 working days"
  claim_convenience_notes     TEXT,         -- app/portal, documents required, etc.
  brand_reputation_summary    TEXT,         -- short summary of reviews / trust
  review_source_notes         TEXT,         -- where info comes from (reviews, CS, etc.)
  key_pros                    TEXT,         -- bullet points of main advantages
  key_cons                    TEXT,         -- bullet points of main disadvantages

  FOREIGN KEY (product_id) REFERENCES insurance_products(id)
);

-- ============================================================================
-- TABLE 4: insurance_plans
-- Plan levels within a product (Essential / Plus / Premium, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS insurance_plans (
  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id              INTEGER NOT NULL,
  name                    TEXT NOT NULL,    -- 'Essential', 'Plus', 'Premium', etc.
  annual_limit_amount     INTEGER,
  reimbursement_percent   INTEGER,
  has_sub_limits          INTEGER,
  sub_limit_structure     TEXT,
  typical_monthly_premium INTEGER,         -- in HKD
  notes                   TEXT,
  FOREIGN KEY (product_id) REFERENCES insurance_products(id)
);

-- Index for joins
CREATE INDEX IF NOT EXISTS idx_plans_product
  ON insurance_plans(product_id);

-- ============================================================================
-- SAMPLE DATA: Hong Kong Pet Insurance Providers
-- ============================================================================

-- Insert companies
INSERT OR IGNORE INTO insurance_companies (id, name_en, name_zh, brand_type, website, contact_phone, notes)
VALUES
  (1, 'OneDegree', '一度保', 'insurer', 'https://www.onedegree.hk', '+852 2588 3388', 'Leading HK pet insurer, online-first, strong mobile experience'),
  (2, 'MSIG', 'MSIG', 'insurer', 'https://www.msig.com.hk', '+852 2891 0898', 'Established Japanese-backed insurer, traditional + digital'),
  (3, 'AIA', 'AIA', 'bank_partner', 'https://www.aia.com.hk', '+852 2881 1000', 'Major regional insurer, various partnerships'),
  (4, 'Zurich', 'Zurich', 'insurer', 'https://www.zurich.com.hk', '+852 2978 8000', 'Global insurer with HK presence, comprehensive coverage');

-- Insert products for OneDegree
INSERT OR IGNORE INTO insurance_products (id, company_id, name_en, name_zh, description, target_segment, is_active, notes)
VALUES
  (1, 1, 'Pawfect Care', '完美呵護', 'Comprehensive pet insurance with no sub-limits', 'both', 1, 'OneDegree flagship product'),
  (2, 1, 'Pawfect Care (Entry)', '完美呵護 (入門)', 'Budget-friendly basic coverage', 'both', 1, 'Entry-level product for cost-conscious owners');

-- Insert products for MSIG
INSERT OR IGNORE INTO insurance_products (id, company_id, name_en, name_zh, description, target_segment, is_active, notes)
VALUES
  (3, 2, 'Ulti-mate Pet Insurance (Dog)', '毛價保 (狗)', 'Multi-tier coverage with annual limits', 'dog', 1, 'Popular MSIG dog insurance'),
  (4, 2, 'Ulti-mate Pet Insurance (Cat)', '毛價保 (貓)', 'Specialized cat coverage', 'cat', 1, 'MSIG cat-specific insurance');

-- Insert products for AIA
INSERT OR IGNORE INTO insurance_products (id, company_id, name_en, name_zh, description, target_segment, is_active, notes)
VALUES
  (5, 3, 'AIA Pet Insurance', 'AIA 寵物保險', 'Bundled with health screening', 'both', 1, 'AIA partnership product');

-- Insert products for Zurich
INSERT OR IGNORE INTO insurance_products (id, company_id, name_en, name_zh, description, target_segment, is_active, notes)
VALUES
  (6, 4, 'Pamper U', '毛孩 寵愛', 'Comprehensive accident & illness coverage', 'both', 1, 'Zurich premium offering');

-- ============================================================================
-- SAMPLE DATA: Product Coverage Profiles
-- ============================================================================

-- OneDegree - Pawfect Care
INSERT OR IGNORE INTO product_coverage_profiles (
  product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes,
  annual_limit_amount, has_sub_limits, sub_limit_structure, no_sub_limit_marketing_tag,
  chronic_multi_year_limit, preexisting_excluded, hereditary_disease_policy,
  breed_age_restrictions, waiting_period_description, inpatient_surgery_included,
  exclusions_notes, typical_monthly_premium, reimbursement_percent, has_deductible,
  deductible_amount, copay_percent, price_value_notes, online_claim_supported,
  claim_process_speed_note, claim_convenience_notes, brand_reputation_summary,
  review_source_notes, key_pros, key_cons
) VALUES (
  1, 1, 1, 'Covers most surgical procedures up to annual limit; claims reimburse 80-90% of vet invoices',
  100000, 0, NULL, 1,
  'Supports ongoing chronic claims across multiple years',
  1, 'Hereditary conditions covered if no prior symptoms within 180 days of policy start',
  'Dogs & cats aged 8 weeks to 10 years old', 'Accident: immediate; Illness: 14 days',
  1, 'Excludes routine preventative care, breeding, behavioral issues',
  196, 80, 1, 3000, 0, 'Excellent value for comprehensive coverage; no sub-limits',
  1, '5–7 working days', 'Mobile app claims with photo upload; most claims settled without vet paperwork',
  'High satisfaction; praised for digital experience and no sub-limits',
  'Google Reviews 4.7/5, Facebook community feedback',
  '- No sub-limits\n- High reimbursement rate\n- Digital claims',
  '- Deductible applies per condition'
);

-- OneDegree - Happy Paws
INSERT OR IGNORE INTO product_coverage_profiles (
  product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes,
  annual_limit_amount, has_sub_limits, sub_limit_structure, no_sub_limit_marketing_tag,
  chronic_multi_year_limit, preexisting_excluded, hereditary_disease_policy,
  breed_age_restrictions, waiting_period_description, inpatient_surgery_included,
  exclusions_notes, typical_monthly_premium, reimbursement_percent, has_deductible,
  deductible_amount, copay_percent, price_value_notes, online_claim_supported,
  claim_process_speed_note, claim_convenience_notes, brand_reputation_summary,
  review_source_notes, key_pros, key_cons
) VALUES (
  2, 1, 0, 'Covers common surgeries; limited chronic illness support',
  60000, 1, 'Per-incident: HKD 15,000; Emergency surgery: HKD 20,000',
  0, 'Limited multi-year coverage for chronic conditions',
  1, 'Hereditary conditions excluded unless onset after 180-day waiting period',
  'Dogs & cats aged 8 weeks to 8 years old', 'Accident: 3 days; Illness: 14 days',
  1, 'No routine care, behavioral, breeding; limited chronic coverage',
  128, 70, 1, 2000, 0, 'Budget option with lower premiums; acceptable for young, healthy pets',
  1, '7–10 working days', 'Online app available; straightforward claims process',
  'Good for budget-conscious owners; basic but reliable coverage',
  'Google Reviews 4.5/5, Pet owner forums',
  '- Low monthly premium\n- Digital claims',
  '- Has sub-limits\n- Lower reimbursement rate'
);

-- MSIG - Pet Care Plus
INSERT OR IGNORE INTO product_coverage_profiles (
  product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes,
  annual_limit_amount, has_sub_limits, sub_limit_structure, no_sub_limit_marketing_tag,
  chronic_multi_year_limit, preexisting_excluded, hereditary_disease_policy,
  breed_age_restrictions, waiting_period_description, inpatient_surgery_included,
  exclusions_notes, typical_monthly_premium, reimbursement_percent, has_deductible,
  deductible_amount, copay_percent, price_value_notes, online_claim_supported,
  claim_process_speed_note, claim_convenience_notes, brand_reputation_summary,
  review_source_notes, key_pros, key_cons
) VALUES (
  3, 1, 1, 'Strong surgical coverage; chronic claims up to multi-year limits',
  80000, 1, 'Per-incident: HKD 12,000; Hospitalization: HKD 25,000',
  0, 'Multi-year chronic claims supported',
  1, 'Certain hereditary conditions covered; age/breed-specific exclusions apply',
  'Dogs aged 2 months to 9 years old', 'Accident: 48 hours; Illness: 10 days',
  1, 'No routine care; breed-specific exclusions for high-risk breeds',
  178, 75, 1, 2500, 0, 'Traditional insurer; good balance of coverage and price',
  0, '10–14 working days typical', 'Requires paper claims or online portal; vet referral often needed',
  'Established brand; moderate satisfaction with claims process',
  'MSIG official website, Pet owner surveys',
  '- Strong brand reputation\n- Good chronic support',
  '- Paper claims process\n- Sub-limits apply'
);

-- MSIG - Feline Friend
INSERT OR IGNORE INTO product_coverage_profiles (
  product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes,
  annual_limit_amount, has_sub_limits, sub_limit_structure, no_sub_limit_marketing_tag,
  chronic_multi_year_limit, preexisting_excluded, hereditary_disease_policy,
  breed_age_restrictions, waiting_period_description, inpatient_surgery_included,
  exclusions_notes, typical_monthly_premium, reimbursement_percent, has_deductible,
  deductible_amount, copay_percent, price_value_notes, online_claim_supported,
  claim_process_speed_note, claim_convenience_notes, brand_reputation_summary,
  review_source_notes, key_pros, key_cons
) VALUES (
  4, 1, 1, 'Specifically designed for cats; strong chronic illness support',
  70000, 0, NULL, 1,
  'Supports chronic conditions across policy years',
  1, 'Feline-specific hereditary conditions (e.g., hypertrophic cardiomyopathy) reviewed case-by-case',
  'Cats aged 8 weeks to 12 years old', 'Accident: immediate; Illness: 14 days',
  1, 'No routine care, vaccination, behavioral issues',
  218, 85, 0, NULL, 0, 'Premium cat-specific coverage; excellent for chronic feline conditions',
  1, '7–10 working days', 'Digital portal; MSIG understands cat-specific medical needs',
  'Highly rated among cat owners; specialized coverage appreciated',
  'Cat owner groups, veterinary recommendations',
  '- No deductible\n- Specialized for cats\n- No sub-limits',
  '- Age limit for enrollment'
);

-- AIA - Pet Plus
INSERT OR IGNORE INTO product_coverage_profiles (
  product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes,
  annual_limit_amount, has_sub_limits, sub_limit_structure, no_sub_limit_marketing_tag,
  chronic_multi_year_limit, preexisting_excluded, hereditary_disease_policy,
  breed_age_restrictions, waiting_period_description, inpatient_surgery_included,
  exclusions_notes, typical_monthly_premium, reimbursement_percent, has_deductible,
  deductible_amount, copay_percent, price_value_notes, online_claim_supported,
  claim_process_speed_note, claim_convenience_notes, brand_reputation_summary,
  review_source_notes, key_pros, key_cons
) VALUES (
  5, 1, 0, 'Good surgical coverage; includes annual health screening benefit',
  75000, 1, 'Per-incident: HKD 10,000; Surgical: HKD 30,000',
  0, 'Limited multi-year support',
  1, 'Standard hereditary exclusions; breed-specific limitations',
  'Dogs & cats aged 1 to 10 years old', 'Accident: 48 hours; Illness: 14 days',
  1, 'Routine care, behavior training excluded; limited chronic support',
  165, 72, 1, 3000, 0, 'Partnership benefit: includes annual health screening; good for preventive care',
  1, '10–15 working days', 'AIA web portal; partnership with major vets for pre-authorization',
  'Moderate satisfaction; screening benefit adds value',
  'AIA marketing materials, Partner vet feedback',
  '- Annual health screening included\n- Trusted brand',
  '- Lower reimbursement rate\n- Sub-limits apply\n- Limited chronic support'
);

-- Zurich - PetShield
INSERT OR IGNORE INTO product_coverage_profiles (
  product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes,
  annual_limit_amount, has_sub_limits, sub_limit_structure, no_sub_limit_marketing_tag,
  chronic_multi_year_limit, preexisting_excluded, hereditary_disease_policy,
  breed_age_restrictions, waiting_period_description, inpatient_surgery_included,
  exclusions_notes, typical_monthly_premium, reimbursement_percent, has_deductible,
  deductible_amount, copay_percent, price_value_notes, online_claim_supported,
  claim_process_speed_note, claim_convenience_notes, brand_reputation_summary,
  review_source_notes, key_pros, key_cons
) VALUES (
  6, 1, 1, 'Premium coverage for accidents and illnesses; most HK vet bills covered',
  120000, 0, NULL, 1,
  'Comprehensive chronic illness support over multiple years',
  1, 'Hereditary conditions covered (no waiting period exclusion)',
  'Dogs & cats aged 6 weeks to 12 years old', 'Accident: immediate; Illness: 7 days',
  1, 'Routine preventative care and breeding only; everything else covered',
  270, 90, 0, NULL, 0, 'Premium tier; highest coverage percentage and annual limit',
  1, '5–7 working days', 'Zurich global infrastructure; multilingual support',
  'High satisfaction; premium pricing reflects comprehensive coverage',
  'Zurich official website, International review sites',
  '- 90% reimbursement\n- High annual limit\n- No sub-limits',
  '- Higher premium\n- No online claims portal (Email/Post)'
);

-- ============================================================================
-- SAMPLE DATA: Plan Levels (for products that offer multiple tiers)
-- ============================================================================

-- Onedegree - Pawfect Care plan levels
INSERT OR IGNORE INTO insurance_plans (
  product_id, name, annual_limit_amount, reimbursement_percent,
  has_sub_limits, sub_limit_structure, typical_monthly_premium, notes
) VALUES
  (1, 'Essential', 60000, 80, 0, NULL, 196, 'No sub-limits; good for young pets'),
  (1, 'Plus', 100000, 85, 0, NULL, 270, 'Higher annual limit; better for older/higher-risk pets'),
  (1, 'Premium', 150000, 90, 0, NULL, 380, 'Maximum coverage; best for comprehensive protection');

-- MSIG - Ulti-mate Pet Insurance plan levels
INSERT OR IGNORE INTO insurance_plans (
  product_id, name, annual_limit_amount, reimbursement_percent,
  has_sub_limits, sub_limit_structure, typical_monthly_premium, notes
) VALUES
  (3, 'Basic', 50000, 70, 1, 'Per-incident: HKD 8,000', 145, 'Entry level with sub-limits'),
  (3, 'Standard', 80000, 75, 1, 'Per-incident: HKD 12,000; Hospitalization: HKD 25,000', 178, 'Mid-tier most popular'),
  (3, 'Premium', 120000, 85, 0, NULL, 250, 'No sub-limits; comprehensive');

-- Zurich - Pamper U plan levels
INSERT OR IGNORE INTO insurance_plans (
  product_id, name, annual_limit_amount, reimbursement_percent,
  has_sub_limits, sub_limit_structure, typical_monthly_premium, notes
) VALUES
  (6, 'Standard', 100000, 85, 0, NULL, 240, 'Solid all-around coverage'),
  (6, 'Premium Plus', 150000, 90, 0, NULL, 320, 'Maximum limits and reimbursement');

-- ============================================================================
-- USEFUL QUERIES
-- ============================================================================

-- Query 1: Compare all active products with key coverage details
SELECT
  c.name_en as company,
  p.name_en as product,
  pcp.annual_limit_amount as annual_limit_hkd,
  pcp.typical_monthly_premium as monthly_premium_hkd,
  pcp.reimbursement_percent as reimbursement_pct,
  pcp.has_sub_limits,
  pcp.no_sub_limit_marketing_tag as no_sub_limits,
  pcp.chronic_illness_supported,
  pcp.online_claim_supported
FROM insurance_products p
JOIN insurance_companies c ON p.company_id = c.id
LEFT JOIN product_coverage_profiles pcp ON p.id = pcp.product_id
WHERE p.is_active = 1
ORDER BY pcp.typical_monthly_premium ASC;

-- Query 2: Find products with no sub-limits and good chronic illness support
SELECT
  c.name_en as company,
  p.name_en as product,
  pcp.annual_limit_amount,
  pcp.typical_monthly_premium,
  pcp.coverage_vs_cost_notes
FROM insurance_products p
JOIN insurance_companies c ON p.company_id = c.id
LEFT JOIN product_coverage_profiles pcp ON p.id = pcp.product_id
WHERE p.is_active = 1
  AND pcp.no_sub_limit_marketing_tag = 1
  AND pcp.chronic_illness_supported = 1
ORDER BY pcp.typical_monthly_premium ASC;

-- Query 3: Compare plan levels for a specific product
SELECT
  p.name as plan_level,
  p.annual_limit_amount,
  p.reimbursement_percent,
  p.typical_monthly_premium,
  p.has_sub_limits,
  p.notes
FROM insurance_plans p
WHERE p.product_id = 1  -- Replace with product_id of interest
ORDER BY p.typical_monthly_premium ASC;

-- ============================================================================
-- END OF DATABASE SCHEMA
-- ============================================================================
