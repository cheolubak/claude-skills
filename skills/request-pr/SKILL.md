---
name: request-pr
description: "지정 브랜치로 GitHub PR 생성. 커밋 히스토리 분석으로 한글 PR 제목/본문 자동 작성.\nTRIGGER when: \"PR 만들어줘\", \"풀 리퀘스트\", \"PR 올려줘\", \"코드 리뷰 요청\", GitHub PR 생성 시.\nSKIP: 코드 리뷰 자체는 review-team. worktree 머지는 merge-worktree."
argument-hint: "<대상 브랜치 (예: main, develop)>"
disable-model-invocation: true
---

# Request PR

현재 브랜치의 커밋 히스토리를 분석하여 지정한 대상 브랜치로 GitHub PR을 한글로 생성합니다.

## Current context

- Current branch: `!git branch --show-current`
- Remote: `!git remote -v`
- Recent commits: `!git log --oneline -10`
- Working tree status: `!git status --short`

## Instructions

Follow these phases exactly, in order. Do NOT skip phases.

---

### Phase 1: 유효성 검증

1. **대상 브랜치 확인**: `$ARGUMENTS`가 비어있으면 사용자에게 대상 브랜치를 물어봅니다. 제공된 경우 해당 브랜치를 대상으로 사용합니다.

2. **현재 브랜치 확인**: `git branch --show-current`로 현재 브랜치를 확인합니다. 대상 브랜치와 동일하면 중단하고 사용자에게 알립니다.

3. **미커밋 변경사항 확인**: `git status --porcelain`을 실행합니다. 미커밋 변경사항이 있으면 사용자에게 경고하고 계속할지 물어봅니다.

4. **리모트 확인**: `git remote -v`로 리모트가 설정되어 있는지 확인합니다. 없으면 중단합니다.

5. **gh CLI 확인**: `gh auth status`로 GitHub CLI 인증 상태를 확인합니다. 인증되어 있지 않으면 중단하고 `gh auth login`을 안내합니다.

---

### Phase 2: 커밋 히스토리 분석

1. **대상 브랜치 최신화**: `git fetch origin <대상 브랜치>`를 실행합니다.

2. **커밋 목록 수집**: `git log --oneline origin/<대상 브랜치>..HEAD`로 PR에 포함될 커밋들을 확인합니다.

3. **커밋이 없으면 중단**: 포함될 커밋이 없으면 사용자에게 알리고 중단합니다.

4. **상세 커밋 분석**: `git log --format="%h %s%n%b%n---" origin/<대상 브랜치>..HEAD`로 커밋 메시지와 본문을 상세히 읽습니다.

5. **변경 파일 통계**: `git diff --stat origin/<대상 브랜치>...HEAD`로 변경된 파일 목록과 규모를 파악합니다.

6. **전체 diff 확인**: `git diff origin/<대상 브랜치>...HEAD`로 전체 변경사항을 읽고 이해합니다.

7. **변경사항 분류**: 커밋들을 다음 카테고리로 분류합니다:
   - 새 기능 (feat)
   - 버그 수정 (fix)
   - 리팩토링 (refactor)
   - 문서 (docs)
   - 설정/기타 (chore)
   - 테스트 (test)

---

### Phase 3: PR 내용 작성

분석 결과를 바탕으로 PR 제목과 본문을 **한글로** 작성합니다.

**PR 제목 규칙:**
- 70자 이내
- 변경의 핵심을 한 문장으로 요약
- 좋은 예: `diff-commit 스킬 추가 및 README 업데이트`
- 나쁜 예: `Add diff-commit skill and update README`

**PR 본문 템플릿:**

```markdown
## 요약
<변경사항의 목적과 배경을 2-3문장으로 설명>

## 변경 내용
<카테고리별로 그룹화한 변경사항 목록>

### 새 기능
- 변경1 설명

### 버그 수정
- 변경2 설명

### 기타
- 변경3 설명

## 변경 파일
<주요 변경 파일 목록과 각 파일의 변경 요약>

| 파일 | 변경 | 설명 |
|------|------|------|
| path/to/file.ts | 수정 | 변경 내용 요약 |

## 테스트
- [ ] 테스트 항목1
- [ ] 테스트 항목2

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**본문 작성 규칙:**
- **모든 내용은 한글로 작성** (파일 경로, 코드, 이모지 제외)
- 카테고리에 해당하는 변경이 없으면 해당 섹션 생략
- 커밋 메시지를 그대로 복사하지 말고, 전체적인 맥락에서 재구성
- 테스트 섹션은 리뷰어가 확인해야 할 항목을 체크리스트로 작성

**작성한 PR 내용을 사용자에게 보여주고 확인을 요청합니다.** 사용자가:
- 승인하면 Phase 4로 진행
- 수정을 요청하면 반영 후 다시 확인 요청

**사용자 승인 없이 Phase 4로 진행하지 않습니다.**

---

### Phase 4: PR 생성

1. **리모트에 푸시**: 현재 브랜치가 리모트에 없거나 최신이 아니면 푸시합니다:
   ```bash
   git push -u origin <현재 브랜치>
   ```

2. **PR 생성**: `gh pr create`로 PR을 생성합니다:
   ```bash
   gh pr create --base <대상 브랜치> --title "<PR 제목>" --body "$(cat <<'EOF'
   <PR 본문>
   EOF
   )"
   ```

3. **생성 실패 처리**: 이미 PR이 존재하는 경우:
   - `gh pr list --head <현재 브랜치> --base <대상 브랜치>`로 기존 PR을 확인
   - 기존 PR이 있으면 URL을 보여주고, 업데이트할지 사용자에게 물어봅니다

---

### Phase 5: 결과 보고

1. **PR URL 출력**: 생성된 PR의 URL을 사용자에게 보여줍니다.

2. **요약 출력**:
   ```
   ## PR 생성 완료

   - **PR**: <PR URL>
   - **브랜치**: <현재 브랜치> → <대상 브랜치>
   - **커밋 수**: <N>개
   - **변경 파일**: <N>개
   ```

---

## Important notes

- **모든 PR 내용(제목, 본문)은 반드시 한글로 작성합니다.**
- **사용자 확인 없이 PR을 생성하지 않습니다** (Phase 3에서 반드시 승인 필요).
- `git push --force`는 절대 사용하지 않습니다.
- 예상치 못한 상황이 발생하면 **중단하고 사용자에게 설명**합니다.
