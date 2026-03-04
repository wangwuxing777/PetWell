# PetWell API 规格文档

本文档定义 PetWell 后端 API 接口详细规格。

## 基础信息

| 项目 | 值 |
|------|-----|
| Base URL | `http://localhost:8000` |
| 认证方式 | Bearer Token |
| Content-Type | `application/json` |
| API 版本 | v1 |

---

## 通用响应格式

### 成功响应

```json
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述"
  }
}
```

---

## P0 - 认证 API

### 1. POST /api/auth/otp/send
发送邮箱验证码

#### 请求

```http
POST /api/auth/otp/send
Content-Type: application/json
```

```json
{
  "email": "user@example.com",
  "purpose": "login"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| purpose | string | 否 | 用途: `login` (默认) 或 `register` |

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "otp_id": "uuid-string",
    "expires_in": 300,
    "message": "验证码已发送"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| otp_id | string | 验证码ID，用于后续验证 |
| expires_in | int | 验证码有效期（秒） |
| message | string | 提示信息 |

#### 错误码

| 错误码 | 说明 |
|--------|------|
| VALIDATION_ERROR | 邮箱格式不正确 |

---

### 2. POST /api/auth/otp/verify
验证验证码并登录

#### 请求

```http
POST /api/auth/otp/verify
Content-Type: application/json
```

```json
{
  "otp_id": "uuid-string",
  "code": "123456",
  "device_id": "optional-device-id"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| otp_id | string | 是 | 发送验证码返回的ID |
| code | string | 是 | 6位验证码 |
| device_id | string | 否 | 设备唯一标识 |

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "display_name": "用户名",
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

#### 错误码

| 错误码 | 说明 |
|--------|------|
| INVALID_OTP_ID | 无效的验证码ID |
| OTP_EXPIRED | 验证码已过期 |
| INVALID_CODE | 验证码错误 |

---

## P0 - 预约 API

### 3. GET /api/bookings
获取用户预约列表

#### 请求

```http
GET /api/bookings?status=upcoming&page=1&limit=20
Authorization: Bearer {token}
```

| 查询参数 | 类型 | 必填 | 说明 |
|----------|------|------|------|
| status | string | 否 | 筛选: `upcoming`, `completed`, `cancelled` |
| page | int | 否 | 页码，默认 1 |
| limit | int | 否 | 每页数量，默认 20 |

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "bookings": [
      {
        "id": "uuid",
        "clinic_id": "uuid",
        "clinic_name": "宠物诊所名称",
        "service_type": "vaccine",
        "scheduled_date": "2024-01-15T10:00:00Z",
        "status": "upcoming",
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

#### Booking 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 预约唯一ID |
| clinic_id | string | 诊所ID |
| clinic_name | string | 诊所名称 |
| service_type | string | 服务类型: `vaccine`, `checkup`, `emergency` |
| scheduled_date | datetime | 预约时间 |
| status | string | 状态: `upcoming`, `completed`, `cancelled` |
| notes | string? | 备注 |
| pet_id | string | 宠物ID |
| pet_name | string | 宠物名称 |
| created_at | datetime | 创建时间 |

---

### 4. GET /api/bookings/{id}
获取预约详情

#### 请求

```http
GET /api/bookings/{booking_id}
Authorization: Bearer {token}
```

| 路径参数 | 类型 | 说明 |
|----------|------|------|
| id | string | 预约ID |

#### 响应 (200)

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
      "species": "dog",
      "breed": "品种"
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

#### 错误码

| 错误码 | 说明 |
|--------|------|
| NOT_FOUND | 预约不存在 |

---

### 5. POST /api/bookings
创建预约

#### 请求

```http
POST /api/bookings
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "clinic_id": "uuid",
  "pet_id": "uuid",
  "service_type": "vaccine",
  "scheduled_date": "2024-01-15T10:00:00Z",
  "notes": "备注信息"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| clinic_id | string | 是 | 诊所ID |
| pet_id | string | 是 | 宠物ID |
| service_type | string | 是 | 服务类型: `vaccine`, `checkup`, `emergency` |
| scheduled_date | datetime | 是 | 预约时间 (ISO 8601) |
| notes | string | 否 | 备注 |

#### 响应 (201)

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

### 6. PATCH /api/bookings/{id}
更新预约状态

#### 请求

```http
PATCH /api/bookings/{booking_id}
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "status": "cancelled",
  "notes": "取消原因"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | string | 是 | 新状态: `cancelled`, `completed` |
| notes | string | 否 | 备注/取消原因 |

#### 响应 (200)

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

#### 错误码

| 错误码 | 说明 |
|--------|------|
| NOT_FOUND | 预约不存在 |

---

## P0 - 用户保险 API

### 7. GET /api/user/insurances
获取用户保险列表

#### 请求

```http
GET /api/user/insurances
Authorization: Bearer {token}
```

#### 响应 (200)

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
        "status": "active"
      }
    ]
  }
}
```

---

### 8. POST /api/user/insurances
关联用户保险

#### 请求

```http
POST /api/user/insurances
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "insurance_id": 1,
  "policy_number": "POL123456",
  "start_date": "2024-01-01",
  "end_date": "2025-01-01",
  "premium": "1500.00",
  "currency": "HKD"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| insurance_id | int | 是 | 保险产品ID |
| policy_number | string | 是 | 保单号 |
| start_date | string | 是 | 生效日期 (YYYY-MM-DD) |
| end_date | string | 是 | 到期日期 (YYYY-MM-DD) |
| premium | string | 是 | 保费金额 |
| currency | string | 否 | 货币，默认 HKD |

#### 响应 (201)

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

## P1 - 社交 API

### 9. GET /api/users/search
搜索用户

#### 请求

```http
GET /api/users/search?q=关键词&limit=10
Authorization: Bearer {token}
```

| 查询参数 | 类型 | 必填 | 说明 |
|----------|------|------|------|
| q | string | 是 | 搜索关键词 |
| limit | int | 否 | 返回数量，默认 10 |

#### 响应 (200)

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
            "species": "dog",
            "breed": "品种"
          }
        ],
        "friend_status": "none"
      }
    ]
  }
}
```

| friend_status 值 | 说明 |
|------------------|------|
| none | 无关系 |
| pending_outgoing | 已发送请求 |
| pending_incoming | 收到请求 |
| friends | 已是好友 |

---

### 10. GET /api/friends
获取好友列表

#### 请求

```http
GET /api/friends
Authorization: Bearer {token}
```

#### 响应 (200)

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

#### 请求

```http
POST /api/friends/request
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "user_id": "目标用户ID"
}
```

#### 响应 (201)

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

#### 错误码

| 错误码 | 说明 |
|--------|------|
| NOT_FOUND | 用户不存在 |
| 400 | 已经是好友或已发送请求 |

---

### 12. POST /api/friends/respond
回应好友请求

#### 请求

```http
POST /api/friends/respond
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "request_id": "uuid",
  "action": "accept"
}
```

| action 值 | 说明 |
|-----------|------|
| accept | 接受 |
| reject | 拒绝 |

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "accepted",
    "message": "已接受好友请求"
  }
}
```

---

## P1 - 实体搜索 API

### 13. GET /api/entities/search
搜索商店/诊所

#### 请求

```http
GET /api/entities/search?q=关键词&type=shop&limit=10
Authorization: Bearer {token}
```

| 查询参数 | 类型 | 必填 | 说明 |
|----------|------|------|------|
| q | string | 是 | 搜索关键词 |
| type | string | 否 | 筛选类型: `shop` 或 `clinic` |
| limit | int | 否 | 返回数量，默认 10 |

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "entities": [
      {
        "id": "uuid",
        "name": "商店名称",
        "type": "shop",
        "address": "地址",
        "distance": 0.5,
        "rating": 4.5,
        "phone": "12345678"
      }
    ]
  }
}
```

---

### 14. GET /api/shops/{id}
获取商店详情

#### 请求

```http
GET /api/shops/{shop_id}
Authorization: Bearer {token}
```

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "商店名称",
    "type": "shop",
    "address": "地址",
    "distance": 0.5,
    "rating": 4.5,
    "phone": "12345678"
  }
}
```

---

### 15. GET /api/clinics/{id}
获取诊所详情

#### 请求

```http
GET /api/clinics/{clinic_id}
Authorization: Bearer {token}
```

#### 响应 (200)

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "诊所名称",
    "type": "clinic",
    "address": "地址",
    "distance": 2.0,
    "rating": 4.8,
    "phone": "11112222"
  }
}
```

---

## 错误码汇总

| 错误码 | HTTP 状态码 | 说明 |
|--------|-------------|------|
| UNAUTHORIZED | 401 | 未认证或 token 无效 |
| FORBIDDEN | 403 | 无权限访问 |
| NOT_FOUND | 404 | 资源不存在 |
| VALIDATION_ERROR | 422 | 请求参数验证失败 |
| RATE_LIMIT | 429 | 请求过于频繁 |
| SERVER_ERROR | 500 | 服务器内部错误 |
| INVALID_OTP_ID | 400 | 无效的验证码ID |
| OTP_EXPIRED | 400 | 验证码已过期 |
| INVALID_CODE | 400 | 验证码错误 |

---

## 认证流程

### 1. 发送验证码

```bash
curl -X POST http://localhost:8000/api/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "purpose": "login"}'
```

响应:
```json
{
  "otp_id": "2c24cfde-4531-465c-98b7-a7532af9b08c",
  "expires_in": 300,
  "message": "验证码已发送"
}
```

### 2. 验证登录 (开发模式验证码会在控制台输出)

```bash
# 查看控制台获取验证码
curl -X POST http://localhost:8000/api/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"otp_id": "2c24cfde-4531-465c-98b7-a7532af9b08c", "code": "123456"}'
```

---

## 启动后端服务

```bash
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

健康检查: `GET /health`
