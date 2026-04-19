# 🚀 Quick Reference Card

## 📡 Server URLs

| Environment | URL | Auto-Detected |
|------------|-----|---------------|
| **Production** | `https://posys.ct.ws/backend/api` | ✅ Default |
| **Localhost** | `http://localhost/backend/api` | ✅ When on localhost |
| **Custom** | Set in app settings | ⚙️ Manual |

## 🔧 Configuration File

**Location**: `frontend/lib/utils/api_config.dart`

```dart
// Production (Default)
static const String _productionUrl = 'https://posys.ct.ws/backend/api';

// Localhost (Dev only)
static const String _localUrl = 'http://localhost/backend/api';
```

## 🏗️ Build Commands

### Development
```bash
cd frontend
flutter run -d chrome
# Uses: http://localhost/backend/api
```

### Production
```bash
cd frontend
flutter build web --release
# Uses: https://posys.ct.ws/backend/api
```

## 📱 Responsive Screens

| Screen | Mobile | Desktop |
|--------|--------|---------|
| Orders | ✅ Vertical | ✅ Horizontal |
| Pending Orders | ✅ Vertical | ✅ Horizontal |
| Products | ✅ Grid | ✅ Grid |
| POS | ✅ Responsive | ✅ Responsive |

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [API_CONFIGURATION.md](API_CONFIGURATION.md) | Complete configuration guide |
| [QUICK_SERVER_SWITCH.md](QUICK_SERVER_SWITCH.md) | Switch between servers |
| [PRODUCTION_DEPLOYMENT_CHECKLIST.md](PRODUCTION_DEPLOYMENT_CHECKLIST.md) | Deployment steps |
| [CONFIGURATION_COMPLETE.md](CONFIGURATION_COMPLETE.md) | Summary of changes |

## 🧪 Testing

### Test Localhost
1. Run: `flutter run -d chrome`
2. Open: `http://localhost:port`
3. Verify: Console shows "Development (Localhost)"

### Test Production
1. Build: `flutter build web --release`
2. Deploy to hosting
3. Verify: Console shows "Production (Infinity)"

## 🔐 Security Checklist

- ✅ HTTPS in production
- ✅ Localhost hidden
- ✅ No credentials in code
- ✅ JWT authentication
- ✅ CORS configured

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Not connecting | Check backend is running |
| CORS errors | Configure backend CORS |
| Wrong server | Check URL in api_config.dart |
| Mobile issues | Test responsive layout |

## 📞 Support

- **Documentation**: See docs folder
- **Configuration**: `api_config.dart`
- **Issues**: Check console logs
- **Backend**: Test with curl/Postman

## ✅ Status

- **Mobile Responsive**: ✅ Complete
- **Server Config**: ✅ Complete
- **Documentation**: ✅ Complete
- **Ready to Deploy**: ✅ YES

---

**Quick Access**: Keep this card handy for reference!
