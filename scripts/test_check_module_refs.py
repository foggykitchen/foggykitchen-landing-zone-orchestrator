"""Offline regressions for Azure/OCI scanning and semver freshness."""
import contextlib
import importlib.util
import io
import pathlib
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('refs', pathlib.Path(__file__).with_name('check-module-refs.py'))
refs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(refs)


class ReferencePolicyTests(unittest.TestCase):
    def check(self, text, tags='', latest=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            (root / 'main.tf').write_text(text)
            def command(args, **kwargs):
                return b'main.tf\0' if args[1] == 'ls-files' else tags
            with patch.object(refs.subprocess, 'check_output', side_effect=command), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                return refs.check(root, latest)

    def test_both_clouds_reject_floating_refs(self):
        for cloud in ('az', 'oci'):
            for ref in ('main', 'master'):
                with self.subTest(cloud=cloud, ref=ref):
                    self.assertTrue(self.check(f'terraform-{cloud}-fk-vnet.git?ref={ref}'))

    def test_normal_check_is_offline(self):
        self.assertFalse(self.check('terraform-az-fk-compute.git?ref=v0.4.1'))

    def test_latest_compares_numeric_versions_and_ignores_prereleases(self):
        tags = 'a\trefs/tags/v0.9.0\nb\trefs/tags/v0.10.0\nc\trefs/tags/v1.0.0-rc.1\n'
        self.assertTrue(self.check('terraform-az-fk-compute.git?ref=v0.9.0', tags, True))
        self.assertFalse(self.check('terraform-az-fk-compute.git?ref=v0.10.0', tags, True))

    def test_latest_rejects_unknown_ref_and_empty_tags(self):
        self.assertTrue(self.check('terraform-oci-fk-vcn.git?ref=v9.0.0', 'a\trefs/tags/v0.3.0\n', True))
        self.assertTrue(self.check('terraform-oci-fk-vcn.git?ref=v0.3.0', '', True))


if __name__ == '__main__':
    unittest.main()
