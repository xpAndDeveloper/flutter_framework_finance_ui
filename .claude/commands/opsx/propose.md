---
name: "OPSX: Propose"
description: Propose a new change - create it and generate all artifacts in one step
category: Workflow
tags: [workflow, artifacts, experimental]
---

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- design.md (how)
- tasks.md (implementation steps)

When ready to implement, run /opsx:apply

---

**Input**: The argument after `/opsx:propose` is the change name (kebab-case), OR a description of what the user wants to build.

**Steps**

1. If no input provided, use **AskUserQuestion** to ask what they want to build.

2. Create the change: `openspec new change "<name>"`

3. Get artifact build order: `openspec status --change "<name>" --json`

4. Create artifacts in sequence until apply-ready:
   - Get instructions: `openspec instructions <artifact-id> --change "<name>" --json`
   - Create artifact file using `template` as structure
   - Apply `context` and `rules` as constraints — do NOT copy them into the file

5. Show final status: `openspec status --change "<name>"`

**Guardrails**
- Create ALL artifacts needed for implementation
- Always read dependency artifacts before creating a new one
- Verify each artifact file exists after writing before proceeding
