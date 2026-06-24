# mnivesh_central

This project uses `--dart-define-from-file` to load API configurations dynamically at compilation time from a JSON file.

## Setup
1. Copy `lib/core/api/api_config.json.example` to `lib/core/api/api_config.json` (which is git-ignored):
   ```bash
   cp lib/core/api/api_config.json.example lib/core/api/api_config.json
   ```
2. Populate the keys in `lib/core/api/api_config.json` with your environment values.

## Development
Run the application locally pointing to the configuration file:
```bash
flutter run --dart-define-from-file=lib/core/api/api_config.json
```
*Note: Hot reloading/restarting works, but if you make changes to `lib/core/api/api_config.json`, you must restart the execution (`q` then run again) for the changes to compile.*

## Short Command Helpers
To avoid typing long commands, you can use the custom `app` script wrapper created at the root of the project.

### On Windows (Command Prompt / PowerShell):
* **Run App**: `app run`
* **Standard Build (APK)**: `app build`
* **Shorebird Release (APK)**: `app release`
* **Shorebird Release (AAB)**: `app release-aab`
* **Shorebird Patch**: `app patch`

### On Git Bash, Linux, or macOS:
* Make it executable (one-time setup): `chmod +x app`
* **Run App**: `./app run`
* **Standard Build (APK)**: `./app build`
* **Shorebird Release (APK)**: `./app release`
* **Shorebird Release (AAB)**: `./app release-aab`
* **Shorebird Patch**: `./app patch`

---

## Detailed Manual Commands

### Standard Build (APK)
```bash
flutter build apk --dart-define-from-file=lib/core/api/api_config.json --no-tree-shake-icons
```

### Shorebird Release (APK)
```bash
shorebird release android --artifact apk --dart-define-from-file=lib/core/api/api_config.json '--' --no-tree-shake-icons
```

### Shorebird Release (AAB)
```bash
shorebird release android --artifact aab --dart-define-from-file=lib/core/api/api_config.json '--' --no-tree-shake-icons
```

### Shorebird Patch
```bash
shorebird patch android --dart-define-from-file=lib/core/api/api_config.json '--' --no-tree-shake-icons
```