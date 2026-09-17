@echo off
setlocal
set "SRC=%~dp0"
echo ForeverMacroHelper by 0xgle
echo.
echo Copy the ForeverMacroHelper folder to:
echo World of Warcraft\_classic_era_\Interface\AddOns\
echo.
echo This helper opens the most common default installation folder.
set "WOW=%ProgramFiles(x86)%\World of Warcraft\_classic_era_\Interface\AddOns"
if exist "%WOW%" (
  explorer "%WOW%"
) else (
  echo Default folder not found. Open your WoW installation manually.
)
pause
