@echo off
echo 🚀 Starting AI Comics Backend Server...

cd /d "E:\ME\SMART HOME\From Scrach Claude SOnet 4\Phase 1 Fundation & Archicetture\backend"

set DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/aicomics
set REDIS_URL=redis://localhost:6379
set NODE_ENV=development
set PORT=3000

echo 📊 Environment configured
echo 💾 Database: %DATABASE_URL%
echo 🗄️ Redis: %REDIS_URL%
echo 🌐 Port: %PORT%

node src/server.js

pause
