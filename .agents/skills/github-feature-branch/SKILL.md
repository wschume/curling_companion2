---
name: github-feature-branch
description: Create and switch to a dedicated branch before implementing a new feature in the curling_companion repository, including work from its GitHub Project or issues.
---

Apply this skill only in the curling_companion repository. Before changing project files for a new feature, create and check out a dedicated feature branch.

- Read applicable repository instructions and inspect the current branch, worktree status, and remotes. Use the repository's branch naming and base-branch conventions, and include the ticket ID in the branch name. Otherwise use `feature/<ticket-id>-<short-feature-name>`, for example `feature/123-shot-history` for GitHub issue #123 or `feature/CC-123-shot-history` for ticket CC-123. Resolve the ID from the linked ticket or task context; never invent one. If the work has no associated ticket, use `feature/<short-feature-name>`.
- If the user provided a branch name or base, use it. Otherwise branch from the repository's intended development base; do not assume the base is named `main`.
- Create and switch with `git switch -c <branch> <base>`. Verify the active branch before making feature edits.
- If already on the branch for this same feature, continue there rather than creating another branch. For a different feature, create a new branch even if the current branch is a feature branch.
- Preserve existing uncommitted work. Do not reset, discard, or automatically stash changes to switch branches. If unrelated work would be carried onto the new branch or switching would overwrite changes, use an isolated worktree when practical; otherwise ask how to handle those changes before proceeding.
- Do not overwrite an existing branch. Reuse it only when it clearly belongs to this feature; otherwise choose an unused name.
- Report the selected branch briefly, then continue the requested feature work. Creating a local branch does not authorize pushing, opening a pull request, or merging.

Honor explicit user instructions to stay on a particular branch. Do not create branches merely for read-only investigation or review.
