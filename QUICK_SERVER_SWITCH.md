# Quick Server Switch Guide

## Current Configuration ✅

**Production (Default)**: `https://posys.ct.ws/backend/api`  
**Localhost (Dev)**: `http://localhost/backend/api`

## How to Switch

### Option 1: Automatic (Recommended)
The app automatically detects:
- **Localhost**: When running on `http://localhost` or `http://127.0.0.1`
- **Production**: When running anywhere else (deployed, mobile, etc.)

### Option 2: Manual Override (Via App Settings)
1. Open the app
2. Navigate to Settings
3. Find "Custom Server URL" field
4. Enter your desired URL
5. Save

To revert to automatic detection, clear the custom URL field.

## Quick Commands

### Test Localhost
```bash
# Run Flutter web on localhost
cd frontend
flutter run -d chrome
# App will use: http://localhost/backend/api
```

### Test Production
```bash
# Build for production
cd frontend
flutter build web --release
# Deploy to server
# App will use: https://posys.ct.ws/backend/api
```

### Check Current Server
Look for console logs or check `ApiConfig.currentEnvironment` in code.

## File to Edit

If you need to change URLs permanently:
- **File**: `frontend/lib/utils/api_config.dart`
- **Lines**: 5-9

```dart
// Development/Local URL (for testing)
static const String _localUrl = 'http://localhost/backend/api';

// Production URL (Infinity hosting)
static const String _productionUrl = 'https://posys.ct.ws/backend/api';
```

## Common Scenarios

### Scenario 1: Development
- Run on localhost
- Backend: XAMPP on localhost
- URL used: `http://localhost/backend/api`

### Scenario 2: Production
- Deployed to Infinity
- Backend: Infinity server
- URL used: `https://posys.ct.ws/backend/api`

### Scenario 3: Testing on Mobile
- Mobile app installed
- Backend: Infinity server
- URL used: `https://posys.ct.ws/backend/api`

### Scenario 4: Custom Testing
- Set custom URL in app settings
- Backend: Any server
- URL used: Your custom URL

## Troubleshooting

**Problem**: App not connecting  
**Solution**: Check if backend server is running and accessible

**Problem**: CORS errors  
**Solution**: Configure CORS headers on backend

**Problem**: Want to force localhost  
**Solution**: Run app on `http://localhost:port`

**Problem**: Want to force production  
**Solution**: Run app on any domain except localhost

## Notes

- ✅ No code changes needed to switch between localhost and production
- ✅ Localhost is automatically detected
- ✅ Production is the default for all deployments
- ✅ Custom URL can override both
