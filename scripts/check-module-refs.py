#!/usr/bin/env python3
"""Check OCI/Azure pins; opt-in --latest checks current stable upstream tags."""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
REFERENCE = re.compile(
    r'(terraform-(?:oci|az)-fk-[a-z0-9-]+)(?:\.git)?'
    r'(?:/[^\s"<>?`]+)?[?&]ref=([^\s"<>`&#)\],]+)'
)
SEMVER = re.compile(r'v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)')


def version(tag):
    match = SEMVER.fullmatch(tag)
    return tuple(map(int, match.groups())) if match else None


def check(root, latest=False):
    files = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root
    ).decode().split('\0')
    errors, references = [], {}
    for name in sorted(set(files)):
        path = root / name
        if path.suffix not in {'.tf', '.json', '.yaml', '.yml', '.md'} or not path.is_file():
            continue
        for number, line in enumerate(path.read_text().splitlines(), 1):
            for module, ref in REFERENCE.findall(line):
                location = f'{name}:{number}'
                references.setdefault(module, {}).setdefault(ref, []).append(location)
                if ref in {'main', 'master'}:
                    errors.append(f'{location}: {module} uses floating ref {ref}')
    if latest:
        for module, pins in sorted(references.items()):
            try:
                output = subprocess.check_output(
                    ['git', 'ls-remote', '--tags', '--refs',
                     f'https://github.com/foggykitchen/{module}.git'],
                    text=True, stderr=subprocess.PIPE, timeout=60,
                )
                tags = [line.split('refs/tags/', 1)[1] for line in output.splitlines()
                        if 'refs/tags/' in line]
                stable = [tag for tag in tags if version(tag) is not None]
                if not stable:
                    raise ValueError('no stable semver tags found')
                newest = max(stable, key=version)
                for ref, locations in sorted(pins.items()):
                    if ref not in tags or version(ref) != version(newest):
                        errors.append(f'{locations[0]}: {module}: {ref}; latest stable tag is {newest}')
                print(f'{module}: latest={newest}; pins={",".join(sorted(pins))}')
            except (subprocess.SubprocessError, ValueError) as exc:
                errors.append(f'{module}: cannot verify upstream tags: {exc}')
    for error in errors:
        print(error, file=sys.stderr)
    print(f'OCI/Azure module references: {len(references)} modules, {len(errors)} errors.')
    return bool(errors)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--latest', action='store_true', help='require latest stable upstream tag')
    sys.exit(check(ROOT, parser.parse_args().latest))
