# 🚀 Production Deployment Checklist

## Pre-Deployment Tasks

### 1. Clean Test Files
- [ ] Run `cleanup.bat` to remove all test files
- [ ] Verify test files are deleted:
  - `POS Login Test.html`
  - `backend/login-test.html`
  - `backend/test_permissions.html`
  - `backend/api/permissions_test.php`

### 2. Update Configuration Files

#### Backend Configuration
- [ ] Update `frontend/lib/utils/api_config.dart`:
  ```dart
  static const String _productionUrl = 'https://YOUR-DOMAIN.com/backend/api';
  ```

#### Environment Variables
Create `.env` file in `backend/` directory:
```env
DB_HOST=your-database-host
DB_NAME=global_pos
DB_USER=your-database-user
DB_PASS=your-secure-password
JWT_SECRET=your-random-secret-key-here
```

- [ ] Set `DB_HOST` to production database host
- [ ] Set `DB_NAME` to your database name
- [ ] Set `DB_USER` to database username
- [ ] Set `DB_PASS` to strong database password
- [ ] Generate and set `JWT_SECRET` (use random 64+ character string)

### 3. Database Setup
- [ ] Create production database
- [ ] Import `backend/database/schema.sql`
- [ ] Verify tables created successfully
- [ ] Check default admin user exists

### 4. Customize Default Data (Optional)
Edit `backend/database/schema.sql` before importing:
- [ ] Update store name and address
- [ ] Modify default categories if needed
- [ ] Adjust default tax rate
- [ ] Change default currency if needed

### 5. Security Review
- [ ] Ensure `.env` file is NOT in version control
- [ ] Add `.env` to `.gitignore`
- [ ] Remove `backend/database/reset_admin_password.sql` from production
- [ ] Verify all API endpoints require authentication
- [ ] Check CORS settings are properly configured

---

## Deployment Steps

### Backend Deployment
1. [ ] Upload `backend/` folder to server
2. [ ] Set proper file permissions (755 for directories, 644 for files)
3. [ ] Create `uploads/` directory with write permissions (777)
4. [ ] Verify PHP version >= 7.4
5. [ ] Test database connection
6. [ ] Test API endpoint: `https://your-domain.com/backend/api/auth.php`

### Frontend Deployment
1. [ ] Build Flutter web app:
   ```bash
   cd frontend
   flutter build web --release
   ```
2. [ ] Upload `build/web/` contents to web server
3. [ ] Configure web server (nginx/apache)
4. [ ] Test frontend loads correctly
5. [ ] Verify API calls work

---

## Post-Deployment Tasks

### 1. First Login & Security
- [ ] Login with default credentials: `admin` / `admin123`
- [ ] **IMMEDIATELY** change admin password
- [ ] Update admin email from `admin@globalpos.com`
- [ ] Create additional user accounts as needed

### 2. System Configuration
- [ ] Configure store information
- [ ] Set up tax rates for your region
- [ ] Configure currency settings
- [ ] Enable/disable features as needed
- [ ] Set up user roles and permissions

### 3. Testing
- [ ] Test user login/logout
- [ ] Test product creation
- [ ] Test order processing
- [ ] Test payment methods
- [ ] Test reports generation
- [ ] Test on mobile devices
- [ ] Test on different browsers

### 4. SSL & Security
- [ ] Verify HTTPS is enabled
- [ ] Check SSL certificate is valid
- [ ] Test mixed content warnings
- [ ] Verify secure cookie settings

### 5. Backup Setup
- [ ] Configure automated database backups
- [ ] Test backup restoration
- [ ] Document backup procedures
- [ ] Set up monitoring/alerts

---

## Verification Checklist

### Functionality
- [ ] Users can login successfully
- [ ] Products can be created/edited
- [ ] Orders can be processed
- [ ] Reports are generated correctly
- [ ] Images upload successfully
- [ ] Search functionality works
- [ ] Filters work correctly

### Security
- [ ] No test files accessible
- [ ] Default password changed
- [ ] Database credentials secure
- [ ] API requires authentication
- [ ] HTTPS enforced
- [ ] No sensitive data in logs

### Performance
- [ ] Page load times acceptable
- [ ] API response times good
- [ ] Images load properly
- [ ] No console errors
- [ ] Mobile performance good

---

## Rollback Plan

If issues occur:
1. [ ] Keep backup of previous version
2. [ ] Document rollback steps
3. [ ] Test rollback procedure
4. [ ] Have database backup ready

---

## Support & Maintenance

### Regular Tasks
- [ ] Monitor error logs
- [ ] Check database size
- [ ] Review user activity
- [ ] Update dependencies
- [ ] Apply security patches

### Documentation
- [ ] Document custom configurations
- [ ] Keep admin credentials secure
- [ ] Maintain deployment notes
- [ ] Update user guides

---

## Emergency Contacts

- **System Admin:** _________________
- **Database Admin:** _________________
- **Hosting Support:** _________________
- **Developer:** _________________

---

## Notes

_Add any deployment-specific notes here_

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Version:** _______________

---

✅ **Deployment Complete!**

Remember to:
- Change default admin password immediately
- Set up regular backups
- Monitor system logs
- Keep software updated
