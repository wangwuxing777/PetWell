# Findings & Decisions: PetWell iOS 未完善頁面

## 需求分析

### 用戶請求
用戶希望分析 PetWell iOS Application 文件夾，找出那些按鈕點擊後沒有後續頁面，或者是「待開發」的頁面，並為每個頁面的開發做 plan。

### 已識別的未完善頁面

#### 1. Profile 頁面 - 6 個待開發模塊
位置: `Views/Records/RecordsView.swift:124-147`

```
ModuleTile(title: "Booking Record", systemImage: "calendar.badge.clock") {
  PlaceholderView(title: "Booking Record")
}

ModuleTile(title: "Recent Purchase", systemImage: "cart") {
  PlaceholderView(title: "Recent Purchase")
}

ModuleTile(title: "Insurance", systemImage: "shield") {
  PlaceholderView(title: "Insurance")
}

ModuleTile(title: "Activity Tracking", systemImage: "figure.walk") {
  PlaceholderView(title: "Activity Tracking")
}

ModuleTile(title: "Travel Document", systemImage: "doc.text") {
  PlaceholderView(title: "Travel Document")
}

ModuleTile(title: "Pet Care Tips", systemImage: "lightbulb") {
  PlaceholderView(title: "Pet Care Tips")
}
```

**PlaceholderView 定義位置**: RecordsView.swift:385-400
```swift
private struct PlaceholderView: View {
    let title: String
    var body: some View {
        VStack {
            Image(systemName: "hammer.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
```

#### 2. Social Search - 功能未完成
位置: `Views/Social/SocialSearchView.swift`

**問題點**:
- 第 247-252 行: 添加好友按鈕無動作
  ```swift
  Button {
      // TODO: Add friend action
  } label: {
      Image(systemName: "person.badge.plus")
          .foregroundStyle(.blue)
  }
  ```

- 第 254-259 行: 商店/診所詳情按鈕無動作
  ```swift
  Button {
      // TODO: View details action
  } label: {
      Image(systemName: "arrow.right.circle")
          .foregroundStyle(.secondary)
  }
  ```

- 第 33-50 行: 搜尋結果使用 Mock Data，非真實 API

#### 3. Share Pet Profile - 未完成
位置: `Views/Social/SharePetProfileView.swift:160`
```swift
// TODO: Implement actual sharing logic with backend
```

#### 4. Blog Post - 部分待開發
位置: `PetWell/ContentView.swift:577-598`

**問題點**:
- 圖片選擇器為佔位區域，點擊無響應
- Tags 功能（Topic, User, Poll）點擊無後續動作

#### 5. Insurance - 部分待完成
位置: `Views/Insurance/InsuranceCompareView.swift`

- 第 349 行: Provider logos 為靜態佔位圖
- 第 811 行: AI 推薦圖標為佔位
- `insurance-to-do.md` 提到需連接真實後端 API

#### 6. 登錄 - 功能佔位
位置: `ViewModels/AuthViewModel.swift`

- 第 88 行: `// Placeholder for Google SSO — would use GoogleSignIn SDK`
- 第 121 行: `// Placeholder for email magic-link / OTP API`

---

## 研究發現

### 項目結構
```
PetWell/
├── PetWell/                    # 主應用
│   ├── ContentView.swift       # 主 Tab 導航
│   ├── ViewModels/
│   │   └── AuthViewModel.swift # 登錄邏輯
│   └── Views/
│       ├── Auth/               # 登錄相關
│       ├── Blog/               # Blog 頁面
│       ├── Guardian/           # AI 助手
│       ├── Insurance/          # 保險相關
│       ├── Map/                # 地圖
│       ├── Medical/            # 醫療相關
│       ├── Onboarding/         # 歡迎頁
│       ├── Records/            # 寵物檔案
│       ├── Shop/               # 商店
│       └── Social/             # 社交功能
├── Services/                   # 服務層
├── Models/                     # 數據模型
└── ViewModels/                 # ViewModels
```

### 現有實現較完善的功能
- ✅ Shop: 產品列表、購物車、結帳流程、篩選
- ✅ Medical: 地圖找診所、疫苗預約、緊急診所、健康檢查
- ✅ Insurance: 登陸頁、保險比較頁
- ✅ Blog: 帖子列表、發布表單框架
- ✅ Records: 寵物檔案 CRUD

---

## 各頁面詳細開發計劃

### 1. Profile 頁面 - Booking Record（預約記錄）

**功能需求**:
- 顯示用戶的歷史預約記錄
- 包含預約日期、診所、服務類型、狀態
- 支持按日期/診所篩選

**數據模型**:
```swift
struct BookingRecord: Identifiable {
    let id: UUID
    let clinicName: String
    let serviceType: String  // 疫苗、體檢、門診
    let scheduledDate: Date
    let status: BookingStatus  // upcoming, completed, cancelled
    let notes: String?
}
```

**API 需求**:
- `GET /api/bookings` - 獲取預約列表
- `GET /api/bookings/{id}` - 獲取詳情
- `POST /api/bookings` - 創建預約
- `PATCH /api/bookings/{id}` - 更新預約狀態

**開發順序**: P0

---

### 2. Profile 頁面 - Recent Purchase（最近購買）

**功能需求**:
- 顯示從 Shop 購買的歷史訂單
- 包含訂單日期、金額、狀態、發貨信息
- 支持查看訂單詳情

**數據模型**:
```swift
struct PurchaseRecord: Identifiable {
    let id: UUID
    let orderNumber: String
    let items: [Product]
    let totalAmount: Decimal
    let currency: String
    let purchaseDate: Date
    let fulfillmentStatus: String  // pending, shipped, delivered
    let trackingNumber: String?
}
```

**API 需求**:
- `GET /api/shopify/orders` - 從 Shopify 同步訂單

**開發順序**: P1

---

### 3. Profile 頁面 - Insurance（保險）

**功能需求**:
- 顯示用戶購買的保險計劃
- 包含保險公司、計劃名稱、覆蓋範圍、保費、到期日
- 快速鏈接到保險比較頁面

**數據模型**:
```swift
struct UserInsurance: Identifiable {
    let id: UUID
    let provider: String
    let planName: String
    let coverageType: [String]
    let premium: Decimal
    let currency: String
    let startDate: Date
    let endDate: Date
    let status: InsuranceStatus  // active, expired, cancelled
}
```

**API 需求**:
- `GET /api/user/insurances` - 獲取用戶保險
- `POST /api/user/insurances` - 關聯保險（可選）

**開發順序**: P1

---

### 4. Profile 頁面 - Activity Tracking（活動追蹤）

**功能需求**:
- 追蹤寵物的日常活動（步數、睡眠、進食）
- 顯示趨勢圖表
- 設定活動目標
- 提醒功能

**數據模型**:
```swift
struct ActivityRecord: Identifiable {
    let id: UUID
    let petId: UUID
    let date: Date
    let steps: Int
    let sleepHours: Double
    let mealsCount: Int
    let waterIntakeMl: Int
}
```

**設計考量**:
- 可能需要與健康設備集成（Apple Watch、寵物追蹤器）
- 可先實現基礎的手動記錄功能

**開發順序**: P2

---

### 5. Profile 頁面 - Travel Document（旅行證件）

**功能需求**:
- 存儲寵物的旅行證件信息
- 包含健康證明、疫苗記錄、進出口許可證
- 證件過期提醒
- 支持生成 PDF 導出

**數據模型**:
```swift
struct TravelDocument: Identifiable {
    let id: UUID
    let petId: UUID
    let documentType: DocumentType  // health_cert, vaccine_cert, import_permit
    let documentNumber: String
    let issueDate: Date
    let expiryDate: Date
    let issuingAuthority: String
    let fileUrl: URL?
}
```

**API 需求**:
- `POST /api/documents/upload` - 上傳證件掃描

**開發順序**: P2

---

### 6. Profile 頁面 - Pet Care Tips（寵物照顧提示）

**功能需求**:
- 根據用戶的寵物種類和年齡推薦護理知識
- 季節性提醒（寄生蟲預防、剃毛等）
- 獸醫建議文章

**數據來源**:
- 可以從現有的 Blog Service 獲取文章
- 或接入寵物知識 API

**設計考量**:
- 可與 Guardian AI 助手集成，實現智能問答

**開發順序**: P2

---

### 7. Social Search - 添加好友

**功能需求**:
- 搜索其他用戶
- 發送好友請求
- 處理請求（接受/拒絕）
- 好友列表管理

**數據模型**:
```swift
struct User: Identifiable {
    let id: UUID
    let displayName: String
    let avatarUrl: URL?
    let pets: [PetSummary]
    let friendStatus: FriendStatus  // none, pending, friends
}

enum FriendStatus {
    case none
    case pending(incoming: Bool)
    case friends
}
```

**API 需求**:
- `GET /api/users/search?q={query}` - 搜索用戶
- `POST /api/friends/request` - 發送好友請求
- `POST /api/friends/respond` - 回應好友請求
- `GET /api/friends` - 獲取好友列表

**開發順序**: P1

---

### 8. Social Search - 商店/診所詳情

**功能需求**:
- 點擊商店/診所進入詳情頁面
- 顯示基本信息、位置、評價
- 支持導航到 Google Maps
- 顯示營業時間

**數據模型**:
```swift
struct SearchableEntity: Identifiable {
    let id: String
    let name: String
    let type: EntityType  // shop, clinic
    let address: String
    let distance: Double?
    let rating: Double?
    let phone: String?
}
```

**API 需求**:
- `GET /api/shops/{id}` - 商店詳情
- `GET /api/clinics/{id}` - 診所詳情

**開發順序**: P1

---

### 9. Share Pet Profile

**功能需求**:
- 生成分享鏈接或二維碼
- 設置分享權限（公開/私密）
- 追蹤分享次數

**API 需求**:
- `POST /api/pets/{id}/share` - 創建分享鏈接
- `GET /api/pets/shared/{token}` - 通過分享訪問

**開發順序**: P2

---

### 10. Blog Post - 圖片選擇器

**功能需求**:
- 從相冊選擇圖片
- 拍攝新照片
- 裁剪和濾鏡（可選）
- 多圖上傳支持

**實現方式**:
- 使用 SwiftUI 的 PhotosPicker
- 圖片壓縮後上傳到存儲服務

**API 需求**:
- `POST /api/media/upload` - 上傳圖片

**開發順序**: P1

---

### 11. Blog Post - Tags 功能

**功能需求**:
- 添加 Topic 標籤
- 提及用戶 (@username)
- 創建投票
- 添加位置

**實現方式**:
- 使用 SwiftUI 的 TextField + 自動完成
- 後端解析標籤語法

**API 需求**:
- `GET /api/topics` - 獲取熱門標籤
- `GET /api/users/mentions?q={query}` - 用戶自動完成

**開發順序**: P2

---

### 12. Insurance - AI 推薦

**功能需求**:
- 基於用戶的寵物信息推薦保險
- 對話式界面收集需求
- 顯示個性化推薦結果

**實現方式**:
- 使用現有的 RAG Service
- 或接入專業保險推薦 API

**API 需求**:
- `POST /api/insurance/recommend` - AI 推薦

**開發順序**: P1

---

### 13. Insurance - Provider Logos

**功能需求**:
- 顯示保險公司的標誌
- 從後端動態獲取
- 緩存處理

**API 需求**:
- `GET /api/insurance/providers` - 獲取保險公司列表（含 logo URL）

**開發順序**: P1

---

### 14. 登錄 - Google SSO

**功能需求**:
- 使用 Google 帳戶登錄
- 獲取用戶信息
- 創建/關聯本地帳戶

**實現方式**:
- 集成 Google Sign-In SDK
- 處理 OAuth 流程

**API 需求**:
- `POST /api/auth/google` - Google 登錄回調

**開發順序**: P1

---

### 15. 登錄 - Email OTP

**功能需求**:
- 使用郵箱 + 驗證碼登錄
- 發送驗證碼郵件
- 驗證驗證碼

**API 需求**:
- `POST /api/auth/otp/send` - 發送驗證碼
- `POST /api/auth/otp/verify` - 驗證並登錄

**開發順序**: P1

---

## 優先級排序

| 優先級 | 功能 | 預估工作量 |
|--------|------|-----------|
| P0 | Booking Record | Medium |
| P0 | Insurance 模塊（Profile） | Medium |
| P0 | Google SSO 登錄 | Medium |
| P1 | Recent Purchase | Medium |
| P1 | Social Search - 添加好友 | Medium |
| P1 | Social Search - 詳情頁 | Small |
| P1 | Blog 圖片選擇器 | Small |
| P1 | Email OTP 登錄 | Medium |
| P1 | Insurance AI 推薦 | Medium |
| P2 | Activity Tracking | Large |
| P2 | Travel Document | Medium |
| P2 | Pet Care Tips | Medium |
| P2 | Share Pet Profile | Small |
| P2 | Blog Tags | Medium |

---

## 共享組件設計

### 1. NetworkService
- 統一的 API 請求處理
- 認證 token 管理
- 錯誤處理

### 2. ImagePicker
- 圖片選擇和上傳
- 進度顯示
- 錯誤處理

### 3. PlaceholderView 替換
- 所有 PlaceholderView 需要替換為真實頁面

---

## 依賴關係

```
登錄 (Google/OTP)
    ↓
用戶認證 → Social Search, Blog Post, Profile
    ↓
各模塊數據加載
```

---

## 技術決策

| 決策 | 理由 |
|------|------|
| 使用 SwiftUI PhotosPicker | 原生支持，無需額外依賴 |
| 先實現 Profile 模塊 | 直接影響用戶留存 |
| Google Sign-In SDK | 業界標準，安全性高 |
| RAG Service 用於保險推薦 | 現有服務，可復用 |

---

## 資源

- 項目路徑: ~/Desktop/PetWell/
- 關鍵文件:
  - `Views/Records/RecordsView.swift`
  - `Views/Social/SocialSearchView.swift`
  - `Views/Social/SharePetProfileView.swift`
  - `Views/Insurance/InsuranceCompareView.swift`
  - `ViewModels/AuthViewModel.swift`
  - `PetWell/ContentView.swift`
