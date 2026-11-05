@echo off
cd /d "%~dp0"
"%~dp0engine\Godot_v4.3-stable_win64_console.exe" --editor --path "%~dp0." --rendering-method gl_compatibility
if errorlevel 1 pause
