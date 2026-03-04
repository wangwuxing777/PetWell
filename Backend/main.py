"""
PetWell Backend - FastAPI Application
P0 + P1 Priority APIs: Auth, Bookings, User Insurances, Social
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


# Social Models
class FriendStatus(str, Enum):
    none = "none"
    pending_outgoing = "pending_outgoing"
    pending_incoming = "pending_incoming"
    friends = "friends"


class PetSummary(BaseModel):
    id: str
    name: str
    species: str
    breed: Optional[str] = None


class SearchedUser(BaseModel):
    id: str
    display_name: str
    avatar_url: Optional[str] = None
    pets: List[PetSummary]
    friend_status: FriendStatus


class Friend(BaseModel):
    id: str
    display_name: str
    avatar_url: Optional[str] = None
    friendship_date: datetime


class FriendRequest(BaseModel):
    id: str
    user_id: str
    display_name: str
    avatar_url: Optional[str] = None
    requested_at: datetime


class FriendsListResponse(BaseModel):
    friends: List[Friend]
    pending_requests: List[FriendRequest]


class FriendRequestAction(str, Enum):
    accept = "accept"
    reject = "reject"


class FriendRequestCreate(BaseModel):
    user_id: str


class FriendRequestRespond(BaseModel):
    request_id: str
    action: FriendRequestAction


# Entity Models (for shop/clinic search)
class EntityType(str, Enum):
    shop = "shop"
    clinic = "clinic"


class SearchableEntity(BaseModel):
    id: str
    name: str
    type: EntityType
    address: str
    distance: Optional[float] = None
    rating: Optional[float] = None
    phone: Optional[str] = None


# ============== In-Memory Storage ==============

# Simulated database
otp_store: dict = {}
user_store: dict = {}
booking_store: dict = {}
insurance_store: dict = {}
friend_store: dict = {}  # {user_id: {"friends": [], "pending": []}}
friend_request_store: dict = {}  # {request_id: {...}}

# Mock users for search
mock_users = [
    {"id": "user-001", "display_name": "宠物爱好者小明", "email": "xiaoming@pet.com", "avatar_url": None,
     "pets": [{"id": "pet-001", "name": "豆豆", "species": "dog", "breed": "金毛"}]},
    {"id": "user-002", "display_name": "爱猫人士小红", "email": "xiaohong@pet.com", "avatar_url": None,
     "pets": [{"id": "pet-002", "name": "咪咪", "species": "cat", "breed": "英短"}]},
    {"id": "user-003", "display_name": "养狗达人", "email": "doglover@pet.com", "avatar_url": None,
     "pets": [{"id": "pet-003", "name": "旺财", "species": "dog", "breed": "哈士奇"}]},
    {"id": "user-004", "display_name": "宠物医生李医生", "email": "drli@pet.com", "avatar_url": None,
     "pets": [{"id": "pet-004", "name": "小虎", "species": "cat", "breed": "狸花猫"}]},
]

# Mock shops and clinics for search
mock_entities = [
    {"id": "shop-001", "name": "宠物用品店", "type": "shop", "address": "中环皇后大道中99号", "distance": 0.5, "rating": 4.5, "phone": "12345678"},
    {"id": "shop-002", "name": "宠物食品超市", "type": "shop", "address": "铜锣湾时代广场", "distance": 1.2, "rating": 4.2, "phone": "87654321"},
    {"id": "clinic-001", "name": "香港宠物医院", "type": "clinic", "address": "尖沙咀弥敦道100号", "distance": 2.0, "rating": 4.8, "phone": "11112222"},
    {"id": "clinic-002", "name": "仁安宠物诊所", "type": "clinic", "address": "旺角朗豪坊", "distance": 1.5, "rating": 4.6, "phone": "33334444"},
]

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


# ============== P1 - Social APIs ==============

@app.get("/api/users/search")
async def search_users(
    q: str = Query(..., min_length=1),
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user)
):
    """
    Search users by name or email
    """
    # Filter mock users by query
    query = q.lower()
    results = []
    for user in mock_users:
        if (query in user["display_name"].lower() or
            query in user.get("email", "").lower()):
            # Determine friend status
            friend_status = FriendStatus.none

            # Check friend store for current user
            user_friends = friend_store.get(current_user.id, {})
            friends_list = user_friends.get("friends", [])
            pending_list = user_friends.get("pending", [])

            if user["id"] in [f["user_id"] for f in friends_list]:
                friend_status = FriendStatus.friends
            elif user["id"] in [r["user_id"] for r in pending_list]:
                friend_status = FriendStatus.pending_outgoing
            elif user["id"] in friend_request_store.get(current_user.id, []):
                friend_status = FriendStatus.pending_outgoing

            results.append({
                "id": user["id"],
                "display_name": user["display_name"],
                "avatar_url": user.get("avatar_url"),
                "pets": user.get("pets", []),
                "friend_status": friend_status.value
            })

            if len(results) >= limit:
                break

    return {"success": True, "data": {"users": results}}


@app.get("/api/friends", response_model=FriendsListResponse)
async def get_friends(
    current_user: User = Depends(get_current_user)
):
    """
    Get user's friends list and pending requests
    """
    user_friends = friend_store.get(current_user.id, {})

    friends_list = user_friends.get("friends", [])
    pending_list = user_friends.get("pending", [])

    # Convert to response format
    friends = []
    for f in friends_list:
        # Find user info from mock data
        user_info = next((u for u in mock_users if u["id"] == f["user_id"]), None)
        if user_info:
            friends.append(Friend(
                id=f["id"],
                display_name=user_info["display_name"],
                avatar_url=user_info.get("avatar_url"),
                friendship_date=f["created_at"]
            ))

    pending_requests = []
    for r in pending_list:
        user_info = next((u for u in mock_users if u["id"] == r["user_id"]), None)
        if user_info:
            pending_requests.append(FriendRequest(
                id=r["id"],
                user_id=r["user_id"],
                display_name=user_info["display_name"],
                avatar_url=user_info.get("avatar_url"),
                requested_at=r["created_at"]
            ))

    return FriendsListResponse(friends=friends, pending_requests=pending_requests)


@app.post("/api/friends/request")
async def send_friend_request(
    request: FriendRequestCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Send a friend request
    """
    # Check if already friends
    user_friends = friend_store.get(current_user.id, {})
    friends_list = user_friends.get("friends", [])
    pending_list = user_friends.get("pending", [])

    if any(f["user_id"] == request.user_id for f in friends_list):
        raise HTTPException(status_code=400, detail="已经是好友")

    if any(r["user_id"] == request.user_id for r in pending_list):
        raise HTTPException(status_code=400, detail="已经发送过好友请求")

    # Check if the target user exists
    target_user = next((u for u in mock_users if u["id"] == request.user_id), None)
    if not target_user:
        raise HTTPException(status_code=404, detail="用户不存在")

    # Create friend request
    request_id = str(uuid.uuid4())
    friend_request = {
        "id": request_id,
        "user_id": request.user_id,
        "created_at": datetime.now()
    }

    # Store request
    if current_user.id not in friend_store:
        friend_store[current_user.id] = {"friends": [], "pending": []}
    friend_store[current_user.id]["pending"].append(friend_request)

    # Also add to request store (for incoming requests)
    if request.user_id not in friend_request_store:
        friend_request_store[request.user_id] = []
    friend_request_store[request.user_id].append({
        "from_user_id": current_user.id,
        "request_id": request_id
    })

    return {
        "success": True,
        "data": {
            "request_id": request_id,
            "status": "pending",
            "message": "好友请求已发送"
        }
    }


@app.post("/api/friends/respond")
async def respond_friend_request(
    request: FriendRequestRespond,
    current_user: User = Depends(get_current_user)
):
    """
    Accept or reject a friend request
    """
    # Find the request
    found_request = None
    request_user_id = None

    for user_id, requests in friend_request_store.items():
        for r in requests:
            if r["request_id"] == request.request_id:
                found_request = r
                request_user_id = user_id
                break
        if found_request:
            break

    if not found_request:
        raise HTTPException(status_code=404, detail="好友请求不存在")

    if request.action == FriendRequestAction.accept:
        # Add to friends
        if current_user.id not in friend_store:
            friend_store[current_user.id] = {"friends": [], "pending": []}

        friend_store[current_user.id]["friends"].append({
            "id": str(uuid.uuid4()),
            "user_id": request_user_id,
            "created_at": datetime.now()
        })

        # Remove from pending
        friend_store[current_user.id]["pending"] = [
            r for r in friend_store[current_user.id]["pending"]
            if r["user_id"] != request_user_id
        ]

        # Remove from request store
        friend_request_store[current_user.id] = [
            r for r in friend_request_store.get(current_user.id, [])
            if r["request_id"] != request.request_id
        ]

        return {
            "success": True,
            "data": {
                "request_id": request.request_id,
                "status": "accepted",
                "message": "已接受好友请求"
            }
        }
    else:
        # Reject - just remove from pending
        friend_store[current_user.id]["pending"] = [
            r for r in friend_store[current_user.id].get("pending", [])
            if r["user_id"] != request_user_id
        ]

        friend_request_store[current_user.id] = [
            r for r in friend_request_store.get(current_user.id, [])
            if r["request_id"] != request.request_id
        ]

        return {
            "success": True,
            "data": {
                "request_id": request.request_id,
                "status": "rejected",
                "message": "已拒绝好友请求"
            }
        }


# ============== Entity Search APIs ==============

@app.get("/api/entities/search")
async def search_entities(
    q: str = Query(..., min_length=1),
    entity_type: Optional[EntityType] = None,
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user)
):
    """
    Search shops or clinics
    """
    query = q.lower()
    results = []

    for entity in mock_entities:
        if entity_type and entity["type"] != entity_type:
            continue
        if query in entity["name"].lower() or query in entity["address"].lower():
            results.append(entity)
            if len(results) >= limit:
                break

    return {"success": True, "data": {"entities": results}}


@app.get("/api/shops/{shop_id}")
async def get_shop_details(
    shop_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get shop details
    """
    shop = next((e for e in mock_entities if e["id"] == shop_id and e["type"] == "shop"), None)
    if not shop:
        raise HTTPException(status_code=404, detail="商店不存在")

    return {"success": True, "data": shop}


@app.get("/api/clinics/{clinic_id}")
async def get_clinic_details(
    clinic_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get clinic details
    """
    clinic = next((e for e in mock_entities if e["id"] == clinic_id and e["type"] == "clinic"), None)
    if not clinic:
        raise HTTPException(status_code=404, detail="诊所不存在")

    return {"success": True, "data": clinic}


# ============== Health Check ==============

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
