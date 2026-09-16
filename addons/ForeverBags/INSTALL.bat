@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
echo.
echo  ForeverBags installer
 echo  --------------------
 echo.
set "WOWROOT="
for %%R in ("%ProgramFiles(x86)%\World of Warcraft" "%ProgramFiles%\World of Warcraft" "C:\Games\World of Warcraft" "D:\Games\World of Warcraft") do (
  if exist "%%~R" if not defined WOWROOT set "WOWROOT=%%~R"
)
if not defined WOWROOT (
  echo World of Warcraft folder was not found automatically.
  set /p WOWROOT=Paste your World of Warcraft folder path: 
)
if not exist "%WOWROOT%" (
  echo Folder does not exist: %WOWROOT%
  pause
  exit /b 1
)
set "CLIENT="
for %%C in (_forever_beta_ _beta_ _classic_era_ _retail_) do (
  if exist "%WOWROOT%\%%C" if not defined CLIENT=%%C
)
if not defined CLIENT (
  echo No known client folder found under %WOWROOT%.
  echo Available folders:
  dir /b /ad "%WOWROOT%"
  set /p CLIENT=Type the client folder name, for example _forever_beta_: 
)
set "DEST=%WOWROOT%\%CLIENT%\Interface\AddOns\ForeverBags"
echo.
echo Installing to:
echo %DEST%
if not exist "%WOWROOT%\%CLIENT%\Interface\AddOns" mkdir "%WOWROOT%\%CLIENT%\Interface\AddOns"
if exist "%DEST%" rmdir /s /q "%DEST%"
mkdir "%DEST%"
xcopy "%~dp0*" "%DEST%\" /E /I /Y >nul
if errorlevel 1 (
  echo Installation failed.
  pause
  exit /b 1
)
echo.
echo Installed successfully.
echo Start WoW, enable ForeverBags in AddOns, then type /fb in game.
echo.
pause
