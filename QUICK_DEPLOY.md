# 🚀 Quick Deployment Guide

## 1️⃣ Cleanup (2 minutes)
```bash
cleanup.bat
```
This removes 4 test files.

## 2️⃣ Update Config (5 minutes)
**File:** `frontend/lib/utils/api_config.dart`
```dart
// Line 9: Change this
static const String _productionUrl = 'https://YOUR-DOMAIN.com/backend/api';
```

## 3️⃣ Environment Variables (3 minutes)
Create `backend/.env`:
```env
DB_HOST=your-host
DB_NAME=global_pos
DB_USER=your-user
DB_PASS=your-password
JWT_SECRET=random-64-char-string
```

## 4️⃣ Deploy Backend (10 minutes)
1. Upload `backend/` folder
2. Create `uploads/` directory (chmod 777)
3. Import `backend/database/schema.sql`
4. Test: `https://your-domain.com/backend/api/auth.php`

## 5️⃣ Deploy Frontend (10 minutes)
```bash
cd frontend
flutter build web --release
```
Upload `build/web/` contents to web server.

## 6️⃣ First Login (2 minutes)
1. Login: `admin` / `admin123`
2. **IMMEDIATELY** change password
3. Update email from `admin@globalpos.com`

## ✅ Done!

---

## 📋 Default Data Included
- 8 product categories
- 1 store (Main Store)
- 1 tax rate (10%)
- 1 currency (USD)
- 1 admin user

---

## 🆘 Troubleshooting

**Can't login?**
- Check database imported correctly
- Verify API URL is correct
- Check browser console for errors

**API not working?**
- Verify `.env` file exists
- Check database credentials
- Test API endpoint directly

**Images not uploading?**
- Check `uploads/` directory exists
- Verify write permissions (777)

---

## 📚 Full Documentation
- `AUDIT_SUMMARY.md` - Complete audit report
- `CLEANUP_REPORT.md` - Detailed findings
- `DEPLOYMENT_CHECKLIST.md` - Step-by-step guide
- `README.md` - System documentation

---

**Total Time:** ~30 minutes  
**Difficulty:** Easy  
**Status:** Production Ready ✅
