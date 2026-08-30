@echo off
for /f "tokens=1,2 delims==" %%a in (.env) do set %%a=%%b
echo API Key starts with: %GEMINI_API_KEY:~0,8%
flutter run --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%