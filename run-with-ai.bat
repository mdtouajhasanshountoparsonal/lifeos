@echo off
REM Gemini offline/online toggle script for LifeOS
REM How to give your key:
REM   Option 1:  set LIFEOS_GEMINI_KEY=PASTE_YOUR_KEY_HERE  (then run this)
REM   Option 2:  create a file named  googleai.key  in THIS folder with ONLY your key inside, then run this.
rem -------------------------------------------------------
cd /d "%~dp0"
setlocal enabledelayedexpansion
if not defined LIFEOS_GEMINI_KEY (
  if exist googleai.key (
    set /p LIFEOS_GEMINI_KEY=<googleai.key
  )
)
if not defined LIFEOS_OPENAI_KEY (
  if exist openaikey.key (
    set /p LIFEOS_OPENAI_KEY=<openaikey.key
  )
)
set EXTRA=
if defined LIFEOS_GEMINI_KEY set EXTRA=--dart-define=LIFEOS_GEMINI_KEY=!LIFEOS_GEMINI_KEY! !EXTRA!
if defined LIFEOS_OPENAI_KEY set EXTRA=--dart-define=LIFEOS_OPENAI_KEY=!LIFEOS_OPENAI_KEY! !EXTRA!
if defined EXTRA (
  echo [OK] Gemini/GPT key found - online AI will be enabled.
  flutter run !EXTRA!
) else (
  echo [!] No AI key found.
  echo     Put your Gemini key in googleai.key or GPT key in openaikey.key
  echo     (this folder), or set LIFEOS_GEMINI_KEY / LIFEOS_OPENAI_KEY, then run again.
  echo     Running without key (offline AI) for now...
  flutter run
)
endlocal