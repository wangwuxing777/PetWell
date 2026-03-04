"""
PetWell Backend - FastAPI Application
P0 Priority APIs: Authentication (OTP), Bookings, User Insurances
"""

import uuid
import random
import string
from datetime import datetime, timedelta
from typing import Optional, List
from enum import Enum

from fastapi import FastAPI, HTTPException, Depends, Header, Query
from pydantic import BaseModel, EmailStr
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="PetWell API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============== Models ==============

class OtpPurpose(str, Enum):
    login = "login"
    register = "register"


class BookingStatus(str, Enum):
    upcoming = "upcoming"
    completed = "completed"
    cancelled = "cancelled"


class ServiceType(str, Enum):
    vaccine = "vaccine"
    checkup = "checkup"
    emergency = "emergency"


class InsuranceStatus(str, Enum):
    active = "active"
    expired = "expired"
    cancelled = "cancelled"


# OTP Models
class OtpSendRequest(BaseModel):
    email: EmailStr
    purpose: OtpPurpose = OtpPurpose.login


class OtpSendResponse(BaseModel):
    otp_id: str
    expires_in: int
    message: str


class OtpVerifyRequest(BaseModel):
    otp_id: str
    code: str
    device_id: Optional[str] = None


class User(BaseModel):
    id: str
    email: str
    display_name: str
    avatar_url: Optional[str] = None
    created_at: datetime


class AuthResponse(BaseModel):
    user: User
    access_token: str
    refresh_token: str
    expires_in: int
    is_new_user: bool


# Booking Models
class Booking(BaseModel):
    id: str
    clinic_id: str
    clinic_name: str
    service_type: ServiceType
    scheduled_date: datetime
    status: BookingStatus
    notes: Optional[str] = None
    pet_id: str
    pet_name: str
    created_at: datetime


class BookingCreateRequest(BaseModel):
    clinic_id: str
    pet_id: str
    service_type: ServiceType
    scheduled_date: datetime
    notes: Optional[str] = None


class BookingUpdateRequest(BaseModel):
    status: BookingStatus
    notes: Optional[str] = None


class BookingListResponse(BaseModel):
    bookings: List[Booking]
    pagination: dict


# Insurance Models
class UserInsurance(BaseModel):
    id: str
    provider: str
    plan_name: str
    coverage_type: List[str]
    premium: str
    currency: str
    start_date: str
    end_date: str
    status: InsuranceStatus


class InsuranceListResponse(BaseModel):
    insurances: List[UserInsurance]


# ============== In-Memory Storage ==============

# Simulated database
otp_store: dict = {}
user_store: dict = {}
booking_store: dict = {}
insurance_store: dict = {}

# Current user (simulated)
current_user_id = str(uuid.uuid4())
current_user = User(
    id=current_user_id,
    email="demo@petwell.com",
    display_name="Demo User",
    avatar_url=None,
    created_at=datetime.now()
)
user_store[current_user_id] = current_user


# ============== Dependencies ==============

def get_current_user(authorization: str = Header(None)) -> User:
    """Mock authentication dependency"""
    if not authorization:
        # Return demo user for development
        return current_user
    # In production, validate JWT token here
    return current_user


# ============== P0 - Auth APIs ==============

@app.post("/api/auth/otp/send", response_model=OtpSendResponse)
async def send_otp(request: OtpSendRequest):
    """
    Send OTP code to email
    """
    otp_id = str(uuid.uuid4())
    # Generate 6-digit code (in production, send via email)
    code = ''.join(random.choices(string.digits, k=6))

    # Store OTP (in production, use Redis with expiration)
    otp_store[otp_id] = {
        "email": request.email,
        "code": code,
        "purpose": request.purpose,
        "expires_at": datetime.now() + timedelta(minutes=5)
    }

    # In development, return the code in response (remove in production!)
    print(f"[DEV] OTP for {request.email}: {code}")

    return OtpSendResponse(
        otp_id=otp_id,
        expires_in=300,
        message="验证码已发送"
    )


@app.post("/api/auth/otp/verify", response_model=AuthResponse)
async def verify_otp(request: OtpVerifyRequest):
    """
    Verify OTP code and login
    """
    otp_data = otp_store.get(request.otp_id)

    if not otp_data:
        raise HTTPException(status_code=400, detail="无效的验证码ID")

    if datetime.now() > otp_data["expires_at"]:
        raise HTTPException(status_code=400, detail="验证码已过期")

    if otp_data["code"] != request.code:
        raise HTTPException(status_code=400, detail="验证码错误")

    # Generate tokens (in production, use JWT)
    access_token = f"mock_access_{uuid.uuid4().hex[:16]}"
    refresh_token = f"mock_refresh_{uuid.uuid4().hex[:16]}"

    # Check if user exists, create if not
    email = otp_data["email"]
    user = None
    for u in user_store.values():
        if u.email == email:
            user = u
            is_new_user = False
            break

    if not user:
        is_new_user = True
        user = User(
            id=str(uuid.uuid4()),
            email=email,
            display_name=email.split("@")[0],
            created_at=datetime.now()
        )
        user_store[user.id] = user

    # Clean up OTP
    del otp_store[request.otp_id]

    return AuthResponse(
        user=user,
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=3600,
        is_new_user=is_new_user
    )


# ============== P0 - Booking APIs ==============

@app.get("/api/bookings", response_model=BookingListResponse)
async def get_bookings(
    status: Optional[BookingStatus] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user)
):
    """
    Get user's booking list
    """
    bookings = list(booking_store.values())

    # Filter by status if provided
    if status:
        bookings = [b for b in bookings if b.status == status]

    # Sort by scheduled date
    bookings.sort(key=lambda x: x.scheduled_date, reverse=True)

    # Pagination
    total = len(bookings)
    total_pages = (total + limit - 1) // limit
    start = (page - 1) * limit
    end = start + limit
    paginated_bookings = bookings[start:end]

    return BookingListResponse(
        bookings=paginated_bookings,
        pagination={
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": total_pages
        }
    )


@app.get("/api/bookings/{booking_id}")
async def get_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get booking details
    """
    booking = booking_store.get(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="预约不存在")

    return {"success": True, "data": booking}


@app.post("/api/bookings", response_model=dict)
async def create_booking(
    request: BookingCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Create a new booking
    """
    booking_id = str(uuid.uuid4())

    # Mock clinic data
    clinic_names = {
        "vaccine": "香港宠物疫苗中心",
        "checkup": "宠物健康检查中心",
        "emergency": "宠物急诊医院"
    }

    service_names = {
        "vaccine": "疫苗注射",
        "checkup": "全面体检",
        "emergency": "急诊服务"
    }

    booking = Booking(
        id=booking_id,
        clinic_id=request.clinic_id,
        clinic_name=clinic_names.get(request.service_type, "宠物诊所"),
        service_type=request.service_type,
        scheduled_date=request.scheduled_date,
        status=BookingStatus.upcoming,
        notes=request.notes,
        pet_id=request.pet_id,
        pet_name="我的宠物",  # In production, fetch from pet store
        created_at=datetime.now()
    )

    booking_store[booking_id] = booking

    return {
        "success": True,
        "data": {
            "id": booking_id,
            "status": "upcoming",
            "message": "预约创建成功"
        }
    }


@app.patch("/api/bookings/{booking_id}")
async def update_booking(
    booking_id: str,
    request: BookingUpdateRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Update booking status
    """
    booking = booking_store.get(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="预约不存在")

    booking.status = request.status
    if request.notes is not None:
        booking.notes = request.notes

    return {
        "success": True,
        "data": {
            "id": booking_id,
            "status": request.status,
            "updated_at": datetime.now().isoformat()
        }
    }


# ============== P0 - User Insurance APIs ==============

@app.get("/api/user/insurances", response_model=InsuranceListResponse)
async def get_user_insurances(
    current_user: User = Depends(get_current_user)
):
    """
    Get user's insurance list
    """
    insurances = list(insurance_store.values())

    return InsuranceListResponse(insurances=insurances)


@app.post("/api/user/insurances", response_model=dict)
async def create_user_insurance(
    insurance_id: int,
    policy_number: str,
    start_date: str,
    end_date: str,
    premium: str,
    currency: str = "HKD",
    current_user: User = Depends(get_current_user)
):
    """
    Associate insurance with user
    """
    insurance_id_str = str(uuid.uuid4())

    # Mock insurance data
    insurance = UserInsurance(
        id=insurance_id_str,
        provider="平安宠物保险",
        plan_name="宠物健康保障计划",
        coverage_type=["意外", "疾病", "手术"],
        premium=premium,
        currency=currency,
        start_date=start_date,
        end_date=end_date,
        status=InsuranceStatus.active
    )

    insurance_store[insurance_id_str] = insurance

    return {
        "success": True,
        "data": {
            "id": insurance_id_str,
            "status": "active",
            "message": "保险关联成功"
        }
    }


# ============== Health Check ==============

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
