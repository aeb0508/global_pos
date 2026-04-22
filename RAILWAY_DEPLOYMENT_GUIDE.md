# Railway Deployment Guide - Global POS

This guide walks you through deploying the Global POS application to Railway with both backend API and Flutter web frontend.

## Overview

**Global POS** is deployed as multiple services on Railway:
- **Backend**: PHP REST API running on Apache
- **Frontend**: Flutter Web application serving static files
- **Database**: MySQL 8.0 for data persistence

---

## Prerequisites

- Railway account (https://railway.app)
- GitHub account with your repository
- Your code pushed to GitHub main branch
- Basic understanding of environment variables

---

## Step 1: Prepare Your Repository

Ensure these files exist in your repository:

```
root/
├── railway.json                 # Service configuration
├── backend/
│   ├── Dockerfile              # PHP Apache image config
│   ├── index.php               # Health check endpoint
│   ├── .htaccess               # URL routing
│   ├── api/
│   │   ├── _bootstrap.php      # API initialization
│   │   ├── auth.php            # Authentication
│   │   └── ... (other API endpoints)
│   ├── config/
│   │   ├── Config.php          # Environment config loader
│   │   └── Database.php        # Database connection
│   └── database/
│       └── schema.sql          # Database schema
└── frontend/
    ├── nixpacks.toml           # Flutter build config
    ├── lib/
    │   ├── main.dart
    │   └── utils/
    │       └── api_config.dart # API endpoint config
    └── pubspec.yaml            # Flutter dependencies
```

All files are already in place. Verify with:
```bash
git log --oneline | head -5
```

---

## Step 2: Set Up Railway Project

### 2.1 Create New Project

1. Go to [railway.app](https://railway.app)
2. Click **"New Project"**
3. Select **"Deploy from GitHub"**
4. Authenticate with GitHub
5. Select your `global_pos` repository
6. Choose **main** branch

### 2.2 Railway Will Auto-Detect Services

Based on `railway.json`, it will create:
- Backend service (PHP)
- Frontend service (Flutter)
- MySQL service (Database)

---

## Step 3: Configure Environment Variables

Once services are created, set variables in Railway Dashboard.

### Backend Environment Variables

Go to **Backend Service → Variables**

```env
# App Configuration
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=UTC
APP_NAME=Global POS

# Database (Railway will provide these)
DB_HOST=mysql.railway.internal
DB_PORT=3306
DB_NAME=global_pos
DB_USER=pos_user
DB_PASSWORD=your-random-password-here

# JWT Security
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRATION=86400

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://your-frontend-url.up.railway.app
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS

# File Upload
UPLOAD_MAX_SIZE=52428800
UPLOAD_ALLOWED_TYPES=jpg,jpeg,png,gif,pdf

# Company Info
COMPANY_NAME=Your Company Name
COMPANY_EMAIL=company@example.com
COMPANY_PHONE=+1-555-0123
```

### MySQL Environment Variables

Go to **MySQL Service → Variables**

```env
MYSQL_ROOT_PASSWORD=root-password-here
MYSQL_DATABASE=global_pos
MYSQL_USER=pos_user
MYSQL_PASSWORD=pos-user-password-here
```

### Frontend Environment Variables

Go to **Frontend Service → Build Variables**

The frontend reads API endpoint from code. After backend deploys:

1. Get your backend URL from Railway Dashboard
   - Format: `https://backend-service-name.up.railway.app`
2. Update [frontend/lib/utils/api_config.dart](frontend/lib/utils/api_config.dart):

```dart
// For production (Railway)
const String API_BASE_URL = 'https://your-backend-url.up.railway.app/backend/api';
```

3. Commit and push:
```bash
git add frontend/lib/utils/api_config.dart
git commit -m "Update API endpoint for Railway production"
git push origin main
```

Railway will auto-trigger a redeploy.

---

## Step 4: Initialize Database

Once MySQL and Backend services are running:

### Option A: Via Railway CLI (Recommended)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Navigate to project
railway link <PROJECT_ID>

# Run database schema
cat backend/database/schema.sql | railway run mysql --cli
```

### Option B: Manual SSH

1. Go to MySQL service → Connect
2. Copy the connection string
3. Connect locally:
```bash
mysql -h <host> -u pos_user -p -D global_pos < backend/database/schema.sql
```

### Option C: Via PHP Script (After Deployment)

The backend includes a restore utility. Call it from browser:
```
https://your-backend.up.railway.app/backend/api/backup_restore.php
```

---

## Step 5: Deploy

### Auto-Deploy (Default)

Railway automatically deploys when you push to main branch:

```bash
git add .
git commit -m "Deploy to Railway"
git push origin main
```

Monitor deployment in Railway Dashboard:
- **Backend Service** → Build logs
- **Frontend Service** → Build logs
- **MySQL Service** → Status

### Manual Deploy

Or trigger manually in Dashboard:
1. Go to service
2. Click three dots (⋯)
3. Select **"Redeploy"**

---

## Step 6: Verify Deployment

### Backend Health Check

```bash
curl https://your-backend.up.railway.app/backend/health.php
```

Expected response:
```json
{
  "status": "OK",
  "database": "Connected"
}
```

### Frontend Access

Open in browser:
```
https://your-frontend.up.railway.app
```

### Test API Connection

Login with a test user:
1. Go to frontend
2. Enter credentials
3. Check browser console (F12) for API calls
4. Verify no CORS errors

---

## Environment-Specific Configuration

### Your Backend Supports Multiple Environments

In [backend/config/Config.php](backend/config/Config.php), you can define environment-specific settings:

```php
// Local development
const LOCAL_DB_HOST = 'localhost';
const LOCAL_DB_NAME = 'global_pos';

// Production (Railway)
const PROD_DB_HOST = 'mysql.railway.internal';
const PROD_DB_NAME = 'global_pos';
```

Railway uses `APP_ENV=production`, so it will use PROD settings automatically.

---

## Troubleshooting

### 1. Frontend Shows 404

**Problem**: Blank page or 404 errors

**Solution**:
```bash
# Check if build succeeded
# In Railway Dashboard → Frontend Service → Build logs

# Rebuild manually
git add .
git commit -m "Trigger rebuild"
git push origin main
```

### 2. API Returns 403 Forbidden

**Problem**: CORS errors in browser console

**Solution**:
```env
# In Railway Dashboard → Backend → Variables
# Update CORS_ALLOWED_ORIGINS to match frontend URL
CORS_ALLOWED_ORIGINS=https://your-frontend-url.up.railway.app
```

Then redeploy backend.

### 3. Cannot Connect to Database

**Problem**: "SQLSTATE[HY000]: General error: 2002 No such file or directory"

**Solution**:
1. Verify MySQL service is running
2. Check database credentials match in .env
3. In backend variables, use:
   ```env
   DB_HOST=mysql.railway.internal
   ```

### 4. JWT Token Errors

**Problem**: "Invalid token" or "Token expired"

**Solution**:
- Ensure same `JWT_SECRET_KEY` on backend
- Check system time is synced
- Verify `JWT_EXPIRATION` (default 86400 = 24 hours)

### 5. Deployment Stuck

**Problem**: Service shows "Building..." for hours

**Solution**:
1. Go to service → Build logs
2. Check for errors
3. Cancel build:
   ```bash
   railway service cancel
   ```
4. Push a new commit to trigger fresh build

---

## Performance Tips

### Database Optimization

Add indexes for frequently queried fields:
```sql
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_order_status ON orders(status);
CREATE INDEX idx_product_barcode ON products(barcode);
```

### Caching

Update API responses with cache headers:
```php
header('Cache-Control: public, max-age=3600');
```

### Image Optimization

Compress product images before upload:
- Max size: 2MB
- Format: JPG/PNG
- Dimensions: 1024x1024px

---

## Scaling

### Increase Resources

In Railway Dashboard:
1. Click service
2. Settings → Compute
3. Increase RAM/CPU

Recommended:
- **Backend**: 512MB RAM, 1 CPU
- **Frontend**: 256MB RAM, 0.5 CPU
- **MySQL**: 1GB RAM, shared CPU

### Database Backups

Railway auto-backs up MySQL. Download backups:
1. MySQL Service → Data
2. Click backup
3. Download SQL file

---

## Monitoring

### Logs

View live logs in Railway:
1. Service → Logs tab
2. Filter by error level
3. Search by keyword

### Metrics

Monitor performance:
1. Service → Metrics
2. View CPU, Memory, Network usage
3. Set alerts for high usage

---

## Next Steps

1. **SSL Certificate**: Railway provides HTTPS automatically ✓
2. **Custom Domain**: Settings → Domains
3. **Environment-Specific Secrets**: Use Railway's secret management
4. **CI/CD**: GitHub actions integrate with Railway
5. **API Documentation**: Document endpoints in `/docs`

---

## Support

- **Railway Docs**: https://docs.railway.app
- **Your Project**: Check backend API docs at `/backend/api/`
- **Community**: Railway Discord: https://discord.railway.app

---

## Quick Reference

### Common Commands

```bash
# Push to deploy
git push origin main

# View logs locally
railway logs -s backend
railway logs -s mysql

# SSH into service
railway shell -s backend

# Run one-off command
railway run php -v
```

### File Locations

| File | Purpose |
|------|---------|
| `railway.json` | Service configuration |
| `backend/Dockerfile` | PHP image setup |
| `backend/.env` | Backend config (generated from vars) |
| `frontend/nixpacks.toml` | Flutter build config |
| `backend/database/schema.sql` | Database schema |

---

**Last Updated**: April 2026
**Status**: Production Ready ✓
