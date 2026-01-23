# PetWell - Pet Healthcare Management App

## 📝 Update Log

| Date | Location | Description |
|------|----------|-------------|
| 2026-01-23 | `InsuranceLandingView.swift` | Implemented sticky mini header with scroll-away animation. Added frosted glass effect and "For Me" recommendation button placeholder. |
| 2026-01-23 | `PetDetailView.swift`<br>`Views/Social/` | Added Share Pet Profile feature with time-limited access. Created `SocialSearchView.swift` for future friend/places search. |
| 2026-01-22 | **System-wide** | Fully localized app to English & Traditional Chinese. Removed Simplified Chinese. |
| 2026-01-22 | `PetWellApp.swift`<br>`RecordsView.swift`| Implemented `LanguageManager` and added Language Toggle in Profile. |
| 2026-01-22 | `InsuranceService.swift`<br>`insurance_list_test.sql` | Corrected insurance product data (OneDegree, MSIG, Zurich, AIA) with verified real-world names and costs. |

## Project Overview
PetWell is a comprehensive iOS application designed to help pet owners manage their furry friends' healthcare needs. The app integrates insurance comparison, medical records management, a shopping experience for health products, and a community blog for sharing pet stories.

**✨ NEW: App is now fully localized in English and Traditional Chinese (繁體中文).**

## Status Report (Frontend)

### 1. Blog (Home Tab) <mark> name pending modification</mark>
*   **Status:** ✅ Implemented (RedNote / Xiaohongshu Style) | **✅ Localized**
*   **Description:** The main entry point of the app. It features a masonry grid layout for browsing community posts.
*   **Key Features:**
    *   **Feed:** "Explore" tab with staggered grid layout.
    *   **Create Post:** Custom "Add Post" sheet with title, content, image picker placeholder, and tag options (#Topic, @User, Poll, Location).
    *   **Styling:** Follows a modern social media aesthetic.
    *   <mark>**New Feature:** consider adding the nearby facilities... </mark>

### 2. Shop <mark> added implementation</mark>
*   **Status:** 🚧 MVP Stub | **✅ Localized**
*   **Description:** Placeholder for the e-commerce section focus on pet health products.
*   **Implementation:** Initial launch with dropshipping pattern for pet supplies (gear), expanding to pet food later. Food items will include ingredient details to match pet profiles for personalized recommendations.

    ## Pet Gear Examples
    | English | Traditional Chinese | Description |
    |---------|-------------------|-------------|
    | Leash | 狗帶 / 貓帶 | Durable nylon or leather for walking |
    | Collar | 項圈 | Adjustable with tag slot |
    | Carrier | 寵物籠 / 背包 | Airline certified for travel |
    | Bowl | 食盆 | Stainless steel anti-tip design |
    | Toys | 玩具 | Durable rubber balls or plush squeakers |

### 3. Medical
*   **Status:** 🚧 MVP Stub | **✅ Localized**
*   **Description:** The main function is about the medical consultation assistant. Placeholder for managing vaccinations, clinic visits, and booking appointments. <mark>consider the comet, this is the large language model but at the same time, it is the browser, consider using talk style to manage the booking, medical services... </mark>

### 4. Insurance
*   **Status:** ⚠️ Basic UI Done | **✅ Fully Localized**
*   **Description:** A dedicated section to educate users on insurance value and compare plans.
*   **Key Features:**
    *   **Landing View:** Displays "The Real Cost of Pet Parenthood" with lifetime cost estimates for dogs and cats. Highlights medical risks.
    *   **Sticky Mini Header:** Scroll-away hero header with Apple-style frosted glass mini header that appears when scrolling. Includes "For Me" recommendation button (placeholder for AI-powered insurance matching).
    *   **Compare View:** Side-by-side comparison interface (e.g., comparing Bowtie vs OneDegree). Currently displays Annual Limits and coverage properties.
    *   **Localization:** Product names, coverage details, and UI elements switch automatically between English and Traditional Chinese.

### 5. Profile (Formerly Records)
*   **Status:** ✅ Basic Implementation | **✨ New Language Switcher**
*   **Description:** User and pet profile management. Access to "Records" and other personal settings.
*   **Key Features:**
    *   **Language Settings:** Toggle between English (en) and Traditional Chinese (zh-HK).
    *   **Share Pet Profile:** Share button in toolbar allows time-limited profile sharing with friends.

---

### 7. Social Features (Planned)

*   **Status:** 🔮 Future Development
*   **Description:** Social networking features for pet owners.
*   **Planned Features:**
    *   **Find Friends & Places:** Search functionality for friends, pet shops, and veterinary clinics. *(UI designed in `SocialSearchView.swift`, not yet integrated into main navigation)*
    *   **Friend System:** Add friends, manage friend list, share pet profiles.
    *   **Location-based Discovery:** Find nearby pet services and connect with local pet owners.

---

### 8. Logs

#### 2026-01-21 - Medical Module & Backend Integration
*   **Backend Architecture**:
    *   Established a local Python `http.server` running on port 8000.
    *   Created `vaccines.json` to serve dynamic data for the application.
    *   Implemented `VaccineService.swift` to handle async data fetching from localhost.
*   **Medical / Vaccine Module UI**:
    *   **Main Dashboard (`VaccineView`)**:
        *   Redesigned for a "High-End" Apple-style aesthetic.
        *   Implemented sticky "Pet Health Center" header with search.
        *   Switched to horizontal scrolling rails for "Services", "Dog Vaccination", and "Cat Vaccination".
        *   **Standardized Card Design**: Created a polished `VaccineCard` component with fixed dimensions (200x220), ensuring perfect alignment between image and content areas. Added "Book" action buttons and "Core/Mandatory" badges.
    *   **Detail View (`VaccineDetailView`)**:
        *   Designed an immersive detail page with gradient headers and dynamic "Puppy/Kitten" logic.
        *   Added "Vaccination Schedule" timeline visualization.
        *   Integrated a "Book Appointment" button that flows naturally with the content.
*   **Asset Management**:
    *   Fixed image loading issues by restructuring `Assets.xcassets` (converting loose PNGs to `.imageset` folders).
    *   Verified "Rabies" image display.

## 📝 Roadmap & TODOs

### Completed (Jan 2026)
- [x] **Localization:** Implemented `LanguageManager` and translated all key views to Traditional Chinese. Removed Simplified Chinese.
- [x] **Insurance Data:** Verified real market product names (OneDegree, MSIG, etc.).

### Immediate Priorities (Medical Module)
- [ ] **Data Population**: Complete the `vaccines.json` with accurate data for all vaccine types (DHPP, Bordetella, FVRCP, etc.).
- [ ] **Asset Completion**: Create `.imageset` folders for the remaining vaccine images in Xcode so they display correctly.
- [ ] **Booking Flow**: Implement the actual logic or a form for the "Book Appointment" button.

### Immediate Priorities (Insurance Module)
We are currently focusing on refining the Insurance features to ensure the comparison tool is accurate and user-friendly.

- [ ] **Refine Insurance Landing Page UI:** Polish the current cost analysis cards and benefit sections to be more engaging.
- [ ] **Refine Insurance Compare Page UI:** Improve the side-by-side layout and visual hierarchy for comparing complex plan details.
- [ ] **Finalize Insurance Database:** 
    *   The SQL database schema needs to be finalized.
    *   ✅ **Real product names verified:** Updated OneDegree, MSIG, Zurich, and AIA product names to match official market offerings (Jan 2026).
    *   Real data for insurance plans (Coverage limits, copays, premiums) needs to be populated to replace the current "Property 1 / Property 2" placeholders in the Compare View.

### Future Work
- [ ] **Backend Integration:** Connect Blog posts to a persistent backend.
- [ ] **Shop & Medical:** Develop full UI and logic for these sections.
- [ ] **Global UI:** Ensure consistent use of the primary App Blue color across all new views.

## 🛠️ Database Management Workflow

### How to update Insurance Data from Excel

To update the app's database with new market research (Excel/CSV):

1.  **Upload the File:** Place the raw Excel file (e.g., `market_research.xlsx`) into the `Data/` folder.
2.  **Generate Relational Schema:** Use the AI assistant to parse and normalize the data.

**Prompt for AI:**
> "I have uploaded a new Excel file to `Data/market_research.xlsx` containing raw insurance product information.
> 
> Please perform the following:
> 1. Analyze the columns to understand the hierarchy (Provider -> Product -> Plan -> Coverage Details).
> 2. Design a normalized SQLite schema (Relational Algebra) to store this effectively.
> 3. Generate a SQL seed script (INSERT statements) to populate the new tables with the data from the Excel file.
> 4. Update the SQL files and `Services/InsuranceService.swift` to reflect these changes."
