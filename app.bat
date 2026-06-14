@echo off
if "%~1"=="" goto usage
if "%~1"=="run" goto run
if "%~1"=="build" goto build
if "%~1"=="release" goto release
if "%~1"=="patch" goto patch

:usage
echo Usage: app [run^|build^|release^|patch]
echo.
echo   run      Runs the app in dev mode using api_config.json
echo   build    Builds the release APK (standard Flutter build)
echo   release  Builds and releases the app using Shorebird (APK artifact)
echo   patch    Builds and patches the app using Shorebird
goto :eof

:run
flutter run --dart-define-from-file=api_config.json
goto :eof

:build
flutter build apk --dart-define-from-file=api_config.json --no-tree-shake-icons
goto :eof

:release
shorebird release android --artifact=apk -- --dart-define-from-file=api_config.json --no-tree-shake-icons
goto :eof

:patch
shorebird patch android -- --dart-define-from-file=api_config.json --no-tree-shake-icons
goto :eof
