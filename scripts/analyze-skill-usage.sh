#!/usr/bin/env bash
# 스킬 사용 현황 분석 스크립트
# 대화 기록(JSONL 트랜스크립트) + 훅 로그를 분석하여 스킬 히팅율을 출력합니다.
#
# 사용법:
#   bash scripts/analyze-skill-usage.sh              # 전체 분석
#   bash scripts/analyze-skill-usage.sh --project     # 프로젝트별 분석
#   bash scripts/analyze-skill-usage.sh --recent 7    # 최근 N일
#   bash scripts/analyze-skill-usage.sh --sessions    # 세션 대비 히팅율

exec python3 - "$@" <<'PYTHON_SCRIPT'
import sys, json, os, glob
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

CLAUDE_DIR = os.path.expanduser("~/.claude")
PROJECTS_DIR = os.path.join(CLAUDE_DIR, "projects")
HOOK_LOG = os.path.join(CLAUDE_DIR, "skill-usage.jsonl")

# 색상
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RESET = "\033[0m"

def parse_args():
    mode = "all"
    recent_days = 0
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--project":
            mode = "project"
        elif args[i] == "--recent":
            i += 1
            recent_days = int(args[i]) if i < len(args) else 7
        elif args[i] == "--sessions":
            mode = "sessions"
        elif args[i] == "--hook-only":
            mode = "hook"
        elif args[i] in ("--help", "-h"):
            print("사용법: analyze-skill-usage.sh [옵션]")
            print()
            print("옵션:")
            print("  --project       프로젝트별 스킬 사용 분석")
            print("  --recent N      최근 N일 데이터만 분석 (기본: 전체)")
            print("  --sessions      세션 대비 스킬 히팅율 분석")
            print("  --hook-only     훅 로그만 분석 (실시간 추적 데이터)")
            print("  --help, -h      도움말")
            sys.exit(0)
        i += 1
    return mode, recent_days

def extract_from_transcripts():
    """대화 기록 JSONL에서 Skill tool_use 추출"""
    results = []
    jsonl_files = glob.glob(os.path.join(PROJECTS_DIR, "*", "*.jsonl"))
    for jsonl_path in jsonl_files:
        project_dir = os.path.basename(os.path.dirname(jsonl_path))
        try:
            with open(jsonl_path, "r") as f:
                for line in f:
                    if '"Skill"' not in line:
                        continue
                    try:
                        d = json.loads(line.strip())
                        msg = d.get("message", {})
                        contents = msg.get("content", [])
                        ts = d.get("timestamp", "")
                        session = d.get("sessionId", "")
                        for c in contents:
                            if c.get("type") == "tool_use" and c.get("name") == "Skill":
                                inp = c.get("input", {})
                                skill = inp.get("skill", "")
                                args = inp.get("args", "")
                                if skill:
                                    results.append({
                                        "skill": skill,
                                        "args": args,
                                        "timestamp": ts,
                                        "session": session,
                                        "project": project_dir,
                                        "source": "transcript",
                                    })
                    except (json.JSONDecodeError, KeyError):
                        pass
        except (IOError, PermissionError):
            pass
    return results

def extract_from_hook_log():
    """훅 로그에서 추출"""
    results = []
    if os.path.exists(HOOK_LOG):
        try:
            with open(HOOK_LOG, "r") as f:
                for line in f:
                    try:
                        d = json.loads(line.strip())
                        d["source"] = "hook"
                        results.append(d)
                    except json.JSONDecodeError:
                        pass
        except IOError:
            pass
    return results

def count_total_sessions():
    """전체 세션 수 집계"""
    sessions = set()
    jsonl_files = glob.glob(os.path.join(PROJECTS_DIR, "*", "*.jsonl"))
    for f in jsonl_files:
        name = os.path.basename(f).replace(".jsonl", "")
        sessions.add(name)
    return len(sessions)

def clean_project_name(name):
    """프로젝트 경로에서 가독성 있는 이름 추출"""
    name = name.replace("-Users-dabot-Documents-develop-", "")
    name = name.replace("-Users-dabot-Documents-", "~/")
    name = name.replace("-Users-dabot-", "~/")
    name = name.split("--claude-worktrees")[0]
    return name or "unknown"

def print_bar(count, max_count, width=25):
    bar_len = int(count / max_count * width) if max_count > 0 else 0
    return "█" * bar_len + "░" * (width - bar_len)

def run():
    mode, recent_days = parse_args()

    print(f"{BOLD}{CYAN}━━━ Claude Skills 사용 현황 분석 ━━━{RESET}")
    print()

    # 데이터 수집
    if mode == "hook":
        all_data = extract_from_hook_log()
    else:
        all_data = extract_from_transcripts() + extract_from_hook_log()

    # 날짜 필터
    if recent_days > 0:
        cutoff = (datetime.now(timezone.utc) - timedelta(days=recent_days)).strftime("%Y-%m-%dT%H:%M:%SZ")
        all_data = [d for d in all_data if d.get("timestamp", "") >= cutoff]
        print(f"{DIM}(최근 {recent_days}일 데이터만 분석){RESET}")
        print()

    total_calls = len(all_data)
    if total_calls == 0:
        print(f"{YELLOW}스킬 사용 기록이 없습니다.{RESET}")
        return

    if mode in ("all", "hook"):
        # ─── 전체 요약 ───
        skills = Counter(d["skill"] for d in all_data)
        timestamps = sorted(d["timestamp"] for d in all_data if d.get("timestamp"))

        print(f"{BOLD}[전체 요약]{RESET}")
        print(f"  총 스킬 호출 횟수: {GREEN}{total_calls}{RESET}회")
        print(f"  사용된 스킬 종류: {GREEN}{len(skills)}{RESET}개")
        if timestamps:
            print(f"  기간: {timestamps[0][:10]} ~ {timestamps[-1][:10]}")
        print()

        # ─── 스킬별 사용 빈도 (랭킹) ───
        print(f"{BOLD}[스킬별 사용 빈도]{RESET}")
        max_count = max(skills.values()) if skills else 1
        for i, (skill, count) in enumerate(skills.most_common(), 1):
            pct = count / total_calls * 100
            bar = print_bar(count, max_count)
            print(f"  {i:2d}. {skill:<30s} {bar} {count:3d}회 ({pct:5.1f}%)")
        print()

        # ─── 데이터 소스별 ───
        sources = Counter(d.get("source", "unknown") for d in all_data)
        labels = {"transcript": "대화 기록 (과거)", "hook": "훅 로그 (실시간)"}
        print(f"{BOLD}[데이터 소스]{RESET}")
        for src, count in sources.most_common():
            label = labels.get(src, src)
            print(f"  - {label}: {count}회")
        print()

        # ─── 월별 트렌드 ───
        months = Counter()
        for d in all_data:
            ts = d.get("timestamp", "")
            if len(ts) >= 7:
                months[ts[:7]] += 1

        print(f"{BOLD}[월별 사용 트렌드]{RESET}")
        if not months:
            print("  데이터 없음")
        else:
            max_m = max(months.values())
            for month in sorted(months.keys()):
                count = months[month]
                bar_len = int(count / max_m * 30) if max_m > 0 else 0
                bar = "▓" * bar_len + "░" * (30 - bar_len)
                print(f"  {month}  {bar} {count:3d}회")

    elif mode == "project":
        # ─── 프로젝트별 분석 ───
        print(f"{BOLD}[프로젝트별 스킬 사용]{RESET}")
        project_skills = defaultdict(Counter)
        for d in all_data:
            proj = clean_project_name(d.get("project", "unknown"))
            project_skills[proj][d["skill"]] += 1

        for proj in sorted(project_skills.keys()):
            skill_counts = project_skills[proj]
            total = sum(skill_counts.values())
            print()
            print(f"  {proj} ({total}회)")
            for skill, count in skill_counts.most_common():
                pct = count / total * 100
                print(f"     {skill:<28s} {count:3d}회 ({pct:5.1f}%)")

    elif mode == "sessions":
        # ─── 세션 대비 히팅율 ───
        total_sessions = count_total_sessions()
        skill_sessions = defaultdict(set)
        all_sessions = set()
        for d in all_data:
            s = d.get("session", "")
            if s:
                all_sessions.add(s)
                skill_sessions[d["skill"]].add(s)

        skill_session_count = len(all_sessions)

        print(f"{BOLD}[세션 대비 스킬 히팅율]{RESET}")
        print(f"  총 세션 수: {GREEN}{total_sessions}{RESET}")
        print(f"  스킬 사용 세션 수: {GREEN}{skill_session_count}{RESET}")

        if total_sessions > 0:
            hit_rate = skill_session_count / total_sessions * 100
            print(f"  전체 히팅율: {GREEN}{hit_rate:.1f}%{RESET} ({skill_session_count}/{total_sessions} 세션)")
            print()
            print(f"  {BOLD}[스킬별 세션 히팅율]{RESET}")
            for skill in sorted(skill_sessions.keys(), key=lambda s: len(skill_sessions[s]), reverse=True):
                s_count = len(skill_sessions[skill])
                s_rate = s_count / total_sessions * 100
                bar = print_bar(s_count, total_sessions, 20)
                print(f"    {skill:<28s} {bar} {s_count:3d} 세션 ({s_rate:5.1f}%)")

    print()
    print(f"{DIM}━━━ 분석 완료 ━━━{RESET}")

run()
PYTHON_SCRIPT
