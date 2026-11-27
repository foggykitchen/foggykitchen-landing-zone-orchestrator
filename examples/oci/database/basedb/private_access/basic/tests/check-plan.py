#!/usr/bin/env python3
"""Check child-module CMK wiring in `tofu test -json -verbose` output.

HCL assertions cannot access child module inputs/resources. Inspect only mocked
plans here; never print plan values (a real plan could contain credentials).
"""
import json
import pathlib
import sys


def check(path):
    events = [json.loads(line) for line in path.read_text().splitlines()
              if line.startswith('{')]
    summaries = [event['test_summary'] for event in events
                 if event.get('type') == 'test_summary']
    if not summaries or summaries[-1]['status'] != 'pass':
        raise ValueError('All mocked HCL tests must pass before checking CMK wiring.')
    plans = {event['@testrun']: event['test_plan'] for event in events
             if event.get('type') == 'test_plan'}
    expected = {
        'cmk_primary': ('ocid1.key.oc1.eu-frankfurt-1.mock',
                        'ocid1.vault.oc1.eu-frankfurt-1.mock',
                        'ocid1.keyversion.oc1.eu-frankfurt-1.mock'),
    }
    # Omitted fields are Optional+Computed, so mocks generate values for them.
    # pattern_security asserts the omitted/null payload; do not mistake generated
    # mock metadata for configured CMK. Check explicit CMK at the resource boundary.
    fields = ('kms_key_id', 'vault_id', 'kms_key_version_id')
    for name, values in expected.items():
        systems = [r for r in plans[name]['resource_changes']
                   if r['type'] == 'oci_database_db_system']
        if len(systems) != 1:
            raise ValueError(f'{name}: expected exactly one PRIMARY DB system.')
        database = systems[0]['change']['after']['db_home'][0]['database'][0]
        if tuple(database.get(field) for field in fields) != values:
            raise ValueError(f'{name}: planned DB encryption fields do not match inputs.')
        print(f'{name}: planned DB system CMK wiring PASS')


if __name__ == '__main__':
    check(pathlib.Path(sys.argv[1]))
