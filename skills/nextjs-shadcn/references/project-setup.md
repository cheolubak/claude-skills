# 프로젝트 설정

## 새 프로젝트 생성

### 프리셋 사용 (권장)

```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=nova&baseColor=neutral&iconLibrary=lucide&font=geist-sans" \
  --template next
```

### 프리셋 URL 전체 옵션

```
https://ui.shadcn.com/init?
  base=radix|base-ui
  &style=vega|nova|maia|lyra|mira
  &baseColor=neutral|slate|gray|zinc|stone
  &theme=neutral|blue|green|orange|red|rose|violet
  &iconLibrary=lucide|tabler|hugeicons|phosphor
  &font=geist-sans|inter|noto-sans|nunito-sans|figtree|roboto|raleway|dm-sans|public-sans|outfit|jetbrains-mono
  &menuAccent=subtle|bold
  &menuColor=default|accent
  &radius=default|sm|md|lg|xl
  &template=next
  &rtl=false|true
```

### 프리셋 예시

**Classic (vega + inter)** — 전통적인 shadcn/ui 룩:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=vega&baseColor=zinc&iconLibrary=lucide&font=inter" \
  --template next
```

**Compact (nova + geist-sans)** — 줄어든 패딩, 모던한 느낌:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=nova&baseColor=neutral&iconLibrary=lucide&font=geist-sans" \
  --template next
```

**Soft (maia + figtree)** — 둥글고 넉넉한 여백:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=maia&baseColor=stone&iconLibrary=phosphor&font=figtree&radius=lg" \
  --template next
```

**Sharp (lyra + jetbrains-mono)** — 각진, 기술적 스타일:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=lyra&baseColor=slate&iconLibrary=lucide&font=jetbrains-mono&radius=sm" \
  --template next
```

**Dense (mira + dm-sans)** — 밀도 높은 데이터 인터페이스:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=mira&baseColor=gray&iconLibrary=tabler&font=dm-sans" \
  --template next
```

## 컴포넌트 추가

```bash
# 단일 컴포넌트
bunx --bun shadcn@latest add button

# 여러 컴포넌트
bunx --bun shadcn@latest add button card input

# 모든 컴포넌트
bunx --bun shadcn@latest add --all
```

## 일반적인 의존성

```bash
# 폼
bun add react-hook-form @hookform/resolvers zod

# AI
bun add ai @ai-sdk/anthropic

# 애니메이션
bun add motion              # Motion 용
bun add gsap @gsap/react    # GSAP 용

# 아이콘 (하나 선택)
bun add lucide-react        # 기본값
```

## 설정 후 프로젝트 구조

```
project/
├── app/
│   ├── globals.css         # 테마 토큰
│   ├── layout.tsx          # 루트 레이아웃
│   └── page.tsx            # 홈 페이지
├── components/
│   └── ui/                 # shadcn 컴포넌트
├── lib/
│   └── utils.ts            # cn() 헬퍼
├── public/
├── components.json         # shadcn 설정
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Bun 명령어 참조

| 작업 | 명령어 |
|------|---------|
| 의존성 설치 | `bun install` |
| 패키지 추가 | `bun add package` |
| 개발 서버 | `bun --bun next dev` |
| 빌드 | `bun --bun next build` |
| 프로덕션 시작 | `bun --bun next start` |
| shadcn 컴포넌트 추가 | `bunx --bun shadcn@latest add component` |
| 프로젝트 생성 | `bunx --bun shadcn@latest create ...` |
