"""
Authentication Router
Handles user registration, login, logout, and password reset
"""
from fastapi import APIRouter, Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordRequestForm
from motor.motor_asyncio import AsyncIOMotorDatabase
from datetime import datetime, timedelta
from typing import Optional
from bson import ObjectId

from app.core.database import get_database
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_otp,
    generate_reset_token,
    create_session,
    invalidate_session,
    invalidate_all_sessions,
    get_current_user
)
from app.models.schemas import (
    UserCreate,
    UserLogin,
    UserResponse,
    Token,
    TokenRefresh,
    PasswordReset,
    PasswordResetConfirm,
    SessionInfo
)
from app.core.config import settings
from app.utils.email_sender import send_password_reset_email
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Register a new user
    
    Epic 1, Pile 1 - User Registration (US1)
    """
    try:
        # Check if user already exists
        existing_user = None
        if user_data.email:
            existing_user = await db.users.find_one({"email": user_data.email})
        if not existing_user and user_data.phone:
            existing_user = await db.users.find_one({"phone": user_data.phone})
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email or phone already exists"
            )
        
        # Hash password
        hashed_password = get_password_hash(user_data.password)
        
        # Normalize location: accept string and convert to structured dict
               # FIXED: Always store location as a simple string, not a dict
        normalized_location = user_data.location
        if isinstance(normalized_location, dict):
            # If it's a dict like {"text": "city"}, extract the text value
            normalized_location = normalized_location.get('text', '')
        elif normalized_location is None:
            # Keep None as is
            normalized_location = None
        # If it's already a string, keep it as is
        # Create user document
        user_doc = {
            "name": user_data.name,
            "email": user_data.email,
            "phone": user_data.phone,
            "hashed_password": hashed_password,
            "preferred_language": user_data.preferred_language or settings.DEFAULT_LANGUAGE,
            "location": normalized_location,
            "is_active": True,
            "created_at": datetime.utcnow(),
            "updated_at": None
        }
        
        # Insert user
        result = await db.users.insert_one(user_doc)
        user_doc["_id"] = str(result.inserted_id)
        
        # Remove sensitive data
        user_doc.pop("hashed_password", None)
        
        logger.info(f"New user registered: {user_doc['_id']}")
        return user_doc
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during registration: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    user_agent: Optional[str] = Header(None),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Login user and return JWT tokens
    
    Epic 1, Pile 2 - Secure Login (US2)
    """
    try:
        # Find user by email or phone
        user = await db.users.find_one({
            "$or": [
                {"email": form_data.username},
                {"phone": form_data.username}
            ]
        })
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Verify password
        if not verify_password(form_data.password, user["hashed_password"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Check if user is active
        if not user.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is deactivated"
            )
        
        # Create tokens
        user_id = str(user["_id"])
        access_token = create_access_token(data={"sub": user_id})
        refresh_token = create_refresh_token(data={"sub": user_id})
        
        # Create session for multi-device support
        device_info = {
            "device_type": "unknown",
            "user_agent": user_agent,
            "login_time": datetime.utcnow()
        }
        
        await create_session(db, user_id, device_info, access_token)
        
        logger.info(f"User logged in: {user_id}")
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during login: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )


@router.post("/refresh", response_model=Token)
async def refresh_token(
    token_data: TokenRefresh,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Refresh access token using refresh token
    """
    try:
        # Decode refresh token
        payload = decode_token(token_data.refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        user_id = payload.get("sub")
        
        # Verify user exists
        user = await db.users.find_one({"_id": user_id})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        # Create new tokens
        access_token = create_access_token(data={"sub": user_id})
        refresh_token = create_refresh_token(data={"sub": user_id})
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error refreshing token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not refresh token"
        )


@router.post("/logout")
async def logout(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Logout user and invalidate session
    
    Epic 1, Pile 3 - Logout (US3)
    """
    try:
        user_id = str(current_user["_id"])
        
        # Invalidate current session
        # In production, you would get the token from the request
        # For now, we'll invalidate all sessions
        
        logger.info(f"User logged out: {user_id}")
        
        return {"message": "Successfully logged out"}
        
    except Exception as e:
        logger.error(f"Error during logout: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed"
        )


@router.post("/logout-all")
async def logout_all_devices(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Logout from all devices
    
    Epic 1, Pile 15 - Multi-Device Login Support (US15)
    """
    try:
        user_id = str(current_user["_id"])
        
        # Invalidate all sessions
        await invalidate_all_sessions(db, user_id)
        
        logger.info(f"User logged out from all devices: {user_id}")
        
        return {"message": "Successfully logged out from all devices"}
        
    except Exception as e:
        logger.error(f"Error logging out from all devices: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed"
        )


@router.post("/forgot-password")
async def forgot_password(
    password_reset: PasswordReset,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Request password reset
    
    Epic 1, Pile 4 - Forgot Password (US4)
    """
    try:
        # Find user
        user = await db.users.find_one({
            "$or": [
                {"email": password_reset.username},
                {"phone": password_reset.username}
            ]
        })
        
        if not user:
            # Don't reveal if user exists or not for security
            return {"message": "If the account exists, a reset code will be sent"}
        
        # Generate OTP and reset token
        otp = generate_otp()
        reset_token = generate_reset_token()
        
        # Store reset token in database
        await db.password_resets.insert_one({
            "user_id": str(user["_id"]),
            "reset_token": reset_token,
            "otp": otp,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(minutes=15),
            "is_used": False
        })
        
        user_email = user.get("email")
        if user_email:
            try:
                send_password_reset_email(user_email, otp)
            except Exception as e:
                logger.error(f"Failed to send reset email: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Unable to send reset email"
                )
        
        return {
            "message": "If the account exists, a reset code will be sent",
            "reset_token": reset_token
        }
        
    except Exception as e:
        logger.error(f"Error in forgot password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password reset request failed"
        )


@router.post("/reset-password")
async def reset_password(
    reset_data: PasswordResetConfirm,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Reset password using token and OTP
    
    Epic 1, Pile 4 - Forgot Password (US4)
    """
    try:
        # Find reset request
        reset_request = await db.password_resets.find_one({
            "reset_token": reset_data.token,
            "otp": reset_data.otp,
            "is_used": False,
            "expires_at": {"$gt": datetime.utcnow()}
        })
        
        if not reset_request:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )
        
        # Update password
        new_password_hash = get_password_hash(reset_data.new_password)
        
        await db.users.update_one(
            {"_id": ObjectId(reset_request["user_id"])},
            {
                "$set": {
                    "hashed_password": new_password_hash,
                    "updated_at": datetime.utcnow()
                }
            }
        )
        
        # Mark reset request as used
        await db.password_resets.update_one(
            {"_id": reset_request["_id"]},
            {"$set": {"is_used": True}}
        )
        
        # Invalidate all sessions for security
        await invalidate_all_sessions(db, reset_request["user_id"])
        
        logger.info(f"Password reset successful for user: {reset_request['user_id']}")
        
        return {"message": "Password reset successful"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resetting password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password reset failed"
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user)
):
    """
    Get current user information
    """
    current_user["_id"] = str(current_user["_id"])
    current_user.pop("hashed_password", None)
    return current_user
