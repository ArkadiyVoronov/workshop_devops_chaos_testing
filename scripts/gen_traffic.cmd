@echo off
setlocal enabledelayedexpansion
set count=%1
if "%count%"=="" set count=30
set url=%2
if "%url%"=="" set url=http://localhost:5000/api/balance

for /l %%i in (1,1,%count%) do (
  curl -s -o nul -w "%%i:%%{http_code} " %url% >nul 2>nul
)
echo Done
