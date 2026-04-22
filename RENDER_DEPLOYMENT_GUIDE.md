# Render Deployment Guide - Global POS

## Why Render?
- ✅ Free tier available
- ✅ Automatic HTTPS
- ✅ Easy database setup
- ✅ Better PHP support than Railway
- ✅ Simple configuration

## Quick Deploy (5 minutes)

### Step 1: Sign Up
1. Go to https://render.com
2. Sign up with GitHub
3. Authorize Render to access your repositories

### Step 2: Deploy Backend

1. Click **"New +"** → **"Web Service"**
2. Connect your `global_pos` repository
3. Configure:
   - **Name**: `globalpos-backend`
   - **Region**: Choose closest to you
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Environment**: `Docker`
   - **Instance Type**: `Free`

4. Add Environment Variables:
   ```
   APP_ENV=production
   APP_DEBUG=false
   JWT_SECRET_KEY=<generate-random-string>
   CORS_ALLOWED_ORIGINS=*
   ```

5. Click **"Create Web Service"**

### Step 3: Create Database

1. Click **"New +"** → **"PostgreSQL"** (or MySQL if available)
2. Configure:
   - **Name**: `globalpos-db`
   - **Database**: `global_pos`
   - **User**: `pos_user`
   - **Region**: Same as backend
   - **Instance Type**: `Free`

3. Click **"Create Database"**

### Step 4: Connect Database to Backend

1. Go to your backend service
2. Click **"Environment"**
3. Add database variables:
   ```
   DB_HOST=<from-database-internal-url>
   DB_PORT=5432
   DB_NAME=global_pos
   DB_USER=pos_user
   DB_PASSWORD=<from-database>
   ```

4. Service will auto-redeploy

### Step 5: Initialize Database

1. Connect to database using Render's shell or external client
2. Run: `backend/database/schema.sql`

### Step 6: Test Backend

Your backend will be available at:
```
https://globalpos-backend.onrender.com
```

Test health endpoint:
```
https://globalpos-backend.onrender.com/health.php
```

## Deploy Frontend (Flutter Web)

### Option A: Render Static Site

1. Build Flutter web locally:
   ```bash
   cd frontend
   flutter build web
   ```

2. Deploy `build/web` folder as static site on Render

### Option B: Netlify/Vercel (Recommended for Flutter)

Flutter web works better on these platforms:
- Netlify: https://netlify.com
- Vercel: https://vercel.com

## Troubleshooting

### Backend not responding
- Check Deploy Logs in Render dashboard
- Verify environment variables are set
- Check database connection

### Database connection failed
- Use internal database URL (not external)
- Verify database is in same region as backend
- Check credentials

## Cost

- **Free Tier Limits**:
  - Backend: 750 hours/month
  - Database: 90 days free, then $7/month
  - Sleeps after 15 min inactivity (wakes on request)

## Alternative: InfinityFree

For completely free hosting:
1. Backend: InfinityFree.net (free PHP hosting)
2. Database: Included with InfinityFree
3. Frontend: Netlify (free static hosting)

See INFINITYFREE_DEPLOYMENT_GUIDE.md for details.
