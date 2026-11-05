@echo off
cd /d "%~dp0"
if not exist "engine\Godot_v4.3-stable_win64_console.exe" goto missing
"%~dp0engine\Godot_v4.3-stable_win64_console.exe" --headless --editor --path "%~dp0." --import --quit
if errorlevel 1 goto failed
"%~dp0engine\Godot_v4.3-stable_win64_console.exe" --path "%~dp0." --rendering-method gl_compatibility
if errorlevel 1 goto failed
exit /b 0
:missing
echo Engine not found. Extract the full v0.1 package first.
pause
exit /b 1
:failed
echo Startup failed. Please send a screenshot of this window.
pause
exit /b 1
