# PetWell Backend

基于 FastAPI 的后端服务，实现 P0 优先级 API。

## 快速启动

```bash
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

## 已实现 API

### P0 - 认证 API

| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /api/auth/otp/send | 发送邮箱验证码 |
| POST | /api/auth/otp/verify | 验证验证码并登录 |

### P0 - 预约 API

| 方法 | 端点 | 描述 |
|------|------|------|
| GET | /api/bookings | 获取预约列表 |
| GET | /api/bookings/{id} | 获取预约详情 |
| POST | /api/bookings | 创建预约 |
| PATCH | /api/bookings/{id} | 更新预约状态 |

### P0 - 用户保险 API

| 方法 | 端点 | 描述 |
|------|------|------|
| GET | /api/user/insurances | 获取用户保险列表 |
| POST | /api/user/insurances | 关联保险 |

## 测试命令

```bash
# 健康检查
curl http://localhost:8000/health

# 发送验证码
curl -X POST http://localhost:8000/api/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "purpose": "login"}'

# 获取预约列表
curl http://localhost:8000/api/bookings

# 创建预约
curl -X POST http://localhost:8000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "clinic_id": "clinic-123",
    "pet_id": "pet-456",
    "service_type": "vaccine",
    "scheduled_date": "2026-03-15T10:00:00Z",
    "notes": "需要注射狂犬疫苗"
  }'

# 获取用户保险
curl http://localhost:8000/api/user/insurances
```

## 技术栈

- FastAPI
- Pydantic
- Uvicorn
