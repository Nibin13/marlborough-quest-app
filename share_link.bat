@echo off
echo ========================================================
echo   Generating Public Client Link via Localtunnel...
echo ========================================================
echo.
echo Make sure run_demo.bat is already running!
echo Generating HTTPS URL for your client...
echo.
npx -y localtunnel --port 8000
pause
