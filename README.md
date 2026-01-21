# PetWell - Pet Healthcare Management App

## Project Overview
PetWell is a comprehensive iOS application designed to help pet owners manage their furry friends' healthcare needs. The app integrates insurance comparison, medical records management, a shopping experience for health products, and a community blog for sharing pet stories.

## Status Report (Frontend)

### 1. Blog (Home Tab)
*   **Status:** ✅ Implemented (RedNote / Xiaohongshu Style)
*   **Description:** The main entry point of the app. It features a masonry grid layout for browsing community posts.
*   **Key Features:**
    *   **Feed:** "Explore" tab with staggered grid layout.
    *   **Create Post:** Custom "Add Post" sheet with title, content, image picker placeholder, and tag options (#Topic, @User, Poll, Location).
    *   **Styling:** Follows a modern social media aesthetic.

### 2. Shop
*   **Status:** 🚧 MVP Stub
*   **Description:** Placeholder for the e-commerce section focus on pet health products.

### 3. Medical
*   **Status:** 🚧 MVP Stub
*   **Description:** Placeholder for managing vaccinations, clinic visits, and booking appointments.

### 4. Insurance
*   **Status:** ⚠️ Basic UI Done (Needs Refinement)
*   **Description:** A dedicated section to educate users on insurance value and compare plans.
*   **Key Features:**
    *   **Landing View:** Displays "The Real Cost of Pet Parenthood" with lifetime cost estimates for dogs and cats. Highlights medical risks.
    *   **Compare View:** Side-by-side comparison interface (e.g., comparing Bowtie vs OneDegree). Currently displays Annual Limits and coverage properties (Surgery, Hospitalization, etc.).

### 5. Profile (Formerly Records)
*   **Status:** ✅ Basic Implementation
*   **Description:** User and pet profile management. Access to "Records" and other personal settings.

---

### 6. Logs

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
    *   Real data for insurance plans (Coverage limits, copays, premiums) needs to be populated to replace the current "Property 1 / Property 2" placeholders in the Compare View.

### Future Work
- [ ] **Backend Integration:** Connect Blog posts to a persistent backend.
- [ ] **Shop & Medical:** Develop full UI and logic for these sections.
- [ ] **Global UI:** Ensure consistent use of the primary App Blue color across all new views.
