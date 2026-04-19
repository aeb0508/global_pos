# InfinityFree Deployment Guide

## 🚨 Current Issue: Connection Error

You're getting a "Failed to fetch" error because of InfinityFree's limitations.

## 📋 Quick Fix Steps

### 1. Test Your Backend
Visit these URLs in your browser:

```
https://posys.ct.ws/backend/index.php
https://posys.ct.ws/backend/api/test.php
https://posys.ct.ws/backend/api/auth.php
```

### 2. Check File Structure on InfinityFree

Your files should be in: `/htdocs/` or `/public_html/`

```
htdocs/
├── backend/
│   ├── api/
│   │   ├── orders.php
│   │   ├── auth.php
│   │   ├── test.php
│   │   └── ...
│   ├── config/
│   ├── .env
│   └── .htaccess
└── (frontend files if hosting together)
```

### 3. Common InfinityFree Issues

#### Issue 1: 403 Forbidden Error
**Cause**: File permissions or .htaccess blocking access

**Fix**:
- Set folder permissions to 755
- Set file permissions to 644
- Check .htaccess isn't blocking requests

#### Issue 2: 500 Internal Server Error
**Cause**: PHP errors or missing extensions

**Fix**:
- Check error logs in InfinityFree control panel
- Verify PHP version is 7.4+ (InfinityFree uses 8.x)
- Ensure all required extensions are available

#### Issue 3: Database Connection Failed
**Cause**: Wrong credentials or remote access blocked

**Fix**:
- Use InfinityFree's database hostname: `sql306.infinityfree.com`
- Database name format: `if0_XXXXX_dbname`
- Username format: `if0_XXXXX`
- Only connect from same server (no remote access)

#### Issue 4: CORS Errors
**Cause**: Headers not being sent properly

**Fix**: Already handled in `_bootstrap.php`

### 4. Update Your .env File

Make sure your `.env` has the correct InfinityFree credentials:

```env
DB_HOST=sql306.infinityfree.com
DB_NAME=if0_41638353_posys
DB_USER=if0_41638353
DB_PASSWORD=Aeb050895
```

### 5. Verify Database Import

1. Go to InfinityFree Control Panel
2. Open phpMyAdmin
3. Select your database: `if0_41638353_posys`
4. Check if tables exist:
   - users
   - products
   - orders
   - customers
   - categories
   - stores
   - etc.

If tables are missing, import `backend/database/schema.sql`

### 6. Test API Endpoints

#### Test 1: Health Check
```bash
curl https://posys.ct.ws/backend/index.php
```

Expected response:
```json
{"status":"ok","message":"Global POS API is running"}
```

#### Test 2: Diagnostic Test
```bash
curl https://posys.ct.ws/backend/api/test.php
```

Should show PHP info and database connection status.

#### Test 3: Login
```bash
curl -X POST https://posys.ct.ws/backend/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"action":"login","username":"admin","password":"admin123"}'
```

Expected response:
```json
{
  "success": true,
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {...}
}
```

## 🔧 InfinityFree Limitations

### What Works:
✅ PHP 8.x
✅ MySQL databases
✅ File uploads (limited size)
✅ Basic API endpoints
✅ CORS headers

### What Doesn't Work:
❌ Cron jobs (use external services)
❌ Long-running scripts (30s timeout)
❌ Large file uploads (>5MB)
❌ High traffic (throttled)
❌ Email sending (use external SMTP)
❌ WebSockets
❌ Remote database access

## 🚀 Alternative: Use Better Hosting

InfinityFree is free but has many limitations. Consider:

### Recommended Alternatives:

1. **Railway** ($5-10/month)
   - Better performance
   - No throttling
   - Built-in MySQL
   - Easy deployment
   - See: `QUICK_START_RAILWAY.md`

2. **DigitalOcean** ($6/month)
   - Full control
   - Better reliability
   - SSH access

3. **Hostinger** ($2-4/month)
   - Good shared hosting
   - Better than InfinityFree
   - Fewer limitations

## 📝 Debugging Steps

### Step 1: Enable Error Reporting
Already done in `_bootstrap.php`

### Step 2: Check PHP Error Logs
In InfinityFree control panel:
- Go to "Error Logs"
- Look for recent errors
- Share errors for help

### Step 3: Test Database Connection
Visit: `https://posys.ct.ws/backend/api/test.php`

This will show:
- PHP version
- Available extensions
- Database connection status

### Step 4: Check File Permissions
In FileZilla or File Manager:
- Folders: 755
- PHP files: 644
- .env file: 644 (but not publicly accessible)

### Step 5: Verify .htaccess
Make sure `.htaccess` files are uploaded and not renamed.

## 🎯 Next Steps

1. **Test the backend**: Visit `https://posys.ct.ws/backend/api/test.php`
2. **Check the response**: Share any errors you see
3. **Verify database**: Make sure tables are imported
4. **Test login**: Try the auth endpoint
5. **Update frontend**: Make sure it points to correct URL

## 💡 Quick Fix for Your Current Error

The "Failed to fetch" error means the backend isn't responding. Most likely:

1. **Files not uploaded correctly**
   - Re-upload the entire `backend` folder
   - Make sure `.htaccess` files are included

2. **Database not configured**
   - Import `schema.sql` in phpMyAdmin
   - Verify credentials in `.env`

3. **PHP errors**
   - Check error logs
   - Visit test.php to see errors

4. **Wrong URL**
   - Frontend should use: `https://posys.ct.ws/backend/api`
   - Not: `https://posys.ct.ws/api`

## 📞 Need Help?

Share the output of:
1. `https://posys.ct.ws/backend/index.php`
2. `https://posys.ct.ws/backend/api/test.php`
3. Any error logs from InfinityFree control panel

This will help diagnose the exact issue.
