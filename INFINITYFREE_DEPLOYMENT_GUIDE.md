# InfinityFree Deployment Guide - Global POS

## ✅ Why InfinityFree?
- **100% FREE** - No credit card required
- **Unlimited bandwidth** and disk space
- **Free MySQL database** included
- **Free SSL certificate**
- **cPanel** for easy management
- Perfect for PHP applications

## 🚀 Quick Deploy (10 minutes)

### Step 1: Sign Up for InfinityFree

1. Go to https://infinityfree.net
2. Click **"Sign Up Now"**
3. Fill in:
   - Email address
   - Password
   - Choose a subdomain (e.g., `globalpos.infinityfreeapp.com`)
4. Click **"Sign Up"**
5. Verify your email

### Step 2: Create Account

1. After email verification, log in to **Client Area**
2. Click **"Create Account"**
3. Choose your subdomain or use custom domain
4. Click **"Create Account"**
5. Wait 2-5 minutes for account activation

### Step 3: Access cPanel

1. In Client Area, click **"Control Panel"** (cPanel)
2. You'll see the cPanel dashboard

### Step 4: Create MySQL Database

1. In cPanel, find **"MySQL Databases"**
2. Create database:
   - Database Name: `global_pos`
   - Click **"Create Database"**
3. Create user:
   - Username: `pos_user`
   - Password: (generate strong password)
   - Click **"Create User"**
4. Add user to database:
   - Select database and user
   - Grant **ALL PRIVILEGES**
   - Click **"Add"**
5. **Save these credentials** - you'll need them!

### Step 5: Upload Backend Files

#### Option A: File Manager (Easy)

1. In cPanel, click **"File Manager"**
2. Navigate to `htdocs` folder
3. Delete default files (index.html, etc.)
4. Click **"Upload"**
5. Upload all files from your `backend` folder:
   - `api/` folder
   - `config/` folder
   - `database/` folder
   - `models/` folder
   - `utils/` folder
   - `middleware/` folder
   - `.htaccess`
   - `index.php`
   - `health.php`

#### Option B: FTP (Faster for many files)

1. In cPanel, find **"FTP Accounts"**
2. Use the main FTP account credentials
3. Connect using FileZilla or any FTP client:
   - Host: `ftpupload.net` or your domain
   - Username: (from cPanel)
   - Password: (your account password)
   - Port: 21
4. Upload all `backend` files to `/htdocs/` folder

### Step 6: Configure Environment

1. In File Manager, navigate to `/htdocs/`
2. Find `.env` file (or create it)
3. Edit with these values:
   ```env
   APP_ENV=production
   APP_DEBUG=false
   APP_TIMEZONE=UTC
   
   # Database (from Step 4)
   DB_HOST=localhost
   DB_NAME=<your_database_name>
   DB_USER=<your_database_user>
   DB_PASSWORD=<your_database_password>
   
   # JWT
   JWT_SECRET_KEY=<generate-random-32-char-string>
   JWT_EXPIRATION=86400
   
   # CORS
   CORS_ALLOWED_ORIGINS=*
   ```

### Step 7: Import Database Schema

1. In cPanel, click **"phpMyAdmin"**
2. Select your database (`global_pos`)
3. Click **"Import"** tab
4. Click **"Choose File"**
5. Select `backend/database/schema.sql` from your computer
6. Click **"Go"**
7. Wait for import to complete

### Step 8: Test Backend

Your backend is now live at:
```
https://your-subdomain.infinityfreeapp.com
```

Test endpoints:
- Health: `https://your-subdomain.infinityfreeapp.com/health.php`
- API: `https://your-subdomain.infinityfreeapp.com/api/auth.php`

## 🎨 Deploy Frontend

### Option 1: Netlify (Recommended)

1. Build Flutter web:
   ```bash
   cd frontend
   flutter build web
   ```

2. Go to https://netlify.com
3. Drag and drop `build/web` folder
4. Done! Your frontend is live

### Option 2: Vercel

1. Build Flutter web (same as above)
2. Go to https://vercel.com
3. Import project or drag `build/web`
4. Deploy

### Option 3: GitHub Pages (Free)

1. Build Flutter web
2. Push `build/web` to GitHub repository
3. Enable GitHub Pages in repository settings
4. Your frontend is live at `username.github.io/repo-name`

## 🔧 Update API Endpoint in Frontend

After deploying backend, update frontend:

1. Open `frontend/lib/utils/api_config.dart`
2. Change:
   ```dart
   const String API_BASE_URL = 'https://your-subdomain.infinityfreeapp.com/api';
   ```
3. Rebuild and redeploy frontend

## ⚠️ InfinityFree Limitations

- **No Node.js/Python** - PHP only (perfect for your backend!)
- **Hits limit**: 50,000 hits/day (more than enough for small-medium apps)
- **File limit**: 10,000 files (you're well under this)
- **Cron jobs**: Limited (use external cron services if needed)
- **Ads**: Small banner on free plan (removable with premium)

## 💡 Tips

### Performance
- Enable **Cloudflare** in cPanel for faster loading
- Optimize images before upload
- Use caching in your PHP code

### Security
- Change default database prefix
- Use strong passwords
- Enable SSL (free with InfinityFree)
- Keep `.env` file secure

### Backup
- Regularly backup database via phpMyAdmin
- Download files via FTP
- InfinityFree provides automatic backups

## 🆙 Upgrade Options

If you outgrow free tier:
- **Premium InfinityFree**: $2.50/month (no ads, more resources)
- **HostGator**: $2.75/month (unlimited everything)
- **Hostinger**: $1.99/month (great performance)

## 🐛 Troubleshooting

### 500 Internal Server Error
- Check `.htaccess` file
- Verify file permissions (755 for folders, 644 for files)
- Check PHP error logs in cPanel

### Database Connection Failed
- Verify credentials in `.env`
- Use `localhost` as DB_HOST
- Check if database user has privileges

### API Returns 404
- Check `.htaccess` file exists
- Verify mod_rewrite is enabled (it is by default)
- Check file paths are correct

### Slow Performance
- Enable Cloudflare
- Optimize database queries
- Use caching

## 📞 Support

- InfinityFree Forum: https://forum.infinityfree.net
- Knowledge Base: https://infinityfree.net/support
- Your backend code is production-ready!

---

## Summary

✅ **Backend**: InfinityFree (free PHP hosting)
✅ **Database**: MySQL (included with InfinityFree)
✅ **Frontend**: Netlify/Vercel (free static hosting)
✅ **SSL**: Free (included)
✅ **Cost**: $0/month

Your Global POS app is now fully deployed for FREE! 🎉
