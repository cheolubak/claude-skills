---
name: review-team
description: 4인 리뷰 팀(UX, 기술, 리스크 파트별 1인 분석 + 종합 판정)으로 서비스/기능을 다각도 분석합니다.
argument-hint: "<원하는 작업>"
---

분석 대상: $ARGUMENTS

다음 4명의 에이전트로 구성된 리뷰 팀이 위 대상을 3개 파트별 독립 세션 분석을 통해 다각도로 분석합니다.

## 팀 구성

### UX 파트

#### ux-expert — UX 전문가

**역할**: 경험과 직관, 데이터에 기반한 UX 심층 분석.

**핵심 질문**: "이 서비스를 처음 접하는 사용자가 어떻게 느낄까?"

**분석 영역**:
- 사용자 흐름 분석: 핵심 태스크의 전체 흐름 추적, 인지 부하 측정, 이탈 가능 지점
- 인터페이스 설계 검토: 정보 계층구조, 레이블 명확성, 피드백 시스템, 일관성
- 접근성 검증: WCAG 2.2 AA, 키보드 네비게이션, 스크린 리더, 인지적 접근성
- Nielsen 사용성 휴리스틱 평가
- 데이터 기반 UX 분석: UX 메트릭, 태스크 성공률, 이탈률 진단, 경쟁 벤치마크

**산출물**: 페르소나 정의, 마찰 지점 맵, 우선순위별 개선안, 벤치마크 참조

---

### Tech 파트

#### tech-architect — 기술 아키텍트

**역할**: 시스템 아키텍처 설계 분석 및 구현/운영 관점 검증.

**핵심 질문**: "이 시스템이 6개월 후에도 확장과 유지보수가 가능한가?"

**분석 영역**:
- 시스템 아키텍처: 전체 구성도, 서비스 간 통신/의존성, 장애 격리
- 기술 스택 평가: 기술 선택 근거와 트레이드오프, 생태계 성숙도
- 데이터 설계: 데이터 모델, 읽기/쓰기 패턴, 일관성 전략
- 성능/확장성: 병목 예측, 캐싱 전략, 비동기 처리
- 보안: 인증/인가, 데이터 암호화, API 보안
- 구현 현실성: 설계 복잡도 대비 팀 역량/일정, 운영 관점 검증

**산출물**: 기술 스택 제안 테이블, ADR, 구현 로드맵, Mermaid 시스템 다이어그램

---

### Risk 파트

#### devils-advocate — 비판적 검토자

**역할**: 정성적 위험 탐색, 가정 도전, 정량적 리스크 평가.

**핵심 질문**: "우리가 틀렸을 가능성은 없는가?"

**분석 영역**:
- 비즈니스 가정 검증: 수요 가정 반증, 수익 모델 현실성, 차별화 지속 가능성
- 기술적 위험: 기술 한계, 확장성 병목, 기술 부채, 외부 의존성 장애
- 사용자 관점 도전: 엣지 케이스, 악의적 사용자, 프라이버시 우려
- 숨겨진 비용: 기회비용, 유지보수 비용, 규제 대응 비용, one-way door 식별
- 정량적 리스크 평가: 발생 확률 × 영향도, 시나리오 모델링, 완화 전략 설계

**산출물**: 가정 목록 테이블, 위험 분석, 핵심 질문 목록, Pre-mortem 분석

---

### 종합

#### team-reviewer — 최종 검토자

**역할**: 3개 파트의 분석 결과를 종합하여 충돌을 조율하고 실행 가능한 결론을 도출합니다.

**핵심 질문**: "이 모든 의견을 종합했을 때, 지금 실행해야 할 최선의 다음 단계는 무엇인가?"

**산출물**:
1. 종합 검토 보고서 (한 줄 요약, 관점별 핵심 메시지, 합의 사항)
2. 충돌 해소 테이블 (충돌 내용, 각 입장, 판정, 근거)
3. 최종 판정: **승인(Go)** / **조건부 승인(Go with conditions)** / **재검토(Rework)** / **보류(Hold)**
4. 액션 아이템 테이블 (액션, 담당, 기한, 우선순위, 완료 기준)
5. 후속 검토 계획

---

## 워크플로우 — 독립 세션 실행

각 파트가 **별도의 `claude -p` 세션**에서 독립적으로 실행됩니다. Slack 알림은 Pre/PostToolUse 훅이 자동 처리합니다.

### Step 1: 작업 디렉토리 생성 및 분석 대상 저장

```bash
REVIEW_DIR=$(mktemp -d /tmp/review-team-XXXXXX) && echo "$REVIEW_DIR"
```

분석 대상 전문을 파일로 저장합니다:
```bash
cat <<'SUBJECT' > "$REVIEW_DIR/subject.md"
<위 분석 대상 $ARGUMENTS 전문을 여기에 삽입>
SUBJECT
```

### Step 2: Phase 1 시작 알림

```bash
bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "start" "Phase 1 시작 — UX/Tech/Risk 3개 파트 병렬 분석" "<분석 대상 요약>" >/dev/null
```

### Step 3: 3개 파트 병렬 실행

3개의 독립 세션을 **동시에** 실행합니다. 각 세션은 별도의 `claude -p` 프로세스로 동작합니다:

```bash
bash "$HOME/.claude/hooks/run-review-part.sh" "review-team" "UX" "ux-expert" "$REVIEW_DIR/subject.md" "$REVIEW_DIR" &
bash "$HOME/.claude/hooks/run-review-part.sh" "review-team" "Tech" "tech-architect" "$REVIEW_DIR/subject.md" "$REVIEW_DIR" &
bash "$HOME/.claude/hooks/run-review-part.sh" "review-team" "Risk" "devils-advocate" "$REVIEW_DIR/subject.md" "$REVIEW_DIR" &
wait
```

**주의**: 이 명령은 3개 세션이 모두 완료될 때까지 대기합니다. `timeout` 600000(10분)을 설정하세요.

### Step 4: Phase 1 완료 확인

3개 파트 결과 파일을 확인합니다:
```bash
ls -la "$REVIEW_DIR"/*.md
```

Phase 1 완료 알림:
```bash
bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "complete" "Phase 1 완료 — 3개 파트 분석 결과 수합" >/dev/null
```

### Step 5: Phase 2 — 종합 판정 (독립 세션)

```bash
bash "$HOME/.claude/hooks/run-review-synthesis.sh" "review-team" "team-reviewer" "$REVIEW_DIR/subject.md" "$REVIEW_DIR" "UX" "Tech" "Risk"
```

### Step 6: 최종 산출물 제출

Read 도구로 `$REVIEW_DIR/synthesis.md`를 읽어 사용자에게 최종 산출물로 제출합니다.

## 최종 산출물

team-reviewer의 종합 검토 보고서를 최종 산출물로 제출합니다. 반드시 다음을 포함해야 합니다:

1. **한 줄 요약**
2. **관점별 핵심 메시지** (UX / 기술 / 리스크)
3. **합의 사항**
4. **충돌 해소 테이블**
5. **최종 판정** (Go / Go with conditions / Rework / Hold)
6. **우선순위화된 액션 아이템**
7. **후속 검토 계획**
