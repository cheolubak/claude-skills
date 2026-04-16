---
name: diff-commit
description: "현재 변경사항을 분석하여 논리적 작업 단위별로 분리된 커밋을 자동 생성합니다.\nTRIGGER when: \"커밋 정리해줘\", \"변경사항 커밋\", \"커밋 분리\", \"작업별로 커밋\", \"커밋 나눠줘\", 여러 작업이 섞인 변경사항을 논리적으로 정리해서 커밋할 때.\nSKIP: 단순 단일 커밋은 /commit. PR 생성은 request-pr. worktree 머지는 merge-worktree."
argument-hint: "[선택사항: 커밋 범위를 제한할 경로 패턴]"
disable-model-invocation: true
---

# Diff Commit

현재 워킹 트리의 변경사항을 분석하여 논리적 작업 단위별로 분리된 커밋을 자동 생성합니다.

## Current context

- Current branch: `!git branch --show-current`
- Working tree status: `!git status --short`
- Recent commits: `!git log --oneline -10`

## Instructions

Follow these phases exactly, in order. Do NOT skip phases.

---

### Phase 1: Validation

1. **Check for changes**: Run `git status --porcelain`. If there are no changes (staged, unstaged, or untracked), stop and tell the user there is nothing to commit.

2. **Check branch**: Confirm the current branch with `git branch --show-current`. If in detached HEAD state, warn the user and ask if they want to continue.

3. **Stash safety**: If there are both staged and unstaged changes to the same file, note this — it will affect how we stage changes later.

---

### Phase 2: Analyze all changes

This is the most critical phase. You must deeply understand every change before grouping.

1. **List all changed files**: Collect three categories:
   - Staged changes: `git diff --cached --stat`
   - Unstaged changes: `git diff --stat`
   - Untracked files: `git ls-files --others --exclude-standard`

2. **Read the full diff**:
   - Staged: `git diff --cached`
   - Unstaged: `git diff`
   - For untracked files: Read each file with the Read tool

3. **If `$ARGUMENTS` is provided**: Filter the analysis to only files matching the given path pattern. Ignore all other changes.

4. **Understand the context**: For each changed file, understand:
   - What was changed (added, modified, deleted)
   - Why it was changed (feature, fix, refactor, config, docs, test)
   - Which other changes it is related to

---

### Phase 3: Group into logical commits

Based on your Phase 2 analysis, group all changes into logical commit units.

**Grouping rules:**

1. **One concern per commit**: Each commit should represent a single logical change (one feature, one fix, one refactor, etc.)
2. **Dependencies matter**: If change B depends on change A, A must be committed first
3. **Related files together**: Files that serve the same purpose go in the same commit (e.g., a component + its test + its styles)
4. **Config changes separate**: Build/config/tooling changes should be their own commit unless directly tied to a feature
5. **Docs separate**: Documentation changes should be their own commit unless they document a feature in the same batch

**Present the grouping plan to the user:**

```
## Commit Plan

### Commit 1: <type>(<scope>): 한글 요약
- path/to/file1.ts (modified)
- path/to/file2.ts (new)

### Commit 2: <type>(<scope>): 한글 요약
- path/to/file3.ts (modified)

### Commit 3: <type>(<scope>): 한글 요약
- path/to/file4.md (modified)
```

**커밋 계획을 출력한 후 바로 Phase 4로 진행합니다.** 별도 확인을 묻지 않습니다.

단, 다음 경우에만 사용자 확인을 요청합니다:
- 10개 이상의 커밋으로 분리되는 경우
- 민감한 파일(.env, credentials 등)이 포함된 경우

---

### Phase 4: Execute commits sequentially

For each commit group (in dependency order):

1. **Reset staging area** (only if needed): If there are previously staged files that don't belong to this commit:
   ```
   git reset HEAD -- <files-that-dont-belong>
   ```

2. **Stage the files** for this commit:
   - For tracked files (modified/deleted): `git add <file1> <file2> ...`
   - For partial file staging (when only some hunks in a file belong to this commit): Use `git add -p <file>` is NOT available in non-interactive mode. Instead, if a file has changes belonging to multiple commits, commit it with the most relevant group and note this in the commit message.
   - For untracked files: `git add <file>`

3. **Verify staging**: Run `git diff --cached --stat` to confirm only the intended files are staged.

4. **Create the commit** using a heredoc:
   ```bash
   git commit -m "$(cat <<'EOF'
   <type>(<scope>): 한글로 작성한 변경 요약 (72자 이내)

   한글로 무엇을 왜 변경했는지 1-3문장으로 설명합니다.

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

5. **Repeat** for each subsequent commit group.

**Commit message rules:**
- **모든 커밋 메시지는 반드시 한글로 작성** (type, scope, Co-Authored-By 제외)
- `<type>` must be one of: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `style`
- `<scope>` is optional but recommended (e.g., `feat(auth)`, `fix(api)`)
- Summary line: 한글로 작성, 마침표 없이, 72자 이내
  - 좋은 예: `feat(skills): diff-commit 스킬 추가`
  - 나쁜 예: `feat(skills): add diff-commit skill`
- Body: 한글로 *왜* 변경했는지 설명, 단순히 *무엇*을 했는지가 아님
- Always end with `Co-Authored-By`

---

### Phase 5: Verification

1. **Show the result**: Run `git log --oneline -<N>` where N is the number of commits created.

2. **Report summary** (한글로 출력):
   ```
   ## 결과

   <N>개 커밋 생성 완료:
   - <hash> <type>(<scope>): 한글 요약
   - <hash> <type>(<scope>): 한글 요약
   - ...

   미커밋 변경사항: <개수 또는 "없음">
   ```

3. **Check for remaining changes**: Run `git status --short`. If there are still uncommitted changes (files that were intentionally skipped), inform the user.

---

## Important notes

- **Never force-push or use destructive git operations** without explicit user confirmation.
- **Never skip pre-commit hooks** (`--no-verify`).
- **확인 없이 바로 커밋을 진행**합니다. 단, 민감한 파일 포함 또는 10개 이상 커밋 분리 시에만 확인을 요청합니다.
- If a pre-commit hook fails, stop and report the error — do NOT retry with `--no-verify`.
- If `git add -p` (interactive staging) is needed but unavailable, commit the entire file with the most relevant group and clearly note this limitation.
- If anything unexpected happens at any phase, **stop and explain** rather than guessing.
