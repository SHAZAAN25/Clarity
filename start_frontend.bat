@echo off
title Clarity Coach - Frontend Dev Server
echo ===================================================
echo Starting Clarity Frontend Web App (Vite + React)...
echo ===================================================
cd /d "%~dp0frontend"
npm run dev -- --host 0.0.0.0 --port 5173
pause
