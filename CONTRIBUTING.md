# Contributing

Thanks for helping improve `myRecepies`.

This repository is organized around one router skill plus several focused sub-skills and shared reference materials, so contributions should stay focused, easy to review, and easy to verify.

## What to change

- `skills/my-recipe/SKILL.md` for the main behavior, workflows, and output rules.
- `skills/my-recipe/{planning,inventory,equipment,timeline,rescue}/SKILL.md` for the focused skill trees.
- `skills/my-recipe/references/*.md` for reusable knowledge like units, equipment, rescue decisions, and rescue guidance.
- `skills/my-recipe/scripts/*` for deterministic helpers that should not be re-derived every time.
- `README.md` for the project overview and the contribution entry point.
- `tests/skill-triggering/` for prompt-driven trigger tests.

## Recommended workflow

1. Create a branch for your change.
2. Keep the change narrow: one behavior, one clarification, or one reference update at a time.
3. If you add a new cooking pattern, include a concrete example in `SKILL.md`.
4. If you change a number, unit, or kitchen assumption, update the matching reference file.
5. Prefer edits that improve both the user-facing prompt quality and the internal consistency of the skill.
6. Review the result by reading the full skill top to bottom and checking that the examples still match the rules.
7. If you add or rename a sub-skill, update the trigger tests and the README tree.

## Editing guidelines

- Keep the skill practical and operational, not just descriptive.
- Preserve the existing Chinese-first voice unless a specific section is better served by English.
- Make sure every recipe step that mentions an ingredient still shows the quantity.
- Keep checklist formatting consistent with `[ ]` and `[x]`.
- Avoid adding overlapping rules that contradict the current workflows.

## Good contribution examples

- Add a new scenario example for a common cooking request.
- Improve the rescue flow for a specific kitchen failure.
- Expand the equipment adaptation rules with a clearer scaling example.
- Tighten wording so the assistant asks better follow-up questions before generating a shopping list.

## Before opening a PR

- Confirm the README still points to the right files.
- Make sure no example conflicts with the reference documents.
- Double-check that any new terminology is used consistently in both the skill and the references.
- Run the skill-triggering tests and confirm the expected leaf skill is the one that fires.

## If you are unsure

- Prefer a smaller change over a larger rewrite.
- If the change affects cooking logic, add one example that shows the new behavior in action.
