#!/usr/bin/env python3
"""Validate every tracked example root, with plan-only tests and no cloud credentials."""
import argparse
import json
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]


def examples():
    names = subprocess.check_output(['git', 'ls-files', '-z', 'examples'], cwd=ROOT).decode().split('\0')
    return sorted({str(pathlib.PurePosixPath(n).parent) for n in names if n.endswith('.tf')})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true', help='emit JSON roots for the CI matrix')
    parser.add_argument('--example', choices=examples())
    parser.add_argument('--log-dir', type=pathlib.Path, default=ROOT / '.validation')
    args = parser.parse_args()
    if args.list:
        print(json.dumps(examples()))
        return 0
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(('ARM_', 'OCI_', 'AWS_', 'AZURE_', 'TF_VAR_'))}
    env.update(TF_IN_AUTOMATION='1', TF_INPUT='0', ARM_USE_CLI='false', ARM_USE_MSI='false')
    args.log_dir.mkdir(parents=True, exist_ok=True)
    results = []
    for name in [args.example] if args.example else examples():
        path = ROOT / name
        tests = sorted(path.glob('*.tftest.hcl')) + sorted((path / 'tests').glob('*.tftest.hcl'))
        for test in tests:
            runs = len(re.findall(r'\brun\s+"', test.read_text()))
            plans = len(re.findall(r'\bcommand\s*=\s*plan\b', test.read_text()))
            if runs != plans or re.search(r'\bcommand\s*=\s*apply\b', test.read_text()):
                raise ValueError(f'{test}: only explicit command = plan tests are allowed')
        commands = [['fmt', '-check'], ['init', '-backend=false', '-input=false', '-no-color'],
                    ['validate', '-no-color']]
        if tests:
            commands.append(['test', '-no-color'])
        result = {'example': name, 'checks': {}}
        log = args.log_dir / (name.replace('/', '__') + '.log')
        with log.open('w') as output:
            for command in commands:
                output.write('$ tofu ' + ' '.join(command) + '\n')
                output.flush()
                run = subprocess.run(['tofu', *command], cwd=path, env=env, stdout=output, stderr=subprocess.STDOUT)
                result['checks'][command[0]] = run.returncode
                print(f'{name}: {command[0]} exit={run.returncode}', flush=True)
                if run.returncode and command[0] == 'init':
                    break
        results.append(result)
    (args.log_dir / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
    return int(any(code for result in results for code in result['checks'].values()))


if __name__ == '__main__':
    sys.exit(main())
