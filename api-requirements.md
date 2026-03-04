# PetWell iOS API 需求文檔

## 概述
本文檔記錄 PetWell iOS 應用所需的後端 API 接口。根據功能優先級排序。

---

## P0 優先級 API

### 1. 登錄認證 (Auth)

| 方法 | 端點 | 描述 |
|------|------|------|
| POST | /api/auth/login | 郵箱/手機密碼登錄 |
| POST | /api/auth/google | Google SSO 登錄回調 |
| POST | /api/auth/otp/send | 發送郵箱驗證碼 |
| POST | /api/auth/otp/verify | 驗證驗證碼並登錄 |

**請求/響應格式**:
```json
// POST /api/auth/otp/send
Request: { "email": "user@example.com" }
Response: { "success": true, "message": "Verification code sent" }

// POST /api/auth/otp/verify
Request: { "email": "user@example.com", "code": "123456" }
Response: { "success": true, "token": "jwt_token", "user": {...} }
```

### 2. 預約記錄 (Booking Record)

| 方法 | 端點 | 描述 |
|------|------|------|
| GET | /api/bookings | 獲取用戶預約列表 |
| GET | /api/bookings/{id} | 獲取預約詳情 |
| POST | /api/bookings | 創建新預約 |
| PATCH | /api/bookings/{id} | 更新預約狀態 |

**數據模型**:
```swift
struct BookingRecord: Codable, Identifiable {
    let id: UUID
    let clinicId: Int
    let clinicName: String
    let serviceType: String  // "vaccination", "checkup", "consultation"
    let scheduledDate: Date
    let status: String  // "upcoming", "completed", "cancelled"
    let notes: String?
    let petId: UUID?
}
```

### 3. 用戶保險 (Profile Insurance)

| 方法 | 端點 | 描述 |
|------|------|------|
| GET | /api/user/insurances | 獲取用戶保險列表 |
| POST | /api/user/insurances | 關聯用戶保險 |

**數據模型**:
```swift
struct UserInsurance: Codable, Identifiable {
    let id: UUID
    let provider: String
    let planName: String
    let coverageType: [String]
    let premium: Decimal
    let currency: String
    let startDate: Date
    let endDate: Date
    let status: String  // "active", "expired", "cancelled"
}
```

---

## P1 優先級 API

### 4. 最近購買 (Recent Purchase)

| 方法 | 端點 | 描述 |
|------|------|------|
| GET | /api/shopify/orders | 從 Shopify 同步訂單 |

**數據模型**:
```swift
struct PurchaseRecord: Codable, Identifiable {
    let id: UUID
    let orderNumber: String
    let items: [OrderItem]
    let totalAmount: Decimal
    let currency: String
    let purchaseDate: Date
    let fulfillmentStatus: String  // "pending", "shipped", "delivered"
    let trackingNumber: String?
}
```

### 5. 社交搜索 (Social Search)

| 方法 | 端點 | 描述 |
|------|------|------|
| GET | /api/users/search?q={query} | 搜索用戶 |
| POST | /api/friends/request | 發送好友請求 |
| POST | /api/friends/respond | 回應好友請求 |
| GET | /api/friends | 獲取好友列表 |
| GET | /api/shops/{id} | 商店詳情 |
| GET | /api/clinics/{id} | 診所詳情 |

### 6. Blog 帖子

| 方法 | 端點 | 描述 |
|------|------|------|
| POST | /api/media/upload | 上傳圖片 |
| GET | /api/topics | 獲取熱門標籤 |
| GET | /api/users/mentions?q={query} | 用戶自動完成 |

### 7. 保險 AI 推薦

| 方法 | 端點 | 描述 |
|------|------|------|
| POST | /api/insurance/recommend | AI 保險推薦 |
| GET | /api/insurance/providers | 獲取保險公司列表(含 logo) |

---

## P2 優先級 API

### 8. 寵物活動追蹤

| 方法 | 端點 | 描述 |
|------|------|------|
| GET | /api/activities | 獲取活動記錄 |
| POST | /api/activities | 記錄活動數據 |

### 9. 旅行證件

| 方法 | 端點 | 描述 |
|------|------|------|
| POST | /api/documents/upload | 上傳證件掃描 |
| GET | /api/documents | 獲取證件列表 |

### 10. 分享寵物檔案

| 方法 | 端點 | 描述 |
|------|------|------|
| POST | /api/pets/{id}/share | 創建分享鏈接 |
| GET | /api/pets/shared/{token} | 通過分享訪問 |

---

## 現有 API 端點（已實現）

根據 InsuranceService 的代碼，以下端點已經可用：

| 端點 | 描述 |
|------|------|
| GET /insurance-companies | 獲取保險公司列表 |
| GET /insurance-products | 獲取保險產品列表 |
| GET /coverage-list | 獲取保險覆蓋項目 |
| GET /coverage-limits | 獲取覆蓋限額 |
| GET /sub-coverage-limits | 獲取子覆蓋限額 |
| GET /insurance-providers | 獲取保險提供商（舊版） |
| GET /service-subcategories | 獲取服務子類別 |

---

## 認證要求

所有需要用戶認證的 API 端點需要在 Header 中攜帶 JWT Token：

```
Authorization: Bearer <jwt_token>
```

---

## 錯誤處理標準

所有 API 響應遵循統一格式：

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}

// 錯誤響應
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human readable error message"
}
```

---

## 文檔維護

- 最後更新: 2026-03-04
- 更新人: Team Lead
- 備註: 隨著功能開發持續更新
