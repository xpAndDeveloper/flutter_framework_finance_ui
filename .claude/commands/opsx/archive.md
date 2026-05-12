---
name: "OPSX: Archive"
description: Archive a completed change in the experimental workflow
category: Workflow
tags: [workflow, archive, experimental]
---

Archive a completed change in the experimental workflow.

**Input**: Optionally specify a change name after `/opsx:archive`. If omitted, prompt for selection.

**Steps**

1. If no change name provided, run `openspec list --json` and use **AskUserQuestion** to let the user select.

2. Check artifact completion: `openspec status --change "<name>" --json`

3. Check task completion: read `tasks.md`, count `- [ ]` vs `- [x]`

4. Assess delta spec sync state at `openspec/changes/<name>/specs/`

5. Perform the archive:
   ```bash
   mv openspec/changes/<name> openspec/changes/archive/YYYY-MM-DD-<name>
   ```

6. Display summary.

**Guardrails**
- Always prompt for change selection if not provided
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive
