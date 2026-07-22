#!/usr/bin/env python3
import argparse
import plistlib
from pathlib import Path


parser = argparse.ArgumentParser(description="Set the default Worker URL in the WLOC shortcut source.")
parser.add_argument("worker_url", help="Worker root URL, for example https://name.account.workers.dev")
args = parser.parse_args()

worker_url = args.worker_url.rstrip("/")
if not worker_url.startswith("https://"):
    raise SystemExit("worker_url must start with https://")

shortcut = Path(__file__).resolve().parents[1] / "shortcuts" / "unsigned" / "WLOC-Set-Location.shortcut"
with shortcut.open("rb") as source:
    workflow = plistlib.load(source)

question = workflow["WFWorkflowImportQuestions"][0]
action = workflow["WFWorkflowActions"][question["ActionIndex"]]
if action["WFWorkflowActionIdentifier"] != "is.workflow.actions.text":
    raise SystemExit("Worker URL action was not found at the configured import-question index")

action["WFWorkflowActionParameters"][question["ParameterKey"]] = worker_url
with shortcut.open("wb") as output:
    plistlib.dump(workflow, output, fmt=plistlib.FMT_BINARY, sort_keys=False)

print(f"Default Worker URL set to {worker_url}")
