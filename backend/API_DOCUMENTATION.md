# API Documentation - Crop Disease Detection Backend

## Base URL
```
Development: http://localhost:8000/api/v1
Production: https://api.yourdomain.com/api/v1
```

## Authentication

All protected endpoints require JWT token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## 📋 Endpoints Overview

### Authentication Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/register` | Register new user | No |
| POST | `/auth/login` | Login user | No |
| POST | `/auth/refresh` | Refresh access token | No |
| POST | `/auth/logout` | Logout current session | Yes |
| POST | `/auth/logout-all` | Logout from all devices | Yes |
| POST | `/auth/forgot-password` | Request password reset | No |
| POST | `/auth/reset-password` | Reset password with OTP | No |
| GET | `/auth/me` | Get current user info | Yes |

### User Management Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/user/profile` | Get user profile | Yes |
| PATCH | `/user/profile` | Update profile | Yes |
| GET | `/user/sessions` | Get active sessions | Yes |
| DELETE | `/user/sessions/{id}` | Revoke specific session | Yes |

### Diagnosis Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/diagnosis/check-quality` | Check image quality | Yes |
| POST | `/diagnosis/` | Create diagnosis from image | Yes |
| POST | `/diagnosis/video` | Create diagnosis from video | Yes |
| GET | `/diagnosis/{id}` | Get diagnosis details | Yes |
| GET | `/diagnosis/` | List all diagnoses | Yes |

### Remediation Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/remediation/{disease_id}` | Get treatment plan | Yes |
| GET | `/remediation/healthy/guidance` | Healthy plant guidance | Yes |

### History Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/history/` | Get diagnosis history | Yes |
| DELETE | `/history/{id}` | Delete history entry | Yes |
| GET | `/history/analytics` | Get analytics | Yes |
| GET | `/history/report/{diagnosis_id}` | Download PDF report | Yes |

### Notification Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/notifications/` | Get notifications | Yes |
| GET | `/notifications/unread-count` | Get unread count | Yes |
| PATCH | `/notifications/{id}/read` | Mark as read | Yes |
| POST | `/notifications/mark-all-read` | Mark all as read | Yes |

---

## 🔐 Authentication Endpoints

### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "name": "John Farmer",
  "email": "john@example.com",
  "phone": "+919876543210",
  "password": "SecurePass123",
  "preferred_language": "en",
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "address": "Bangalore, Karnataka"
  }
}
```

**Response (201 Created):**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "John Farmer",
  "email": "john@example.com",
  "phone": "+919876543210",
  "preferred_language": "en",
  "is_active": true,
  "created_at": "2026-01-30T10:00:00Z"
}
```

### Login
```http
POST /api/v1/auth/login
Content-Type: application/x-www-form-urlencoded

username=john@example.com&password=SecurePass123
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

### Refresh Token
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Forgot Password
```http
POST /api/v1/auth/forgot-password
Content-Type: application/json

{
  "username": "john@example.com"
}
```

**Response:**
```json
{
  "message": "If the account exists, a reset code will be sent",
  "reset_token": "abc123def456..."
}
```

### Reset Password
```http
POST /api/v1/auth/reset-password
Content-Type: application/json

{
  "token": "abc123def456...",
  "otp": "123456",
  "new_password": "NewSecurePass123"
}
```

---

## 👤 User Management

### Get Profile
```http
GET /api/v1/user/profile
Authorization: Bearer <access_token>
```

### Update Profile
```http
PATCH /api/v1/user/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "John Updated",
  "preferred_language": "hi",
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946
  }
}
```

### Get Active Sessions
```http
GET /api/v1/user/sessions
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "sessions": [
    {
      "session_id": "507f1f77bcf86cd799439011",
      "device_info": {
        "device_type": "mobile",
        "user_agent": "Mozilla/5.0..."
      },
      "created_at": "2026-01-30T10:00:00Z",
      "expires_at": "2026-02-06T10:00:00Z"
    }
  ],
  "total": 1
}
```

---

## 🔬 Diagnosis Endpoints

### Check Image Quality
```http
POST /api/v1/diagnosis/check-quality
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

image=@/path/to/image.jpg
```

**Response:**
```json
{
  "is_acceptable": true,
  "blur_score": 234.56,
  "blur_threshold": 100,
  "message": "Image quality is good"
}
```

### Create Diagnosis from Image
```http
POST /api/v1/diagnosis/
Authorization: Bearer <access_token>
Accept-Language: en
Content-Type: multipart/form-data

crop_type=tomato&image=@/path/to/image.jpg
```

**Response (201 Created):**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "user_id": "507f1f77bcf86cd799439012",
  "crop_type": "tomato",
  "disease_id": "tomato_early_blight",
  "disease_name": "Early Blight",
  "confidence": 0.92,
  "severity": "medium",
  "is_healthy": false,
  "image_url": "/uploads/images/tomato_abc123.jpg",
  "heatmap_url": "/uploads/heatmaps/heatmap_def456.jpg",
  "bounding_boxes": [
    {
      "x": 100,
      "y": 150,
      "width": 200,
      "height": 180,
      "confidence": 0.92
    }
  ],
  "secondary_diagnoses": [],
  "created_at": "2026-01-30T10:00:00Z",
  "metadata": {
    "image_quality": {
      "is_acceptable": true,
      "blur_score": 234.56
    }
  }
}
```

### Create Diagnosis from Video
```http
POST /api/v1/diagnosis/video
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

crop_type=tomato&video=@/path/to/video.mp4
```

### Get Diagnosis Details
```http
GET /api/v1/diagnosis/507f1f77bcf86cd799439011
Authorization: Bearer <access_token>
```

### List All Diagnoses
```http
GET /api/v1/diagnosis/?skip=0&limit=20
Authorization: Bearer <access_token>
```

---

## 💊 Remediation Endpoints

### Get Treatment Plan
```http
GET /api/v1/remediation/tomato_early_blight?severity=medium&treatment_type=organic
Authorization: Bearer <access_token>
Accept-Language: en
```

**Query Parameters:**
- `severity`: low | medium | high | critical
- `treatment_type`: organic | chemical

**Response:**
```json
{
  "disease_id": "tomato_early_blight",
  "disease_name": "Early Blight",
  "severity": "medium",
  "treatment": {
    "type": "organic",
    "steps": [
      {
        "step_number": 1,
        "description": "Remove and destroy infected leaves immediately",
        "icon": "remove",
        "safety_warning": "Wear gloves while handling infected plants"
      },
      {
        "step_number": 2,
        "description": "Apply neem oil spray (5ml per liter of water)",
        "icon": "spray",
        "duration": "Every 7 days"
      }
    ],
    "dosage": "5ml neem oil per liter of water",
    "frequency": "Once every 7 days for 3 weeks",
    "cost_estimate": "low"
  },
  "prevention_tips": [
    "Practice crop rotation with non-solanaceous crops",
    "Ensure proper spacing between plants"
  ],
  "safety_warnings": [
    "Wear gloves while handling infected plants"
  ],
  "severity_guidance": "Start with organic treatment. If no improvement in 7 days, switch to chemical.",
  "expert_consultation_required": false
}
```

### Get Healthy Plant Guidance
```http
GET /api/v1/remediation/healthy/guidance
Authorization: Bearer <access_token>
Accept-Language: hi
```

---

## 📜 History Endpoints

### Get History with Filters
```http
GET /api/v1/history/?skip=0&limit=20&crop_type=tomato&severity=medium
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `skip`: Pagination offset (default: 0)
- `limit`: Items per page (default: 20, max: 100)
- `crop_type`: Filter by crop type
- `severity`: Filter by severity level
- `start_date`: Filter from date (ISO format)
- `end_date`: Filter to date (ISO format)
- `disease_name`: Search by disease name

**Response:**
```json
[
  {
    "_id": "507f1f77bcf86cd799439011",
    "user_id": "507f1f77bcf86cd799439012",
    "diagnosis_id": "507f1f77bcf86cd799439013",
    "crop_type": "tomato",
    "disease_name": "Early Blight",
    "confidence": 0.92,
    "severity": "medium",
    "image_url": "/uploads/images/tomato_abc123.jpg",
    "created_at": "2026-01-30T10:00:00Z"
  }
]
```

### Delete History Entry
```http
DELETE /api/v1/history/507f1f77bcf86cd799439011
Authorization: Bearer <access_token>
```

### Get Analytics
```http
GET /api/v1/history/analytics
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "total_diagnoses": 45,
  "disease_frequency": {
    "Early Blight": 15,
    "Late Blight": 10,
    "Healthy": 20
  },
  "crop_wise_trends": {
    "tomato": 30,
    "rice": 15
  },
  "severity_distribution": {
    "low": 10,
    "medium": 20,
    "high": 5,
    "healthy": 10
  },
  "monthly_trends": [
    {
      "month": "2026-01",
      "count": 45
    }
  ]
}
```

### Download PDF Report
```http
GET /api/v1/history/report/507f1f77bcf86cd799439011?include_treatment=true&include_prevention=true
Authorization: Bearer <access_token>
Accept-Language: en
```

**Response:** PDF file download

---

## 🔔 Notification Endpoints

### Get Notifications
```http
GET /api/v1/notifications/?limit=50&unread_only=true
Authorization: Bearer <access_token>
Accept-Language: en
```

**Response:**
```json
[
  {
    "_id": "507f1f77bcf86cd799439011",
    "user_id": "507f1f77bcf86cd799439012",
    "type": "diagnosis_complete",
    "title": "Diagnosis Complete",
    "message": "Your crop has been diagnosed with Early Blight. View treatment recommendations.",
    "data": {
      "diagnosis_id": "507f1f77bcf86cd799439013",
      "disease_name": "Early Blight"
    },
    "is_read": false,
    "created_at": "2026-01-30T10:00:00Z"
  }
]
```

### Get Unread Count
```http
GET /api/v1/notifications/unread-count
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "unread_count": 5
}
```

### Mark Notification as Read
```http
PATCH /api/v1/notifications/507f1f77bcf86cd799439011/read
Authorization: Bearer <access_token>
```

### Mark All as Read
```http
POST /api/v1/notifications/mark-all-read
Authorization: Bearer <access_token>
```

---

## 🌐 Multi-Language Support

Set language via:
1. **Accept-Language Header** (recommended)
   ```http
   Accept-Language: hi
   ```

2. **User Preference** (saved in profile)
   ```json
   {
     "preferred_language": "hi"
   }
   ```

Supported languages:
- `en` - English
- `hi` - Hindi (हिंदी)
- `kn` - Kannada (ಕನ್ನಡ)
- `ta` - Tamil (தமிழ்)
- `te` - Telugu (తెలుగు)
- `mr` - Marathi (मराठी)
- `bn` - Bengali (বাংলা)

---

## ❌ Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid input data"
}
```

### 401 Unauthorized
```json
{
  "detail": "Could not validate credentials"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## 📊 Rate Limiting

- Default: 60 requests per minute per IP
- Exceeded: HTTP 429 Too Many Requests

---

## 🧪 Testing with cURL

### Register and Login
```bash
# Register
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"Test123456"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=Test123456"
```

### Create Diagnosis
```bash
curl -X POST http://localhost:8000/api/v1/diagnosis/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "crop_type=tomato" \
  -F "image=@/path/to/leaf.jpg"
```

---

## 📝 Notes

- All timestamps are in UTC (ISO 8601 format)
- File uploads limited to 10MB
- Supported image formats: JPG, JPEG, PNG, HEIC
- Video formats: MP4, AVI, MOV (max 5 seconds)

---

**For interactive API documentation, visit: http://localhost:8000/docs**
