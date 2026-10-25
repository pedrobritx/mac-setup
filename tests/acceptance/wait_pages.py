"""Require a successful Pages deployment of the exact revision under test."""

import json
import os
import time
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def wait_for_pages(fetch_runs, sha, repository, *, timeout=180, interval=5,
                   clock=time.monotonic, pause=time.sleep):
    deadline = clock() + timeout
    while True:
        candidates = [run for run in fetch_runs() if (
            run.get("path") == "dynamic/pages/pages-build-deployment"
            and run.get("head_sha") == sha
            and run.get("head_branch") == "main"
            and (run.get("head_repository") or {}).get("full_name") == repository
        )]
        if candidates:
            run = max(candidates, key=lambda run: run["id"])
            if run["status"] == "completed":
                if run["conclusion"] != "success":
                    raise RuntimeError(f"Pages deployment {run['id']}: {run['conclusion']}")
                return run
        if clock() >= deadline:
            raise TimeoutError(f"No successful Pages deployment for {sha} within {timeout}s")
        pause(min(interval, max(0, deadline - clock())))


def fetch_runs(repository, sha):
    query = urlencode({"head_sha": sha, "per_page": 100})
    headers = {"Accept": "application/vnd.github+json"}
    if os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["GITHUB_TOKEN"]
    request = Request(
        f"https://api.github.com/repos/{repository}/actions/runs?{query}",
        headers=headers,
    )
    with urlopen(request, timeout=15) as response:
        return json.load(response)["workflow_runs"]


if __name__ == "__main__":
    repository = os.environ["GITHUB_REPOSITORY"]
    sha = os.environ["MAC_SETUP_EXPECTED_COMMIT"]
    run = wait_for_pages(lambda: fetch_runs(repository, sha), sha, repository)
    print(f"Confirmed Pages deployment for {sha}: {run['html_url']}")
