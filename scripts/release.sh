#!/usr/bin/env bash
# ==============================================================================
# WhatsPlay Automated Version Tagging & Release Script
# Author: Nikhil
#
# Version Series:
#   1.0.0+1 -> 1.0.1+2 -> 1.0.2+3 (Semantic Version + Incrementing Build Number)
#
# Usage:
#   ./scripts/release.sh                # Automatically increments to next version in series
#   ./scripts/release.sh 1.0.0+1        # Explicit version + build number
#   ./scripts/release.sh v1.0.0         # Explicit tag name
#   ./scripts/release.sh 1.0.0+1 "Summary of changes"
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Locate Flutter
FLUTTER_BIN=""
if [ -x "/Users/imac/fvm/versions/3.41.8/bin/flutter" ]; then
  FLUTTER_BIN="/Users/imac/fvm/versions/3.41.8/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
else
  echo "❌ Error: Flutter executable not found."
  exit 1
fi

ARG_VERSION="${1:-}"
ARG_SUMMARY="${2:-}"

# Execute Python helper to resolve and set version in pubspec.yaml
VERSION_INFO=$(python3 - "$ARG_VERSION" "$ARG_SUMMARY" << 'EOF'
import sys, re

arg_ver = sys.argv[1].strip() if len(sys.argv) > 1 else ""
arg_sum = sys.argv[2].strip() if len(sys.argv) > 2 else ""

with open('pubspec.yaml', 'r') as f:
    pubspec = f.read()

m = re.search(r'version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)', pubspec)
cur_major = int(m.group(1)) if m else 1
cur_minor = int(m.group(2)) if m else 0
cur_patch = int(m.group(3)) if m else 0
cur_build = int(m.group(4)) if m else 1

if arg_ver:
    # Clean 'v' prefix if provided
    clean_ver = arg_ver.lstrip('v')
    if '+' in clean_ver:
        ver_part, build_part = clean_ver.split('+', 1)
        target_version = ver_part
        target_build = int(build_part)
    else:
        target_version = clean_ver
        target_build = cur_build + 1
else:
    # Auto-increment patch and build number: e.g. 1.0.0+1 -> 1.0.1+2
    target_version = f"{cur_major}.{cur_minor}.{cur_patch + 1}"
    target_build = cur_build + 1

full_ver = f"{target_version}+{target_build}"
tag_name = f"v{target_version}"
summary = arg_sum if arg_sum else f"Release {tag_name} ({full_ver})"

# Update pubspec.yaml
new_pubspec = re.sub(r'version:\s*[^\n]+', f'version: {full_ver}', pubspec)
with open('pubspec.yaml', 'w') as f:
    f.write(new_pubspec)

print(f"{tag_name}|{target_version}|{target_build}|{full_ver}|{summary}")
EOF
)

IFS='|' read -r TAG_NAME TARGET_VERSION TARGET_BUILD FULL_VERSION SUMMARY <<< "$VERSION_INFO"

echo "=================================================="
echo "🚀 Starting WhatsPlay Release: $TAG_NAME"
echo "🔢 Full Version : $FULL_VERSION (Build $TARGET_BUILD)"
echo "📌 Summary      : $SUMMARY"
echo "🛠️ Flutter      : $FLUTTER_BIN"
echo "=================================================="

# Ensure local secrets vault is protected and never committed to public git
git update-index --skip-worktree lib/config/secrets/api_secrets_vault.dart 2>/dev/null || true

# 1. Build optimized Release APK
echo "📦 1. Building release APK with split-per-abi..."
"$FLUTTER_BIN" build apk --release --split-per-abi

SOURCE_APK="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
if [ ! -f "$SOURCE_APK" ]; then
  echo "❌ Error: Expected APK not found at $SOURCE_APK"
  exit 1
fi

# 2. Synchronize APK artifacts
echo "📂 2. Copying APK to downloads/WhatsPlay.apk and docs/downloads/WhatsPlay.apk..."
mkdir -p downloads docs/downloads
cp "$SOURCE_APK" downloads/WhatsPlay.apk
cp "$SOURCE_APK" docs/downloads/WhatsPlay.apk

# 3. Compute file size and SHA256 checksum
APK_SIZE_BYTES="$(stat -f%z downloads/WhatsPlay.apk 2>/dev/null || stat -c%s downloads/WhatsPlay.apk)"
APK_SHA256="$(shasum -a 256 downloads/WhatsPlay.apk | awk '{print $1}')"

# 4. Update README.md, CHANGELOG.md, and docs with Python
echo "📄 3. Updating README.md, CHANGELOG.md, docs/index.html & docs/blend.html..."
python3 - "$TAG_NAME" "$FULL_VERSION" "$APK_SIZE_BYTES" "$SUMMARY" << 'EOF'
import sys, re, datetime

tag = sys.argv[1]
full_ver = sys.argv[2]
size_bytes = int(sys.argv[3])
summary = sys.argv[4] if len(sys.argv) > 4 else f"Release {tag}"

size_mb = f"{size_bytes / (1024 * 1024):.1f} MB"
badge_size = size_mb.replace(" ", "_")
today_date = datetime.date.today().strftime("%Y-%m-%d")
month_year = datetime.date.today().strftime("%B %Y")

# 1. Update README.md
try:
    with open('README.md', 'r') as f:
        readme = f.read()
    # Update release version badge
    readme = re.sub(
        r'https://img\.shields\.io/badge/Release-[^"]+',
        f'https://img.shields.io/badge/Release-{tag}_({full_ver})-blue.svg?style=for-the-badge&logo=git',
        readme
    )
    # Update APK download badge to link through trackable source URL
    readme = re.sub(
        r'<a href="[^"]*"><img src="https://img\.shields\.io/badge/Download_APK-[^"]+"',
        f'<a href="https://nikhilxrstudio-ctrl.github.io/Whats_play/?source=GitHub+README&download=1"><img src="https://img.shields.io/badge/Download_APK-WhatsPlay.apk_({badge_size})-1DB954?style=for-the-badge&logo=android&logoColor=white"',
        readme
    )
    # Update table row
    readme = re.sub(
        r'\|\s*\*\*WhatsPlay\.apk[^\n]*',
        f'| **WhatsPlay.apk (Latest {tag})** | `arm64-v8a` (99% Modern Android Phones) | **{size_mb}** | [⬇️ **Download WhatsPlay.apk**](https://nikhilxrstudio-ctrl.github.io/Whats_play/?source=GitHub+README&download=1) <br><sub>[Direct Link](https://github.com/nikhilxrstudio-ctrl/Whats_play/raw/main/downloads/WhatsPlay.apk)</sub> |',
        readme
    )
    with open('README.md', 'w') as f:
        f.write(readme)
    print("✓ Updated README.md (Version badge, APK size, download link)")
except Exception as e:
    print(f"Notice updating README: {e}")

# 2. Update CHANGELOG.md if this version is not yet recorded
try:
    with open('CHANGELOG.md', 'r') as f:
        changelog = f.read()
    if f"## [{tag}]" not in changelog:
        new_entry = f"\n## [{tag}] - {today_date} (Build: {full_ver})\n\n### ⚡ What's New\n- {summary}\n"
        # Insert after header separator
        if "---\n" in changelog:
            parts = changelog.split("---\n", 1)
            changelog = parts[0] + "---\n" + new_entry + parts[1]
        else:
            changelog += new_entry
        with open('CHANGELOG.md', 'w') as f:
            f.write(changelog)
        print(f"✓ Added {tag} entry to CHANGELOG.md")
except Exception as e:
    print(f"Notice updating CHANGELOG.md: {e}")

# 3. Update docs/index.html
try:
    with open('docs/index.html', 'r') as f:
        html = f.read()
    # Update hero button
    html = re.sub(r'⬇️ Download WhatsPlay\.apk \([^)]+\)', f'⬇️ Download WhatsPlay.apk ({size_mb})', html)
    # Update changelog download button
    html = re.sub(r'⬇️ Download APK \([^)]+\)', f'⬇️ Download APK ({size_mb})', html)
    # Update version badge
    html = re.sub(r'<span class=\"version-badge\">[^<]+</span>', f'<span class=\"version-badge\">{tag} • Latest Release</span>', html)
    # Update release date
    html = re.sub(r'<span class=\"release-date\">[^<]+</span>', f'<span class=\"release-date\">{month_year}</span>', html)
    # Update JavaScript constants for smart detection
    html = re.sub(r'const LATEST_VERSION = \'[^\']+\';', f'const LATEST_VERSION = \'{tag}\';', html)
    html = re.sub(r'const APK_SIZE = \'[^\']+\';', f'const APK_SIZE = \'{size_mb}\';', html)
    with open('docs/index.html', 'w') as f:
        f.write(html)
    print("✓ Updated docs/index.html (Version badge, Release date, APK size)")
except Exception as e:
    print(f"Notice updating docs/index.html: {e}")

# 4. Update docs/blend.html
try:
    with open('docs/blend.html', 'r') as f:
        b_html = f.read()
    b_html = re.sub(r'⬇️ Download WhatsPlay APK \([^)]+\)', f'⬇️ Download WhatsPlay APK ({size_mb})', b_html)
    with open('docs/blend.html', 'w') as f:
        f.write(b_html)
    print("✓ Updated docs/blend.html (APK size)")
except Exception as e:
    print(f"Notice updating docs/blend.html: {e}")

print(f"Artifact sync complete for {tag} ({size_mb})")
EOF

# Sync docs HTML to root HTML for GitHub Pages compatibility
cp docs/index.html index.html
cp docs/blend.html blend.html

APK_SIZE_MB="$(python3 -c "print(f'{$APK_SIZE_BYTES / (1024 * 1024):.1f} MB')")"

# 5. Commit release artifacts with author Nikhil
echo "💾 4. Committing release artifacts..."
git add -A pubspec.yaml CHANGELOG.md scripts/ README.md index.html blend.html docs/index.html docs/blend.html downloads/WhatsPlay.apk docs/downloads/WhatsPlay.apk android/ lib/
git commit --author="Nikhil <nikhil@whatsplay.com>" -m "release: $TAG_NAME ($FULL_VERSION) - $SUMMARY" || echo "No changes to commit"

# 6. Create annotated Git tag
echo "🏷️ 5. Creating annotated Git tag: $TAG_NAME..."
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
  echo "⚠️ Tag $TAG_NAME already exists, recreating tag..."
  git tag -d "$TAG_NAME"
fi

git tag -a "$TAG_NAME" -m "$TAG_NAME: $SUMMARY

Release Details:
- Version: $FULL_VERSION
- APK File: WhatsPlay.apk ($APK_SIZE_MB)
- Architecture: arm64-v8a
- SHA256: $APK_SHA256
- Author: Nikhil"

# 7. Push commit and tag to remote
echo "🌐 6. Pushing to origin main with tags..."
git push origin main
git push origin "$TAG_NAME" --force

echo ""
echo "=================================================="
echo "🎉 SUCCESS: WhatsPlay $TAG_NAME ($FULL_VERSION) Published!"
echo "🏷️ Tag       : $TAG_NAME"
echo "🔢 Version   : $FULL_VERSION"
echo "📦 APK File  : WhatsPlay.apk ($APK_SIZE_MB)"
echo "🔑 SHA256    : $APK_SHA256"
echo "🌐 Website   : https://nikhilxrstudio-ctrl.github.io/Whats_play/"
echo "⬇️ Download  : https://nikhilxrstudio-ctrl.github.io/Whats_play/downloads/WhatsPlay.apk"
echo "=================================================="
