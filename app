#!/bin/bash

case "$1" in
  run)
    flutter run --dart-define-from-file=api_config.json
    ;;
  build)
    flutter build apk --dart-define-from-file=api_config.json --no-tree-shake-icons
    ;;
  release)
    shorebird release android --artifact=apk -- --dart-define-from-file=api_config.json --no-tree-shake-icons
    ;;
  patch)
    shorebird patch android -- --dart-define-from-file=api_config.json --no-tree-shake-icons
    ;;
  *)
    echo "Usage: ./app [run|build|release|patch]"
    echo ""
    echo "  run      Runs the app in dev mode using api_config.json"
    echo "  build    Builds the release APK (standard Flutter build)"
    echo "  release  Builds and releases the app using Shorebird (APK artifact)"
    echo "  patch    Builds and patches the app using Shorebird"
    exit 1
    ;;
esac
