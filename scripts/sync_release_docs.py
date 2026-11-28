#!/usr/bin/env python3
import sys
import os
import re

def main():
    if len(sys.argv) < 3:
        print("Usage: sync_release_docs.py <version_tag> <apk_size_mb>")
        sys.exit(1)

    version_tag = sys.argv[1]
    raw_version = version_tag.lstrip('v')
    apk_size_mb = sys.argv[2]
    apk_size_badge = apk_size_mb.replace(" ", "_")

    # 1. Update README.md
    if os.path.exists('README.md'):
        with open('README.md', 'r', encoding='utf-8') as f:
            readme = f.read()
        readme = re.sub(
            r'Download_APK-WhatsPlay\.apk_\([^)]+\)-1DB954',
            f'Download_APK-WhatsPlay.apk_({apk_size_badge})-1DB954',
            readme
        )
        readme = re.sub(
            r'\|\s*\*\*WhatsPlay\.apk \(Recommended\)\*\*\s*\|\s*`arm64-v8a`[^\n]*',
            f'| **WhatsPlay.apk (Recommended)** | `arm64-v8a` (99% Modern Android Phones) | **{apk_size_mb}** | [⬇️ **Download WhatsPlay.apk**](https://github.com/nikhilxrstudio-ctrl/Whats_play/raw/main/downloads/WhatsPlay.apk) |',
            readme
        )
        with open('README.md', 'w', encoding='utf-8') as f:
            f.write(readme)
        print(f"✅ Updated README.md with {apk_size_mb}")

    # 2. Update docs/index.html
    if os.path.exists('docs/index.html'):
        with open('docs/index.html', 'r', encoding='utf-8') as f:
            html = f.read()
        html = re.sub(
            r'⬇️ Download WhatsPlay\.apk \([^)]+\)',
            f'⬇️ Download WhatsPlay.apk ({apk_size_mb})',
            html
        )
        html = re.sub(
            r'⬇️ Download APK \([^)]+\)',
            f'⬇️ Download APK ({apk_size_mb})',
            html
        )
        html = re.sub(
            r'<span class="version-badge">[^<]+</span>',
            f'<span class="version-badge">{version_tag} • Latest Release</span>',
            html
        )
        with open('docs/index.html', 'w', encoding='utf-8') as f:
            f.write(html)
        print(f"✅ Updated docs/index.html with {version_tag} and {apk_size_mb}")

    # 3. Update docs/blend.html
    if os.path.exists('docs/blend.html'):
        with open('docs/blend.html', 'r', encoding='utf-8') as f:
            blend_html = f.read()
        blend_html = re.sub(
            r'⬇️ Download WhatsPlay APK \([^)]+\)',
            f'⬇️ Download WhatsPlay APK ({apk_size_mb})',
            blend_html
        )
        with open('docs/blend.html', 'w', encoding='utf-8') as f:
            f.write(blend_html)
        print(f"✅ Updated docs/blend.html with {apk_size_mb}")

if __name__ == '__main__':
    main()
