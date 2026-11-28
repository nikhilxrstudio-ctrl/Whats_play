#!/usr/bin/env python3
import sys
import os
import re

def get_current_version():
    with open('pubspec.yaml', 'r', encoding='utf-8') as f:
        content = f.read()
    match = re.search(r'version:\s*([^\s\n]+)', content)
    if not match:
        raise ValueError("Could not find 'version:' in pubspec.yaml")
    return match.group(1)

def set_version(new_version):
    with open('pubspec.yaml', 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = re.sub(r'version:\s*[^\s\n]+', f'version: {new_version}', content)
    with open('pubspec.yaml', 'w', encoding='utf-8') as f:
        f.write(new_content)
    return new_version

def next_version(current):
    # current format: X.Y.Z+B or X.Y.Z
    if '+' in current:
        ver_part, build_part = current.split('+', 1)
        build_num = int(build_part) + 1
    else:
        ver_part = current
        build_num = 1

    parts = [int(p) for p in ver_part.split('.')]
    while len(parts) < 3:
        parts.append(0)
    parts[2] += 1  # increment patch
    new_ver_part = f"{parts[0]}.{parts[1]}.{parts[2]}"
    return f"{new_ver_part}+{build_num}"

def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    current = get_current_version()

    if not arg or arg == '--get':
        print(current)
        return

    if arg == '--next':
        target = next_version(current)
    else:
        # User specified version (strip leading 'v' if present)
        target = arg.lstrip('v')
        if '+' not in target:
            # preserve or compute build number
            curr_build = current.split('+')[1] if '+' in current else '1'
            target = f"{target}+{curr_build}"

    set_version(target)
    print(target)

if __name__ == '__main__':
    main()
