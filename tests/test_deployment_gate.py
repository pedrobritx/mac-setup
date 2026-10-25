"""Deployment gate checks: require the tested revision, never an older success."""

import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "wait_pages", Path(__file__).parent / "acceptance/wait_pages.py"
)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class DeploymentGateTests(unittest.TestCase):
    def run_record(self, **changes):
        return dict({
            "id": 1, "path": "dynamic/pages/pages-build-deployment",
            "head_sha": "tested", "head_branch": "main",
            "head_repository": {"full_name": "owner/repo"},
            "status": "completed", "conclusion": "success",
        }, **changes)

    def wait(self, batches):
        now = [0]
        def pause(seconds):
            now[0] += seconds
        return gate.wait_for_pages(
            lambda: next(batches), "tested", "owner/repo", timeout=2,
            interval=1, clock=lambda: now[0], pause=pause,
        )

    def test_waits_for_matching_revision_and_completed_deployment(self):
        result = self.wait(iter([
            [self.run_record(head_sha="old")],
            [self.run_record(status="in_progress", conclusion=None)],
            [self.run_record()],
        ]))
        self.assertEqual(result["head_sha"], "tested")

    def test_latest_failed_run_cannot_be_hidden_by_old_success(self):
        with self.assertRaisesRegex(RuntimeError, "Pages deployment 2: failure"):
            self.wait(iter([[self.run_record(), self.run_record(id=2, conclusion="failure")]]))

    def test_wrong_workflow_branch_and_repository_cannot_satisfy_gate(self):
        runs = [self.run_record(path=".github/workflows/ci.yml"),
                self.run_record(head_branch="feature"),
                self.run_record(head_repository={"full_name": "fork/repo"})]
        with self.assertRaises(TimeoutError):
            self.wait(iter([runs, runs, runs]))

    def test_missing_run_expires_instead_of_accepting_old_deployment(self):
        with self.assertRaises(TimeoutError):
            self.wait(iter([[], [], []]))


if __name__ == "__main__":
    unittest.main()
