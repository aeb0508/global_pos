# 🗑️ Database Cleanup Guide - Remove Test Products

## Quick Cleanup (Recommended)

### Option 1: Automated Script (Windows)
```bash
cleanup_database.bat
```
This will:
1. Backup your database automatically
2. Remove all test products
3. Clean orphaned records

### Option 2: Manual SQL (Any Platform)

1. **Backup first:**
```bash
mysqldump -u root -p global_pos > backup.sql
```

2. **Run cleanup script:**
```bash
mysql -u root -p global_pos < backend/database/cleanup_test_data.sql
```

---

## What Will Be Removed

### Test Products Visible in Screenshots:
- ✅ "test prod" (120.00 DHs)
- ✅ "test prod 2" (120.00 DHs)
- ✅ "test cat" products
- ✅ Any other products with "test" in the name

### Related Data:
- Test categories
- Test customers
- Test orders
- Orphaned inventory records

---

## Manual Cleanup (If Scripts Don't Work)

### Using phpMyAdmin or MySQL Workbench:

1. **Remove test products:**
```sql
DELETE FROM products 
WHERE name LIKE '%test%' 
   OR name = 'test prod'
   OR name = 'test prod 2'
   OR name = 'test cat';
```

2. **Verify removal:**
```sql
SELECT * FROM products WHERE name LIKE '%test%';
```

3. **Clean orphaned records:**
```sql
DELETE FROM order_items 
WHERE product_id NOT IN (SELECT id FROM products);

DELETE FROM inventory_logs 
WHERE product_id NOT IN (SELECT id FROM products);
```

---

## Using the Application

### Delete Products Manually:
1. Open Products screen
2. Click on each test product
3. Click the delete button (trash icon)
4. Confirm deletion

This is safer but slower for multiple products.

---

## Verification

After cleanup, verify:

1. **Check product count:**
```sql
SELECT COUNT(*) FROM products;
```

2. **Search for remaining test data:**
```sql
SELECT * FROM products WHERE name LIKE '%test%';
```

3. **Refresh your app** - Test products should be gone

---

## Rollback (If Something Goes Wrong)

If you backed up before cleanup:

```bash
mysql -u root -p global_pos < backup.sql
```

---

## Safety Notes

✅ **Always backup before cleanup**
✅ **Test on development first**
✅ **Verify real data is intact after cleanup**
⚠️ **Cannot undo without backup**

---

## Alternative: Keep Test Products

If you want to keep some test products for demo purposes:

1. Rename them to something obvious like "DEMO Product"
2. Move them to a "Demo" category
3. Mark them as inactive if your system supports it

---

## Files Created

- `backend/database/cleanup_test_data.sql` - SQL cleanup script
- `cleanup_database.bat` - Automated cleanup with backup
- `DATABASE_CLEANUP_GUIDE.md` - This guide

---

## Quick Commands Reference

```bash
# Backup
mysqldump -u root -p global_pos > backup.sql

# Cleanup
mysql -u root -p global_pos < backend/database/cleanup_test_data.sql

# Restore
mysql -u root -p global_pos < backup.sql

# Verify
mysql -u root -p global_pos -e "SELECT COUNT(*) FROM products;"
```

---

## Need Help?

If cleanup fails:
1. Check MySQL is running
2. Verify database credentials
3. Check backup was created
4. Try manual deletion via phpMyAdmin
5. Contact support with error message

---

**Status:** Ready to clean test data  
**Risk Level:** Low (with backup)  
**Time Required:** 2-5 minutes
