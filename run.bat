@echo off
for /f "tokens=1,2 delims==" %%a in (.env) do set %%a=%%b
flutter run --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%