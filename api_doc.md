# PetWell API 文档

本文档定义 PetWell 后端 API 接口规格，用于指导前端开发与后端集成。

## 基础信息

- **Base URL**: `https://api.petwell.example.com/v1`
- **认证方式**: Bearer Token (JWT)
- **Content-Type**: `application/json`
- **响应格式**: 统一 JSON 格式

### 通用响应格式

```json
// 成功响应
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}

// 错误响应
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述"
  }
}
```

---

## P0 - 登录相关 API

### 1. POST /api/auth/google
Google 登录回调接口

**请求头**:
```
Authorization: Bearer {id_token}
Content-Type: application/json
```

**请求体**:
```json
{
  "id_token": "string (required) - Google ID Token",
  "device_id": "string (optional) - 设备唯一标识"
}
```

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "display_name": "User Name",
      "avatar_url": "https://...",
      "created_at": "2024-01-01T00:00:00Z"
    },
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 3600
  }
}
```

---

### 2. POST /api/auth/otp/send
发送邮箱验证码

**请求体**:
```json
{
  "email": "user@example.com (required)",
  "purpose": "login | register"
}
```

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "otp_id": "uuid - 用于验证时关联",
    "expires_in": 300,
    "message": "验证码已发送"
  }
}
```

---

### 3. POST /api/auth/otp/verify
验证验证码并登录

**请求体**:
```json
{
  "otp_id": "uuid (required)",
  "code": "123456 (required - 6位验证码)",
  "device_id": "string (optional)"
}
```

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "display_name": "User Name",
      "avatar_url": "https://...",
      "created_at": "2024-01-01T00:00:00Z"
    },
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 3600,
    "is_new_user": false
  }
}
```

---

## P0 - 预约相关 API

### 4. GET /api/bookings
获取预约列表

**查询参数**:
- `status`: upcoming | completed | cancelled (可选)
- `page`: 页码 (默认 1)
- `limit`: 每页数量 (默认 20)

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "bookings": [
      {
        "id": "uuid",
        "clinic_id": "uuid",
        "clinic_name": "宠物诊所名称",
        "service_type": "vaccine | checkup | emergency",
        "scheduled_date": "2024-01-15T10:00:00Z",
        "status": "upcoming | completed | cancelled",
        "notes": "备注信息",
        "pet_id": "uuid",
        "pet_name": "宠物名称",
        "created_at": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "total_pages": 3
    }
  }
}
```

---

### 5. GET /api/bookings/{id}
获取预约详情

**路径参数**:
- `id`: 预约 UUID

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "clinic_id": "uuid",
    "clinic": {
      "id": "uuid",
      "name": "诊所名称",
      "address": "地址",
      "phone": "电话",
      "latitude": 22.2855,
      "longitude": 114.1577
    },
    "service_type": "vaccine",
    "service_name": "疫苗注射",
    "scheduled_date": "2024-01-15T10:00:00Z",
    "status": "upcoming",
    "notes": "备注",
    "pet": {
      "id": "uuid",
      "name": "宠物名称",
      "species": "dog | cat",
      "breed": "品种"
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

---

### 6. POST /api/bookings
创建预约

**请求体**:
```json
{
  "clinic_id": "uuid (required)",
  "pet_id": "uuid (required)",
  "service_type": "vaccine | checkup | emergency (required)",
  "scheduled_date": "2024-01-15T10:00:00Z (required)",
  "notes": "string (optional)"
}
```

**响应 (201)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "upcoming",
    "message": "预约创建成功"
  }
}
```

---

### 7. PATCH /api/bookings/{id}
更新预约状态

**路径参数**:
- `id`: 预约 UUID

**请求体**:
```json
{
  "status": "cancelled | completed (required)",
  "notes": "string (optional)"
}
```

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "cancelled",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

---

## P1 - 订单相关 API

### 8. GET /api/shopify/orders
从 Shopify 同步订单

**查询参数**:
- `status`: pending | shipped | delivered (可选)
- `page`: 页码 (默认 1)
- `limit`: 每页数量 (默认 20)

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": "uuid",
        "order_number": "SHP-12345",
        "shopify_order_id": "shopify_order_id",
        "items": [
          {
            "product_id": "uuid",
            "name": "产品名称",
            "quantity": 2,
            "price": "99.00",
            "currency": "HKD",
            "image_url": "https://..."
          }
        ],
        "total_amount": "198.00",
        "currency": "HKD",
        "purchase_date": "2024-01-01T00:00:00Z",
        "fulfillment_status": "pending | shipped | delivered",
        "tracking_number": "string (optional)",
        "shipping_address": {
          "line1": "地址行1",
          "line2": "地址行2",
          "city": "城市",
          "country": "国家"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

---

## P1 - 社交相关 API

### 9. GET /api/users/search
搜索用户

**查询参数**:
- `q`: 搜索关键词 (必填)
- `limit`: 返回数量 (默认 10)

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "uuid",
        "display_name": "用户名",
        "avatar_url": "https://...",
        "pets": [
          {
            "id": "uuid",
            "name": "宠物名",
            "species": "dog | cat",
            "breed": "品种"
          }
        ],
        "friend_status": "none | pending_outgoing | pending_incoming | friends"
      }
    ]
  }
}
```

---

### 10. GET /api/friends
获取好友列表

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "friends": [
      {
        "id": "uuid",
        "display_name": "好友名称",
        "avatar_url": "https://...",
        "friendship_date": "2024-01-01T00:00:00Z"
      }
    ],
    "pending_requests": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "display_name": "请求者名称",
        "avatar_url": "https://...",
        "requested_at": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

---

### 11. POST /api/friends/request
发送好友请求

**请求体**:
```json
{
  "user_id": "uuid (required) - 目标用户ID"
}
```

**响应 (201)**:
```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "pending",
    "message": "好友请求已发送"
  }
}
```

---

### 12. POST /api/friends/respond
回应好友请求

**请求体**:
```json
{
  "request_id": "uuid (required)",
  "action": "accept | reject (required)"
}
```

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "accepted | rejected",
    "message": "已接受/拒绝好友请求"
  }
}
```

---

## P1 - 保险相关 API

### 13. GET /api/user/insurances
获取用户保险

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "insurances": [
      {
        "id": "uuid",
        "provider": "保险公司名称",
        "plan_name": "计划名称",
        "coverage_type": ["意外", "疾病"],
        "premium": "1500.00",
        "currency": "HKD",
        "start_date": "2024-01-01",
        "end_date": "2025-01-01",
        "status": "active | expired | cancelled"
      }
    ]
  }
}
```

---

### 14. POST /api/user/insurances
关联用户保险

**请求体**:
```json
{
  "insurance_id": "int (required) - 保险产品ID",
  "policy_number": "string (required) - 保单号",
  "start_date": "2024-01-01 (required)",
  "end_date": "2025-01-01 (required)",
  "premium": "1500.00 (required)",
  "currency": "HKD (required)"
}
```

**响应 (201)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "active",
    "message": "保险关联成功"
  }
}
```

---

### 15. GET /api/insurance/providers
获取保险公司列表

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "providers": [
      {
        "company_id": 1,
        "company_name": "保险公司A",
        "company_name_zh": "保险公司A",
        "company_logo": "https://..."
      }
    ]
  }
}
```

---

### 16. POST /api/insurance/recommend
AI 推荐保险

**请求体**:
```json
{
  "pet_id": "uuid (required)",
  "pet_species": "dog | cat (required)",
  "pet_breed": "品种 (optional)",
  "pet_age": 3,
  "budget_range": {
    "min": 500,
    "max": 2000,
    "currency": "HKD"
  },
  "coverage_preferences": ["意外", "疾病", "手术"],
  "additional_requirements": "string (optional)"
}
```

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "insurance_id": 1,
        "insurance_name": "推荐计划A",
        "provider": "保险公司A",
        "match_score": 95,
        "coverage_summary": ["意外: HK$50,000", "疾病: HK$30,000"],
        "monthly_premium": "1500.00",
        "currency": "HKD",
        "reason": "根据您的宠物年龄和需求推荐"
      }
    ],
    "analysis": "基于您的需求分析..."
  }
}
```

---

## P2 - 文档相关 API

### 17. POST /api/documents/upload
上传证件扫描

**请求体**: Multipart form-data
```
file: binary (required) - 证件图片
pet_id: uuid (required)
document_type: health_cert | vaccine_cert | import_permit (required)
document_number: string (optional)
```

**响应 (201)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "document_type": "health_cert",
    "document_number": "DOC-12345",
    "file_url": "https://...",
    "uploaded_at": "2024-01-01T00:00:00Z"
  }
}
```

---

## P2 - 分享相关 API

### 18. POST /api/pets/{id}/share
创建宠物分享链接

**路径参数**:
- `id`: 宠物 UUID

**请求体**:
```json
{
  "permission": "public | private (default: private)",
  "expires_at": "2024-12-31T23:59:59Z (optional)",
  "allow_download": true
}
```

**响应 (201)**:
```json
{
  "success": true,
  "data": {
    "share_token": "unique_token_string",
    "share_url": "https://petwell.app/share/abc123",
    "qr_code_url": "https://...",
    "expires_at": "2024-12-31T23:59:59Z"
  }
}
```

---

### 19. GET /api/pets/shared/{token}
通过分享访问宠物资料

**路径参数**:
- `token`: 分享 token

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "pet": {
      "id": "uuid",
      "name": "宠物名称",
      "species": "dog",
      "breed": "品种",
      "age": 3,
      "avatar_url": "https://...",
      "vaccinations": [...],
      "medical_records": [...]
    },
    "owner": {
      "display_name": "主人名称",
      "message": "个人简介"
    },
    "share_info": {
      "permission": "public",
      "view_count": 10
    }
  }
}
```

---

## P2 - 媒体相关 API

### 20. POST /api/media/upload
上传图片

**请求体**: Multipart form-data
```
file: binary (required) - 图片文件
type: avatar | pet_photo | blog_post | document (required)
pet_id: uuid (optional) - 如果是宠物相关
```

**响应 (201)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "url": "https://cdn.petwell.example.com/...",
    "thumbnail_url": "https://cdn.petwell.example.com/..._thumb",
    "width": 1920,
    "height": 1080,
    "file_size": 1024000,
    "mime_type": "image/jpeg"
  }
}
```

---

## P2 - 博客相关 API

### 21. GET /api/topics
获取热门标签

**查询参数**:
- `limit`: 返回数量 (默认 20)

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "topics": [
      {
        "id": "uuid",
        "name": "宠物健康",
        "post_count": 150,
        "trend_score": 85
      },
      {
        "id": "uuid",
        "name": "养狗经验",
        "post_count": 120,
        "trend_score": 72
      }
    ]
  }
}
```

---

### 22. GET /api/users/mentions
用户自动完成

**查询参数**:
- `q`: 搜索关键词 (必填)
- `limit`: 返回数量 (默认 10)

**响应 (200)**:
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "uuid",
        "username": "pet_lover",
        "display_name": "宠物爱好者",
        "avatar_url": "https://..."
      }
    ]
  }
}
```

---

## 错误码说明

| 错误码 | 描述 |
|--------|------|
| UNAUTHORIZED | 未认证或 token 无效 |
| FORBIDDEN | 无权限访问 |
| NOT_FOUND | 资源不存在 |
| VALIDATION_ERROR | 请求参数验证失败 |
| RATE_LIMIT | 请求过于频繁 |
| SERVER_ERROR | 服务器内部错误 |

---

## 认证流程

### 获取 Token
1. 首次登录通过 Google OAuth 或 OTP 获取 access_token 和 refresh_token
2. access_token 有效期 1 小时
3. 使用 refresh_token 刷新 access_token

### Token 刷新
```
POST /api/auth/refresh
Authorization: Bearer {refresh_token}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "access_token": "new_jwt_token",
    "expires_in": 3600
  }
}
```
