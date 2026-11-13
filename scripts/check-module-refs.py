#!/usr/bin/env python3
"""Reject floating OCI module branches in tracked source, documentation and payloads."""
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[1]
files = subprocess.check_output(
    ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root
).decode().split('\0')
pattern = re.compile(r'terraform-oci-fk-[^\s"<>]*[?&]ref=(?:main|master)(?![\w.-])')
errors = []
for name in files:
    path = root / name
    if path.suffix not in {'.tf', '.json', '.yaml', '.yml', '.md'} or not path.is_file():
        continue
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if pattern.search(line):
            errors.append(f'{name}:{number}: {line.strip()}')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print('OCI module references: no main/master pins.')
