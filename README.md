# 🛒 Global POS - Point of Sale System

A full-featured Point of Sale system with Flutter frontend and PHP backend.

## 🚀 Quick Deploy to Railway

**Deploy in 5 minutes!** See [QUICK_START_RAILWAY.md](QUICK_START_RAILWAY.md)

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Deploy backend
cd backend
railway login
railway init
railway up

# 3. Add MySQL database in Railway dashboard
# 4. Configure environment variables (see railway.env.template)
# 5. Import database schema
# 6. Deploy frontend (see guide)
```

## 📚 Documentation

- **[Quick Start Guide](QUICK_START_RAILWAY.md)** - Deploy in 5 minutes
- **[Full Deployment Guide](RAILWAY_DEPLOYMENT.md)** - Detailed instructions
- **[Deployment Checklist](DEPLOYMENT_CHECKLIST.md)** - Step-by-step checklist
- **[Architecture Diagram](ARCHITECTURE.md)** - System architecture
- **[Environment Variables](backend/railway.env.template)** - Configuration template
- **[API Configuration](API_CONFIGURATION.md)** - Server connection setup
- **[Quick Server Switch](QUICK_SERVER_SWITCH.md)** - Switch between localhost and production

## 🏗️ Project Structure

```
├── backend/                    # PHP API Backend
│   ├── api/                   # API endpoints
│   ├── config/                # Configuration files
│   ├── models/                # Data models
│   ├── utils/                 # Utilities (JWT, UUID, etc.)
│   ├── database/              # SQL schemas and migrations
│   ├── railway.json           # Railway configuration
│   ├── nixpacks.toml          # PHP setup for Railway
│   └── railway.env.template   # Environment variables template
│
├── frontend/                   # Flutter Web/Mobile App
│   ├── lib/                   # Flutter source code
│   ├── web/                   # Web-specific files
│   ├── Dockerfile             # Container configuration
│   └── nginx.conf             # Web server configuration
│
└── uploads/                    # Product images
```

## ✨ Features

### Core Features
- 🔐 User authentication & authorization
- 📦 Product management with images
- 🛍️ Order processing & POS interface
- 👥 Customer management
- 📊 Sales reports & analytics
- 💰 Multiple payment methods
- 🏷️ Category management
- 📈 Inventory tracking

### Advanced Features
- 📊 Inventory analytics
- 👨‍💼 Employee management
- 🎁 Gift cards
- 💳 Loyalty program
- 💸 Refunds & returns
- 📋 Audit logs
- 🔄 Stock management
- 💱 Multi-currency support
- 📱 Offline sync capability

## 🛠️ Technology Stack

### Backend
- PHP 8.2
- MySQL 8.0
- JWT Authentication
- PDO for database
- RESTful API

### Frontend
- Flutter 3.x
- Provider state management
- HTTP client
- Responsive design
- Web, Windows, Android support

## 🚀 Deployment Options

### Railway (Recommended)
- ✅ Easy setup
- ✅ Automatic HTTPS
- ✅ Built-in MySQL
- ✅ Environment variables
- ✅ Automatic deployments
- 💰 ~$10/month

### Alternative Platforms
- **Backend**: Heroku, DigitalOcean, AWS
- **Frontend**: Vercel, Netlify, Firebase Hosting
- **Database**: PlanetScale, AWS RDS, DigitalOcean

## 🔧 Local Development

### Backend Setup
```bash
cd backend
cp .env.example .env
# Edit .env with your database credentials
# Import database/schema.sql to MySQL
php -S localhost:8000
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Server Configuration

The app automatically connects to the appropriate server:

- **Localhost**: When running on `http://localhost` (development)
- **Production**: When deployed or accessed from any other domain
- **Custom**: Can be set via app settings

See [API Configuration Guide](API_CONFIGURATION.md) for details.

**Current Production Server**: `https://posys.ct.ws/backend/api`

## 🧪 Testing

### Test Backend API
```bash
# Health check
curl http://localhost:8000

# Login
curl -X POST http://localhost:8000/api/auth.php \
  -H "Content-Type: application/json" \
  -d '{"action":"login","username":"admin","password":"admin123"}'
```

### Default Credentials
- Username: `admin`
- Password: `admin123`

**⚠️ Change these in production!**

## 📦 Database Schema

Import in this order:
1. `backend/database/schema.sql` - Main schema
2. `backend/database/test_data.sql` - Sample data (optional)

## 🔒 Security

- JWT token authentication
- Password hashing (bcrypt)
- SQL injection prevention (PDO prepared statements)
- CORS configuration
- Input validation
- Environment variable secrets

## 🌐 API Endpoints

### Authentication
- `POST /api/auth.php` - Login/logout

### Core Resources
- `GET/POST/PUT/DELETE /api/products.php` - Products
- `GET/POST/PUT/DELETE /api/orders.php` - Orders
- `GET/POST/PUT/DELETE /api/customers.php` - Customers
- `GET/POST/PUT/DELETE /api/categories.php` - Categories
- `GET/POST/PUT/DELETE /api/users.php` - Users

### Analytics
- `GET /api/reports.php` - Sales reports
- `GET /api/inventory_analytics.php` - Inventory insights
- `GET /api/customer_analytics.php` - Customer insights

### Operations
- `POST /api/upload_image.php` - Image upload
- `GET/POST /api/stock_management.php` - Stock operations
- `GET/POST /api/refunds.php` - Refund processing

## 📱 Supported Platforms

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Windows Desktop
- ✅ Android
- ⚠️ iOS (requires Mac for building)
- ⚠️ macOS (requires Mac for building)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

- 📖 Documentation: See docs folder
- 🐛 Issues: Create an issue on GitHub
- 💬 Questions: Contact support team

## 🎯 Roadmap

- [ ] Mobile app optimization
- [ ] Barcode scanner integration
- [ ] Receipt printer support
- [ ] Multi-store management
- [ ] Advanced reporting
- [ ] API documentation (Swagger)
- [ ] Automated testing
- [ ] CI/CD pipeline

## 📊 System Requirements

### Backend
- PHP 8.2+
- MySQL 8.0+
- 512MB RAM minimum
- 1GB storage minimum

### Frontend
- Modern web browser
- 2GB RAM minimum
- Internet connection

## 🔄 Updates

To update your deployment:

```bash
# Backend
cd backend
railway up

# Frontend
cd frontend
flutter build web --release
# Deploy build/web folder
```

## 💡 Tips

1. **Use Railway for backend** - Easiest setup with built-in MySQL
2. **Use Vercel for frontend** - Best performance for Flutter web
3. **Enable backups** - Regular database backups are crucial
4. **Monitor logs** - Check Railway logs for errors
5. **Update regularly** - Keep dependencies up to date

## 🎉 Success!

Once deployed, you'll have:
- ✅ Live backend API
- ✅ Live frontend web app
- ✅ MySQL database
- ✅ HTTPS enabled
- ✅ Ready for production

**Start selling!** 🛒💰

---

Made with ❤️ for small businesses
