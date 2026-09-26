@echo off
title Clarity Coach - Backend Server
echo ===================================================
echo Starting Clarity Backend Server (FastAPI)...
echo ===================================================
cd /d "%~dp0backend"
call .\venv\Scripts\activate.bat
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
