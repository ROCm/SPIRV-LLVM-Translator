"""Exercise workflow security boundaries locally (requires PyYAML, bash and jq)."""

import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from typing import TypedDict

import yaml


WORKFLOWS = Path(__file__).resolve().parents[1] / "workflows"
REPO = "ROCm/SPIRV-LLVM-Translator"
SHA = "a" * 40
BOT = "rocm-spirv-translator-merge[bot]"


class WorkflowStep(TypedDict, total=False):
    name: str
    run: str


class WorkflowJob(TypedDict):
    steps: list[WorkflowStep]


class WorkflowDefinition(TypedDict):
    jobs: dict[str, WorkflowJob]


JsonValue = str | int | bool | None | list["JsonValue"] | dict[str, "JsonValue"]


class MergeFixture(TypedDict):
    prs: list[dict[str, int]]
    details: dict[str, JsonValue]
    jobs: list[dict[str, str]]


def workflow(name: str) -> WorkflowDefinition:
    return yaml.safe_load((WORKFLOWS / name).read_text(encoding="utf-8"))


def step(name: str, step_name: str) -> WorkflowStep:
    for job in workflow(name)["jobs"].values():
        for entry in job.get("steps", []):
            if entry.get("name") == step_name:
                return entry
    raise ValueError(f"Missing step: {name}: {step_name}")


class WorkflowSecurityTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.log = self.root / "commands.jsonl"
        self.env = os.environ | {
            "PATH": f"{self.root}:{os.environ['PATH']}",
            "COMMAND_LOG": str(self.log),
            "GH_TOKEN": "test-token",
            "REPO": REPO,
            "HEAD_SHA": SHA,
            "EXPECTED_AUTHOR": BOT,
            "RUN_ID": "123",
            "RUN_ATTEMPT": "2",
        }
        gh = self.root / "gh"
        gh.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "args = sys.argv[1:]\n"
            "with open(os.environ['COMMAND_LOG'], 'a') as log:\n"
            "    log.write(json.dumps(args) + '\\n')\n"
            "fixture = json.loads(os.environ['GH_FIXTURE'])\n"
            "if args[:2] == ['pr', 'list']:\n"
            "    print(json.dumps(fixture['prs']))\n"
            "elif args[0] == 'api' and '/pulls/' in args[1]:\n"
            "    print(json.dumps(fixture['details']))\n"
            "elif args[0] == 'api' and args[1].endswith('/attempts/2/jobs'):\n"
            "    for job in fixture['jobs']: print(json.dumps(job))\n"
            "elif args[:2] != ['pr', 'merge']:\n"
            "    raise ValueError(args)\n",
            encoding="utf-8",
        )
        gh.chmod(0o755)

    def commands(self) -> list[list[str]]:
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def fixture(self, branch: str) -> MergeFixture:
        return {
            "prs": [{"number": 123}],
            "details": {
                "state": "open", "draft": False,
                "base": {"ref": "amd-staging", "repo": {"full_name": REPO}},
                "head": {"ref": branch, "sha": SHA, "repo": {"full_name": REPO}},
                "user": {"login": BOT},
            },
            "jobs": [
                {"name": "Linux::release / Build", "status": "completed", "conclusion": "success"},
                {"name": "Linux::release / Test rocm-examples", "status": "completed", "conclusion": "success"},
            ],
        }

    def run_watcher(self, filename: str, fixture: MergeFixture) -> list[list[str]]:
        self.log.unlink(missing_ok=True)
        branch = "deps/rocm-examples" if "rocm-examples" in filename else "upstream-merge-123"
        job = next(iter(workflow(filename)["jobs"].values()))
        result = subprocess.run(
            ["bash", "-e", "-o", "pipefail"], input=job["steps"][-1]["run"],
            env=self.env | {"HEAD_BRANCH": branch, "GH_FIXTURE": json.dumps(fixture)},
            cwd=self.root, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return [args for args in self.commands() if args[:2] == ["pr", "merge"]]

    def test_merge_only_matches_current_bot_head(self) -> None:
        for filename, branch in [
            ("automerge-after-ci.yml", "upstream-merge-123"),
            ("automerge-rocm-examples.yml", "deps/rocm-examples"),
        ]:
            fixture = self.fixture(branch)
            merges = self.run_watcher(filename, fixture)
            self.assertEqual(len(merges), 1)
            self.assertEqual(merges[0][-2:], ["--match-head-commit", SHA])
            for path, value in [
                (("head", "sha"), "b" * 40),
                (("head", "ref"), "another-branch"),
                (("head", "repo", "full_name"), "attacker/fork"),
                (("base", "ref"), "another-base"),
                (("base", "repo", "full_name"), "attacker/fork"),
                (("user", "login"), "attacker"),
                (("draft",), True),
                (("state",), "closed"),
            ]:
                with self.subTest(workflow=filename, field=path):
                    bad = copy.deepcopy(fixture)
                    obj = bad["details"]
                    for key in path[:-1]:
                        obj = obj[key]
                    obj[path[-1]] = value
                    self.assertEqual(self.run_watcher(filename, bad), [])
            for prs in [[], [{"number": 1}, {"number": 2}]]:
                self.assertEqual(self.run_watcher(filename, fixture | {"prs": prs}), [])

    def test_examples_gate_requires_exact_successful_jobs(self) -> None:
        filename = "automerge-rocm-examples.yml"
        fixture = self.fixture("deps/rocm-examples")
        for jobs in [
            [], fixture["jobs"][:1], fixture["jobs"] * 2,
            [fixture["jobs"][0] | {"conclusion": "failure"}, fixture["jobs"][1]],
            [fixture["jobs"][0] | {"status": "in_progress"}, fixture["jobs"][1]],
            [fixture["jobs"][0] | {"name": "Other / Build"}, fixture["jobs"][1]],
        ]:
            with self.subTest(jobs=jobs):
                self.assertEqual(self.run_watcher(filename, fixture | {"jobs": jobs}), [])
        self.run_watcher(filename, fixture)
        self.assertIn(
            ["api", f"repos/{REPO}/actions/runs/123/attempts/2/jobs", "--paginate", "--jq", ".jobs[]"],
            self.commands(),
        )

    def test_container_requires_digest_before_job_start(self) -> None:
        script = step("test_component.yml", "Require a digest for Linux test images")["run"]
        output = self.root / "output"
        pinned = "ghcr.io/rocm/test@sha256:" + SHA + "a" * 24
        for platform, override, expected in [
            ("linux", "", pinned), ("linux", pinned, pinned), ("windows", "", ""),
            ("linux", "ghcr.io/rocm/test:latest", None),
            ("linux", pinned + "\nimage=other", None), ("other", "", None),
        ]:
            with self.subTest(platform=platform, override=override):
                output.unlink(missing_ok=True)
                result = subprocess.run(
                    [sys.executable, "-c", script], text=True, capture_output=True,
                    env=self.env | {"PLATFORM": platform, "COMPONENT": json.dumps({"container_image": override}),
                                    "DEFAULT_IMAGE": pinned, "GITHUB_OUTPUT": str(output)},
                )
                if expected is None:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse(output.exists())
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(output.read_text(), f"image={expected}\n")

    def test_cmake_arguments_are_data(self) -> None:
        command = self.root / "cmake"
        command.write_text(
            f"#!{sys.executable}\nimport json, os, sys\n"
            "with open(os.environ['COMMAND_LOG'], 'a') as f: f.write(json.dumps(sys.argv[1:]) + '\\n')\n"
        )
        command.chmod(0o755)
        malicious = 'spaces $(touch SHOULD_NOT_EXIST) ; "quoted"'
        script = step("multi_arch_build_portable_linux_artifacts.yml", "Configure PR Projects")["run"]
        result = subprocess.run(
            ["bash", "-e", "-o", "pipefail"], input=script, text=True, capture_output=True,
            cwd=self.root, env=self.env | {
                "BUILD_DIR": "build with spaces", "INPUTS_ROCM_PACKAGE_VERSION": malicious,
                "CMAKE_PRESET_ARG": "", "STAGE_CMAKE_ARGS": "'-DFOO=a b' '-DBAR=$(touch SHOULD_NOT_EXIST)'",
                "extra_cmake_options": "'-DBAZ=c d'",
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        args = self.commands()[0]
        self.assertIn("-DTHEROCK_PACKAGE_VERSION=" + malicious, args)
        self.assertIn("-DFOO=a b", args)
        self.assertIn("-DBAR=$(touch SHOULD_NOT_EXIST)", args)
        self.assertIn("-DBAZ=c d", args)
        self.assertNotIn("", args)
        self.assertFalse((self.root / "SHOULD_NOT_EXIST").exists())


if __name__ == "__main__":
    unittest.main()
