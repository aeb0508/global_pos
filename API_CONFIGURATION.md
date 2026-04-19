# API Configuration Guide

## Overview
The app is configured to automatically connect to the appropriate backend server based on the environment.

## Server URLs

### Production (Default)
- **URL**: `https://posys.ct.ws/backend/api`
- **Used when**: App is deployed to production or accessed from any non-localhost domain
- **Purpose**: Main production server hosted on Infinity

### Development (Localhost)
- **URL**: `http://localhost/backend/api`
- **Used when**: Running on localhost (127.0.0.1) during development
- **Purpose**: Local testing and development

### Custom Server (Optional)
- **URL**: Configurable via Settings screen in the app
- **Used when**: User sets a custom server URL in app settings
- **Purpose**: Testing with different servers or custom deployments

## How It Works

The app automatically detects which server to use:

1. **Priority 1 - Custom URL**: If set in app settings, this is used first
2. **Priority 2 - Localhost Detection**: If running on localhost, uses local backend
3. **Priority 3 - Production**: Default for all other cases (mobile apps, deployed web)

## Configuration File

Location: `frontend/lib/utils/api_config.dart`

```dart
// Production URL (Infinity hosting)
static const String _productionUrl = 'https://posys.ct.ws/backend/api';

// Development/Local URL (for testing)
static const String _localUrl = 'http://localhost/backend/api';
```

## Switching Between Environments

### For Development (Localhost)
1. Run the app on `http://localhost` or `http://127.0.0.1`
2. The app will automatically use the local backend

### For Production (Infinity)
1. Deploy the app to your production domain
2. The app will automatically use `https://posys.ct.ws/backend/api`

### For Custom Server
1. Open the app
2. Go to Settings
3. Enter your custom server URL
4. The app will use this URL until you clear it

## Testing the Configuration

You can check which environment is active by looking at the console logs or by checking the `ApiConfig.currentEnvironment` property:

- `"Development (Localhost)"` - Using localhost
- `"Production (Infinity)"` - Using Infinity server
- `"Custom: [URL]"` - Using custom server

## Updating Production URL

If you need to change the production URL (e.g., new domain):

1. Open `frontend/lib/utils/api_config.dart`
2. Update the `_productionUrl` constant:
   ```dart
   static const String _productionUrl = 'https://your-new-domain.com/backend/api';
   ```
3. Rebuild and redeploy the app

## Important Notes

- ✅ **Localhost is hidden**: Only used when explicitly running on localhost
- ✅ **Production is default**: All deployed apps use Infinity by default
- ✅ **Mobile apps**: Always use production URL
- ✅ **Custom URL**: Can be set per-device via app settings
- ⚠️ **CORS**: Ensure your backend allows requests from your frontend domain
- ⚠️ **HTTPS**: Production should always use HTTPS for security

## Troubleshooting

### App not connecting to server
1. Check your internet connection
2. Verify the backend server is running
3. Check browser console for CORS errors
4. Verify the URL in `api_config.dart` is correct

### Want to test with localhost
1. Run the app on `http://localhost:port`
2. Ensure backend is running on `http://localhost/backend/api`
3. Check that XAMPP/Apache is running

### Want to use a different production server
1. Update `_productionUrl` in `api_config.dart`, OR
2. Use the custom server URL feature in app settings

## Security Recommendations

1. **Always use HTTPS** in production
2. **Never commit** sensitive credentials to the repository
3. **Use environment variables** for sensitive configuration (if needed)
4. **Enable CORS** properly on your backend
5. **Keep localhost URL** for development only

## Backend Requirements

Your backend server must:
- Be accessible at the configured URL
- Have proper CORS headers configured
- Support all API endpoints listed in `api_config.dart`
- Use HTTPS in production

## Support

For issues or questions:
- Check the backend logs
- Verify network connectivity
- Test API endpoints with Postman/curl
- Review browser console for errors
