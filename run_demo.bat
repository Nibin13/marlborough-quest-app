@echo off
echo ========================================================
echo   Google AI Edge Eloquent - Speech to Well-Crafted Text
echo ========================================================
echo.
echo Starting FastAPI & Flutter Web Server on port 8000...
echo Open in browser: http://localhost:8000
echo Mobile on same Wi-Fi: http://192.168.1.156:8000
echo.
cd /d "%~dp0server"
python -m uvicorn main:app --host 0.0.0.0 --port 8000
pause
