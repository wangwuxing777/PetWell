//
//  InsuranceService.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/14.
//

import Foundation
import SQLite3

// MARK: - Service

/// Service to load and query insurance data from SQLite database
final class InsuranceService {
	static let shared = InsuranceService()

	private var db: OpaquePointer?

	init() {
		openDatabase()
	}

	deinit {
		closeDatabase()
	}

	private func openDatabase() {
		// For now, use in-memory DB to test. Later, bundle the SQL as a resource.
		if sqlite3_open(":memory:", &db) == SQLITE_OK {
			initializeDatabase()
		}
	}

	private func closeDatabase() {
		if let db = db {
			sqlite3_close(db)
		}
	}

	// MARK: - Initialize Database (Create tables + load sample data from bundled SQL)

	private func initializeDatabase() {
		let sql = """
		-- ============================================================================
		-- TABLE 1: insurance_companies
		-- ============================================================================
		CREATE TABLE IF NOT EXISTS insurance_companies (
		  id              INTEGER PRIMARY KEY AUTOINCREMENT,
		  name_en         TEXT NOT NULL,
		  name_zh         TEXT,
		  brand_type      TEXT NOT NULL,
		  website         TEXT,
		  contact_phone   TEXT,
		  logo_url        TEXT,
		  logo_base64     TEXT,
		  notes           TEXT
		);

		-- ============================================================================
		-- TABLE 2: insurance_products
		-- ============================================================================
		CREATE TABLE IF NOT EXISTS insurance_products (
		  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
		  company_id              INTEGER NOT NULL,
		  name_en                 TEXT NOT NULL,
		  name_zh                 TEXT,
		  description             TEXT,
		  target_segment          TEXT,
		  is_active               INTEGER NOT NULL DEFAULT 1,
		  notes                   TEXT,
		  FOREIGN KEY (company_id) REFERENCES insurance_companies(id)
		);

		CREATE INDEX IF NOT EXISTS idx_products_company
		  ON insurance_products(company_id);

		-- ============================================================================
		-- TABLE 3: product_coverage_profiles
		-- ============================================================================
		CREATE TABLE IF NOT EXISTS product_coverage_profiles (
		  id                          INTEGER PRIMARY KEY AUTOINCREMENT,
		  product_id                  INTEGER NOT NULL UNIQUE,
		  typical_surgery_covered     INTEGER,
		  chronic_illness_supported   INTEGER,
		  coverage_vs_cost_notes      TEXT,
		  annual_limit_amount         INTEGER,
		  has_sub_limits              INTEGER,
		  sub_limit_structure         TEXT,
		  no_sub_limit_marketing_tag  INTEGER,
		  chronic_multi_year_limit    TEXT,
		  preexisting_excluded        INTEGER,
		  hereditary_disease_policy   TEXT,
		  breed_age_restrictions      TEXT,
		  waiting_period_description  TEXT,
		  inpatient_surgery_included  INTEGER,
		  exclusions_notes            TEXT,
		  typical_monthly_premium     INTEGER,
		  reimbursement_percent       INTEGER,
		  has_deductible              INTEGER,
		  deductible_amount           INTEGER,
		  copay_percent               INTEGER,
		  price_value_notes           TEXT,
		  online_claim_supported      INTEGER,
		  claim_process_speed_note    TEXT,
		  claim_convenience_notes     TEXT,
		  brand_reputation_summary    TEXT,
		  review_source_notes         TEXT,
		  FOREIGN KEY (product_id) REFERENCES insurance_products(id)
		);

		-- ============================================================================
		-- TABLE 4: insurance_plans
		-- ============================================================================
		CREATE TABLE IF NOT EXISTS insurance_plans (
		  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
		  product_id              INTEGER NOT NULL,
		  name                    TEXT NOT NULL,
		  annual_limit_amount     INTEGER,
		  reimbursement_percent   INTEGER,
		  has_sub_limits          INTEGER,
		  sub_limit_structure     TEXT,
		  typical_monthly_premium INTEGER,
		  notes                   TEXT,
		  FOREIGN KEY (product_id) REFERENCES insurance_products(id)
		);

		CREATE INDEX IF NOT EXISTS idx_plans_product
		  ON insurance_plans(product_id);
		"""

		var errorMessage: UnsafeMutablePointer<CChar>?
		if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
			if let errorMessage = errorMessage {
				let message = String(cString: errorMessage)
				print("Error creating tables: \(message)")
				sqlite3_free(errorMessage)
			}
		}

		// Load sample data
		loadSampleData()
	}

	private func loadSampleData() {
		let inserts = """
		INSERT OR IGNORE INTO insurance_companies (id, name_en, name_zh, brand_type, website, contact_phone, logo_url, logo_base64, notes)
		VALUES
		  (1, 'OneDegree', '一度保', 'insurer', 'https://www.onedegree.hk', '+852 2588 3388', NULL, NULL, 'Leading HK pet insurer, online-first, strong mobile experience'),
		  (2, 'MSIG', 'MSIG', 'insurer', 'https://www.msig.com.hk', '+852 2891 0898', NULL, NULL, 'Established Japanese-backed insurer, traditional + digital'),
		  (3, 'AIA', 'AIA', 'bank_partner', 'https://www.aia.com.hk', '+852 2881 1000', NULL, NULL, 'Major regional insurer, various partnerships'),
		  (4, 'Zurich', 'Zurich', 'insurer', 'https://www.zurich.com.hk', '+852 2978 8000', NULL, NULL, 'Global insurer with HK presence, comprehensive coverage');

		INSERT OR IGNORE INTO insurance_products (id, company_id, name_en, name_zh, description, target_segment, is_active, notes)
		VALUES
		  (1, 1, 'Pawfect Care', '完美呵护', 'Comprehensive pet insurance with no sub-limits', 'both', 1, 'OneDegree flagship product'),
		  (2, 1, 'Happy Paws', '快乐爪印', 'Budget-friendly basic coverage', 'both', 1, 'Entry-level product for cost-conscious owners'),
		  (3, 2, 'Pet Care Plus', '宠物保险+', 'Multi-tier coverage with annual limits', 'dog', 1, 'Popular MSIG dog insurance'),
		  (4, 2, 'Feline Friend', '猫咪好友', 'Specialized cat coverage', 'cat', 1, 'MSIG cat-specific insurance'),
		  (5, 3, 'Pet Plus', '宠物加', 'Bundled with health screening', 'both', 1, 'AIA partnership product'),
		  (6, 4, 'PetShield', '宠物护盾', 'Comprehensive accident & illness coverage', 'both', 1, 'Zurich premium offering');

		INSERT OR IGNORE INTO product_coverage_profiles (product_id, typical_surgery_covered, chronic_illness_supported, coverage_vs_cost_notes, annual_limit_amount, has_sub_limits, no_sub_limit_marketing_tag, preexisting_excluded, typical_monthly_premium, reimbursement_percent, has_deductible, deductible_amount, copay_percent, online_claim_supported, claim_process_speed_note, brand_reputation_summary)
		VALUES
		  (1, 1, 1, 'Covers most surgical procedures up to annual limit', 100000, 0, 1, 1, 196, 80, 1, 3000, 0, 1, '5–7 working days', 'High satisfaction; praised for digital experience and no sub-limits'),
		  (2, 1, 0, 'Covers common surgeries; limited chronic illness support', 60000, 1, 0, 1, 128, 70, 1, 2000, 0, 1, '7–10 working days', 'Good for budget-conscious owners; basic but reliable coverage'),
		  (3, 1, 1, 'Strong surgical coverage; chronic claims up to multi-year limits', 80000, 1, 0, 1, 178, 75, 1, 2500, 0, 0, '10–14 working days typical', 'Established brand; moderate satisfaction with claims process'),
		  (4, 1, 1, 'Specifically designed for cats; strong chronic illness support', 70000, 0, 1, 1, 218, 85, 0, NULL, 0, 1, '7–10 working days', 'Highly rated among cat owners; specialized coverage appreciated'),
		  (5, 1, 0, 'Good surgical coverage; includes annual health screening benefit', 75000, 1, 0, 1, 165, 72, 1, 3000, 0, 1, '10–15 working days', 'Moderate satisfaction; screening benefit adds value'),
		  (6, 1, 1, 'Premium coverage for accidents and illnesses', 120000, 0, 1, 1, 270, 90, 0, NULL, 0, 1, '5–7 working days', 'High satisfaction; premium pricing reflects comprehensive coverage');

		INSERT OR IGNORE INTO insurance_plans (product_id, name, annual_limit_amount, reimbursement_percent, has_sub_limits, typical_monthly_premium, notes)
		VALUES
		  (1, 'Essential', 60000, 80, 0, 196, 'No sub-limits; good for young pets'),
		  (1, 'Plus', 100000, 85, 0, 270, 'Higher annual limit; better for older/higher-risk pets'),
		  (1, 'Premium', 150000, 90, 0, 380, 'Maximum coverage; best for comprehensive protection'),
		  (3, 'Basic', 50000, 70, 1, 145, 'Entry level with sub-limits'),
		  (3, 'Standard', 80000, 75, 1, 178, 'Mid-tier most popular'),
		  (3, 'Premium', 120000, 85, 0, 250, 'No sub-limits; comprehensive'),
		  (6, 'Standard', 100000, 85, 0, 240, 'Solid all-around coverage'),
		  (6, 'Premium Plus', 150000, 90, 0, 320, 'Maximum limits and reimbursement');
		"""

		var errorMessage: UnsafeMutablePointer<CChar>?
		if sqlite3_exec(db, inserts, nil, nil, &errorMessage) != SQLITE_OK {
			if let errorMessage = errorMessage {
				let message = String(cString: errorMessage)
				print("Error loading sample data: \(message)")
				sqlite3_free(errorMessage)
			}
		}
	}

	// MARK: - Query Methods

	func getAllCompanies() -> [InsuranceCompany] {
		let query = "SELECT * FROM insurance_companies ORDER BY name_en ASC"
		return executeQuery(query) { statement in
			InsuranceCompany(
				id: Int(sqlite3_column_int(statement, 0)),
				nameEn: String(cString: sqlite3_column_text(statement, 1)),
				nameZh: columnString(statement, 2),
				brandType: String(cString: sqlite3_column_text(statement, 3)),
				website: columnString(statement, 4),
				contactPhone: columnString(statement, 5),
				logoUrl: columnString(statement, 6),
				logoBase64: columnString(statement, 7),
				notes: columnString(statement, 8)
			)
		}
	}

	func getProductsByCompany(companyId: Int) -> [InsuranceProduct] {
		let query = "SELECT * FROM insurance_products WHERE company_id = \(companyId) AND is_active = 1 ORDER BY name_en ASC"
		return executeQuery(query) { statement in
			InsuranceProduct(
				id: Int(sqlite3_column_int(statement, 0)),
				companyId: Int(sqlite3_column_int(statement, 1)),
				nameEn: String(cString: sqlite3_column_text(statement, 2)),
				nameZh: columnString(statement, 3),
				description: columnString(statement, 4),
				targetSegment: columnString(statement, 5),
				isActive: Int(sqlite3_column_int(statement, 6)),
				notes: columnString(statement, 7)
			)
		}
	}

	func getCoverageProfile(productId: Int) -> ProductCoverageProfile? {
		let query = "SELECT * FROM product_coverage_profiles WHERE product_id = \(productId)"
		let results = executeQuery(query) { statement in
			ProductCoverageProfile(
				id: Int(sqlite3_column_int(statement, 0)),
				productId: Int(sqlite3_column_int(statement, 1)),
				typicalSurgeryCovered: columnInt(statement, 2),
				chronicIllnessSupported: columnInt(statement, 3),
				coverageVsCostNotes: columnString(statement, 4),
				annualLimitAmount: columnInt(statement, 5),
				hasSubLimits: columnInt(statement, 6),
				subLimitStructure: columnString(statement, 7),
				noSubLimitMarketingTag: columnInt(statement, 8),
				chronicMultiYearLimit: columnString(statement, 9),
				preexistingExcluded: columnInt(statement, 10),
				hereditaryDiseasePolicy: columnString(statement, 11),
				breedAgeRestrictions: columnString(statement, 12),
				waitingPeriodDescription: columnString(statement, 13),
				inpatientSurgeryIncluded: columnInt(statement, 14),
				exclusionsNotes: columnString(statement, 15),
				typicalMonthlyPremium: columnInt(statement, 16),
				reimbursementPercent: columnInt(statement, 17),
				hasDeductible: columnInt(statement, 18),
				deductibleAmount: columnInt(statement, 19),
				copayPercent: columnInt(statement, 20),
				priceValueNotes: columnString(statement, 21),
				onlineClaimSupported: columnInt(statement, 22),
				claimProcessSpeedNote: columnString(statement, 23),
				claimConvenienceNotes: columnString(statement, 24),
				brandReputationSummary: columnString(statement, 25),
				reviewSourceNotes: columnString(statement, 26)
			)
		}
		return results.first
	}

	func getPlansByProduct(productId: Int) -> [InsurancePlan] {
		let query = "SELECT * FROM insurance_plans WHERE product_id = \(productId) ORDER BY typical_monthly_premium ASC"
		return executeQuery(query) { statement in
			InsurancePlan(
				id: Int(sqlite3_column_int(statement, 0)),
				productId: Int(sqlite3_column_int(statement, 1)),
				name: String(cString: sqlite3_column_text(statement, 2)),
				annualLimitAmount: columnInt(statement, 3),
				reimbursementPercent: columnInt(statement, 4),
				hasSubLimits: columnInt(statement, 5),
				subLimitStructure: columnString(statement, 6),
				typicalMonthlyPremium: columnInt(statement, 7),
				notes: columnString(statement, 8)
			)
		}
	}

	// MARK: - Helper Methods

	private func executeQuery<T>(_ query: String, transform: (OpaquePointer) -> T) -> [T] {
		var results: [T] = []
		var statement: OpaquePointer?

		if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
			while sqlite3_step(statement) == SQLITE_ROW {
				results.append(transform(statement!))
			}
		}

		if let statement = statement {
			sqlite3_finalize(statement)
		}

		return results
	}

	private func columnString(_ statement: OpaquePointer, _ index: Int32) -> String? {
		if let cString = sqlite3_column_text(statement, index) {
			return String(cString: cString)
		}
		return nil
	}

	private func columnInt(_ statement: OpaquePointer, _ index: Int32) -> Int? {
		let value = sqlite3_column_int(statement, index)
		return value == 0 && sqlite3_column_type(statement, index) != SQLITE_INTEGER ? nil : Int(value)
	}
}

