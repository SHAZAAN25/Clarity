@echo off
title Clarity Coach - Launcher
echo ===================================================
echo Launching Clarity Coach (Backend + Frontend)...
echo ===================================================
start "Clarity Backend (FastAPI)" "%~dp0start_backend.bat"
start "Clarity Frontend (Vite React)" "%~dp0start_frontend.bat"
echo.
echo Both servers are starting up!
echo - Backend API & Docs: http://localhost:8000/docs
echo - Frontend Web App:   http://localhost:5173
echo.
pause
