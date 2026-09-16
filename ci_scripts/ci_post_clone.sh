#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Keep Xcode Cloud package-plugin behavior explicit.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

# Fail early when repository-controlled runtime configuration is missing.
required_files=(
  "OursReader/GoogleService-Info.plist"
  "readerWatchOS Watch App/GoogleService-Info.plist"
  "OursReader/OursReaderDebug.entitlements"
  "OursReader/OursReader.entitlements"
  "OursReader.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required build configuration: $file" >&2
    exit 1
  fi
done

echo "OursReader repository build prerequisites are present."
