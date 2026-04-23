# InfinityFree Deployment Checklist

## ✅ Your Configuration is Ready!

### Database Connection Details:
- **Host**: sql306.infinityfree.com
- **Port**: 3306
- **Database**: if0_41638353_posys
- **Username**: if0_41638353
- **Password**: Aeb050895

---

## 📋 Deployment Steps

### Step 1: Upload Files to InfinityFree

1. **Login to cPanel** (from InfinityFree client area)
2. **Open File Manager**
3. **Navigate to `/htdocs/` folder**
4. **Delete default files** (index.html, default.php, etc.)
5. **Upload these files/folders**:
   - ✅ `api/` folder (entire folder with all PHP files)
   - ✅ `config/` folder
   - ✅ `database/` folder
   - ✅ `models/` folder
   - ✅ `utils/` folder
   - ✅ `middleware/` folder
   - ✅ `.htaccess` file
   - ✅ `index.php`
   - ✅ `health.php`
   - ✅ `.env` file (rename `.env.production` to `.env`)

### Step 2: Configure Environment

1. After uploading, **edit `.env` file** in File Manager
2. Verify these values are correct:
   ```
   DB_HOST=sql306.infinityfree.com
   DB_NAME=if0_41638353_posys
   DB_USER=if0_41638353
   DB_PASSWORD=Aeb050895
   ```

### Step 3: Import Database Schema

1. **Open phpMyAdmin** from cPanel
2. **Select database**: `if0_41638353_posys`
3. **Click "Import" tab**
4. **Choose file**: Upload `backend/database/schema.sql`
5. **Click "Go"**
6. **Wait for success message**

### Step 4: Set File Permissions

In File Manager, set permissions:
- **Folders**: 755 (api, config, database, etc.)
- **PHP Files**: 644 (all .php files)
- **.htaccess**: 644
- **.env**: 644 (but keep it secure!)

### Step 5: Test Your Backend

Your backend URL will be:
```
https://your-subdomain.infinityfreeapp.com
```

Test these endpoints:
1. **Health Check**:
   ```
   https://your-subdomain.infinityfreeapp.com/health.php
   ```
   Should return: `{"success":true,"message":"Backend is working"}`

2. **API Test**:
   ```
   https://your-subdomain.infinityfreeapp.com/api/
   ```
   Should return API info

### Step 6: Enable SSL (Free)

1. In cPanel, find **"SSL/TLS"**
2. Click **"Install SSL Certificate"**
3. InfinityFree provides free SSL automatically
4. Wait 5-10 minutes for activation

---

## 🎨 Deploy Frontend

### Option 1: Netlify (Recommended)

1. **Build Flutter web**:
   ```bash
   cd frontend
   flutter build web
   ```

2. **Update API endpoint** in `frontend/lib/utils/api_config.dart`:
   ```dart
   const String API_BASE_URL = 'https://your-subdomain.infinityfreeapp.com/api';
   ```

3. **Rebuild**:
   ```bash
   flutter build web
   ```

4. **Deploy to Netlify**:
   - Go to https://app.netlify.com
   - Drag and drop `build/web` folder
   - Done!

### Option 2: Vercel

Same process as Netlify:
1. Build Flutter web
2. Go to https://vercel.com
3. Deploy `build/web` folder

---

## 🔍 Troubleshooting

### Database Connection Error
- ✅ Use `sql306.infinityfree.com` (not `localhost`)
- ✅ Verify credentials in `.env`
- ✅ Check database exists in phpMyAdmin

### 500 Internal Server Error
- ✅ Check `.htaccess` file exists
- ✅ Verify file permissions (755/644)
- ✅ Check PHP error logs in cPanel

### API Returns 404
- ✅ Verify `.htaccess` is uploaded
- ✅ Check mod_rewrite is enabled (default on InfinityFree)
- ✅ Verify file paths are correct

### CORS Errors
- ✅ Set `CORS_ALLOWED_ORIGINS=*` in `.env`
- ✅ Check CORS headers in API responses

---

## 📊 What You Get

✅ **Backend API**: Fully functional PHP REST API
✅ **Database**: MySQL with all tables and data
✅ **SSL**: Free HTTPS certificate
✅ **Bandwidth**: Unlimited
✅ **Storage**: Unlimited
✅ **Cost**: $0/month

---

## 🚀 Next Steps After Deployment

1. **Test all API endpoints**
2. **Create admin user** via database
3. **Test frontend connection**
4. **Set up regular backups**
5. **Monitor performance**

---

## 📞 Need Help?

- InfinityFree Forum: https://forum.infinityfree.net
- Your backend is production-ready!
- All configuration files are prepared!

---

## ⚠️ Security Notes

- **Never commit `.env` to Git**
- **Change JWT_SECRET_KEY** to a unique value
- **Use strong passwords**
- **Regular backups** via phpMyAdmin
- **Monitor access logs** in cPanel

---

Your Global POS backend is ready to deploy! 🎉
