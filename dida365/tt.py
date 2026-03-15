#!/usr/bin/env python3
"""tt.py — TickTick/Dida365 CLI  (pure Python, no external deps)"""

import json
import os
import re
import sys
import urllib.request
import urllib.error

BASE_URL = "https://api.dida365.com/open/v1"
INBOX_ID = "inbox00000000"

TIMEZONE = "Asia/Shanghai"
TZ_OFFSET = "+0800"


PRIORITY_MAP = {"none": 0, "low": 1, "med": 3, "medium": 3, "high": 5}
PRIORITY_LABEL = {0: "none", 1: "low", 3: "medium", 5: "high"}
PRIORITY_TAG = {0: "     ", 1: "[LOW] ", 3: "[MED] ", 5: "[HIGH]"}


# ── Auth ────────────────────────────────────────────────────────────────────────

def get_token():
    token = os.environ.get("TICKTICK_TOKEN", "")
    if not token:
        print("ERROR: TICKTICK_TOKEN not set", file=sys.stderr)
        sys.exit(1)
    return token


# ── HTTP helpers ────────────────────────────────────────────────────────────────

def _request(method, path, body=None):
    token = get_token()
    url = BASE_URL + path
    headers = {"Authorization": f"Bearer {token}"}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            if raw:
                return json.loads(raw)
            return None
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            err = json.loads(raw)
            print(f"ERROR: {err.get('errorMessage', raw)}", file=sys.stderr)
        except json.JSONDecodeError:
            print(f"ERROR: HTTP {e.code} — {raw}", file=sys.stderr)
        sys.exit(1)


def _get(path):
    return _request("GET", path)


def _post(path, body):
    return _request("POST", path, body)


def _del(path):
    return _request("DELETE", path)


# ── Helpers ─────────────────────────────────────────────────────────────────────

def priority_val(s):
    key = s.lower()
    if key not in PRIORITY_MAP:
        print(f"ERROR: Invalid priority '{s}'. Use: none, low, med, high", file=sys.stderr)
        sys.exit(1)
    return PRIORITY_MAP[key]


def resolve_project(name):
    if name == "inbox":
        return INBOX_ID
    if re.fullmatch(r"[0-9a-f]{24}", name):
        return name
    projects = _get("/project")
    for p in projects:
        if p["name"].lower() == name.lower():
            return p["id"]
    print(f"ERROR: Project '{name}' not found", file=sys.stderr)
    sys.exit(1)


# ── Commands ────────────────────────────────────────────────────────────────────

def cmd_projects(_args):
    projects = _get("/project")
    print(f"📁 {len(projects)} projects")
    for p in projects:
        print(f"  {p['id']}  {p['name']}")


def cmd_tasks(args):
    project = "inbox"
    i = 0
    while i < len(args):
        if args[i] == "--project":
            project = args[i + 1]; i += 2
        else:
            print(f"ERROR: Unknown option {args[i]}", file=sys.stderr); sys.exit(1)
    project_id = resolve_project(project)
    data = _get(f"/project/{project_id}/data")
    tasks = [t for t in data.get("tasks", []) if t.get("status", 0) == 0]
    tasks.sort(key=lambda t: (-t.get("priority", 0), t.get("startDate", "")))
    print(f"📋 {len(tasks)} pending tasks:\n")
    for t in tasks:
        start = ""
        if t.get("startDate"):
            start = "  — start " + t["startDate"][:10]
        p = PRIORITY_TAG.get(t.get("priority", 0), "     ")
        print(f"  ○ {p}{start}: {t['title']}\n     id: {t['id']}\n")


def cmd_add(args):
    if not args:
        print("ERROR: title required", file=sys.stderr); sys.exit(1)
    title = args[0]; args = args[1:]
    project = "inbox"; priority = 0; start = ""; notes = ""; tags = ""
    i = 0
    while i < len(args):
        if args[i] == "--project":
            project = args[i + 1]; i += 2
        elif args[i] == "--priority":
            priority = priority_val(args[i + 1]); i += 2
        elif args[i] == "--start":
            start = args[i + 1] + TZ_OFFSET; i += 2
        elif args[i] == "--notes":
            notes = args[i + 1]; i += 2
        elif args[i] == "--tag":
            tags = args[i + 1]; i += 2
        else:
            print(f"ERROR: Unknown option {args[i]}", file=sys.stderr); sys.exit(1)
    project_id = resolve_project(project)
    body = {
        "title": title,
        "projectId": project_id,
        "priority": priority,
        "timeZone": TIMEZONE,
    }

    if start:
        body["startDate"] = start
    else:
        print("⚠️  No start date set. Use --start YYYY-MM-DDTHH:MM:SS to set one.")

    if notes:
        body["content"] = notes

    if tags:
        body["tags"] = [t.strip() for t in tags.split(",")]



    d = _post("/task", body)

    if "errorCode" in d:
        print(f"ERROR: {d['errorMessage']}", file=sys.stderr); sys.exit(1)

    start_str = f"  start {d['startDate'][:10]}" if d.get("startDate") else " . . . No start date"

    plabel = PRIORITY_LABEL.get(d.get("priority", 0), "none")

    print(f"✅ Created: {d['title']}{start_str} [{plabel} priority]")
    print(f"   id: {d['id']}")


def cmd_complete(args):
    if not args:
        print("ERROR: taskId required", file=sys.stderr); sys.exit(1)
    task_id = args[0]; args = args[1:]
    project_id = ""
    i = 0
    while i < len(args):
        if args[i] == "--project":
            project_id = resolve_project(args[i + 1]); i += 2
        else:
            print(f"ERROR: Unknown option {args[i]}", file=sys.stderr); sys.exit(1)
    if not project_id:
        project_id = INBOX_ID
    _post(f"/project/{project_id}/task/{task_id}/complete", {})
    print(f"✅ Task {task_id} marked complete")


def cmd_delete(args):
    if not args:
        print("ERROR: taskId required", file=sys.stderr); sys.exit(1)
    task_id = args[0]; args = args[1:]
    project_id = ""
    i = 0
    while i < len(args):
        if args[i] == "--project":
            project_id = resolve_project(args[i + 1]); i += 2
        else:
            print(f"ERROR: Unknown option {args[i]}", file=sys.stderr); sys.exit(1)
    if not project_id:
        project_id = INBOX_ID
    _del(f"/project/{project_id}/task/{task_id}")
    print(f"🗑️  Task {task_id} deleted")


def cmd_update(args):
    if not args:
        print("ERROR: taskId required", file=sys.stderr); sys.exit(1)
    task_id = args[0]; args = args[1:]
    project_id = INBOX_ID; title = ""; priority = ""; start = ""
    i = 0
    while i < len(args):
        if args[i] == "--project":
            project_id = resolve_project(args[i + 1]); i += 2
        elif args[i] == "--title":
            title = args[i + 1]; i += 2
        elif args[i] == "--priority":
            priority = priority_val(args[i + 1]); i += 2
        elif args[i] == "--start":
            start = args[i + 1] + TZ_OFFSET; i += 2
        else:
            print(f"ERROR: Unknown option {args[i]}", file=sys.stderr); sys.exit(1)
    body = {"id": task_id, "projectId": project_id}
    if title:
        body["title"] = title
    if priority != "":
        body["priority"] = int(priority)
    if start:
        body["startDate"] = start
    d = _post(f"/task/{task_id}", body)
    if "errorCode" in d:
        print(f"ERROR: {d['errorMessage']}", file=sys.stderr); sys.exit(1)
    print(f"✅ Updated: {d.get('title', 'task')}")


def cmd_add_project(args):
    if not args:
        print("ERROR: name required", file=sys.stderr); sys.exit(1)
    name = args[0]; args = args[1:]
    color = "#4A90E2"
    i = 0
    while i < len(args):
        if args[i] == "--color":
            color = args[i + 1]; i += 2
        else:
            print(f"ERROR: Unknown option {args[i]}", file=sys.stderr); sys.exit(1)
    d = _post("/project", {"name": name, "color": color, "viewMode": "list"})
    if "errorCode" in d:
        print(f"ERROR: {d['errorMessage']}", file=sys.stderr); sys.exit(1)
    print(f"✅ Project created: {d['name']} (id: {d['id']})")


def cmd_delete_project(args):
    if not args:
        print("ERROR: projectId required", file=sys.stderr); sys.exit(1)
    _del(f"/project/{args[0]}")
    print(f"🗑️  Project {args[0]} deleted")


# ── Usage ───────────────────────────────────────────────────────────────────────

USAGE = """\
Usage: tt.py <command> [options]

Commands:
  projects/project                       List all projects
  tasks/task [--project <name|id>]       List tasks (default: inbox)
  add <title> [options]             Create a task
    --project <name|id>             Target project (default: inbox)
    --priority <none|low|med|high>  Priority
    --start <YYYY-MM-DDTHH:MM:SS>     start date (+08:00 appended)
    --notes <text>                  Description
    --tag <tag1,tag2>               Tags (comma-separated)
  complete <taskId> --project <id>  Mark task complete
  delete <taskId> --project <id>    Delete task
  update <taskId> --project <id> [--title X] [--priority X] [--start X]
  add-project <name> [--color #hex] Create project
  delete-project <id>               Delete project"""

COMMANDS = {
    "projects": cmd_projects,
    "project": cmd_projects,
    "tasks": cmd_tasks,
    "task": cmd_tasks,
    "add": cmd_add,
    "complete": cmd_complete,
    "delete": cmd_delete,
    "update": cmd_update,
    "add-project": cmd_add_project,
    "delete-project": cmd_delete_project,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(USAGE, file=sys.stderr)
        sys.exit(1)
    cmd = sys.argv[1]
    COMMANDS[cmd](sys.argv[2:])


if __name__ == "__main__":
    main()
