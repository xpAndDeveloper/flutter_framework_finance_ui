---
name: "OPSX: Apply"
description: Implement tasks from an OpenSpec change (Experimental)
category: Workflow
tags: [workflow, artifacts, experimental]
---

Implement tasks from an OpenSpec change.

**Input**: Optionally specify a change name (e.g., `/opsx:apply add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/opsx:apply <other>`).

2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```

3. **Get apply instructions**
   ```bash
   openspec instructions apply --change "<name>" --json
   ```

4. **Read context files** — every file path listed under `contextFiles`

5. **Show current progress** — schema, N/M tasks complete, remaining overview

6. **Implement tasks (loop until done or blocked)**
   - Mark task complete: `- [ ]` → `- [x]`
   - Pause if unclear, blocked, or user interrupts

7. **On completion or pause, show status**

**Guardrails**
- Keep going through tasks until done or blocked
- Always read context files before starting
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements - don't guess
