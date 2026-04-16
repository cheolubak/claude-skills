---
name: tailwind-patterns
description: "Tailwind CSS + CSS 변수 패턴. 테마 시스템, 반응형 디자인, 다크모드, 애니메이션 가이드.\nTRIGGER when: \"스타일 입혀줘\", \"디자인 적용\", \"다크모드\", \"반응형\", \"테마 설정\", \"tailwind\", \"CSS 변수\", \"색상 시스템\", \"모바일 대응\", 스타일링/테마/반응형 디자인 작업 시.\nSKIP: 컴포넌트 구조는 nextjs-shadcn. JS 기반 복잡한 애니메이션은 framer-motion."
---

> 참조:
> - [references/theme-system.md](references/theme-system.md) - CSS 변수 전체 목록, 커스텀 색상 추가, 다크모드 설정
> - [references/layouts.md](references/layouts.md) - 브레이크포인트, Flex/Grid 패턴, 컨테이너, 반응형 타이포그래피
> - [references/animations.md](references/animations.md) - CSS 애니메이션, View Transitions, Motion, GSAP, Lenis
> - [references/utilities.md](references/utilities.md) - cn(), cva, 배경 패턴, 스크롤, 오버레이 등 유틸리티

# Tailwind CSS 패턴 가이드

## 1. CSS 변수 기반 테마 시스템

### globals.css 설정

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --primary: 240 5.9% 10%;
    --primary-foreground: 0 0% 98%;
    --secondary: 240 4.8% 95.9%;
    --secondary-foreground: 240 5.9% 10%;
    --muted: 240 4.8% 95.9%;
    --muted-foreground: 240 3.8% 46.1%;
    --accent: 240 4.8% 95.9%;
    --accent-foreground: 240 5.9% 10%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 5.9% 90%;
    --ring: 240 5.9% 10%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --primary: 0 0% 98%;
    --primary-foreground: 240 5.9% 10%;
    /* ... */
  }
}
```

### 커스텀 브랜드 색상 추가

```css
:root {
  --brand: 220 90% 56%;
  --brand-foreground: 0 0% 100%;
  --success: 142 76% 36%;
  --success-foreground: 0 0% 100%;
  --warning: 38 92% 50%;
  --warning-foreground: 0 0% 100%;
}
```

```ts
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        brand: "hsl(var(--brand))",
        "brand-foreground": "hsl(var(--brand-foreground))",
        success: "hsl(var(--success))",
        warning: "hsl(var(--warning))",
      },
    },
  },
};
```

## 2. 하드코딩 색상 금지

```tsx
// ✅ 좋음 - 테마 변수
<div className="bg-primary text-primary-foreground" />
<div className="bg-muted text-muted-foreground" />
<div className="border-border" />
<div className="bg-brand text-brand-foreground" />

// ❌ 나쁨 - 하드코딩
<div className="bg-blue-500 text-white" />
<div className="bg-[#1a1a1a]" />
<div className="text-gray-600" />
```

## 3. 반응형 디자인

### 모바일 퍼스트

```tsx
<div className="
  grid grid-cols-1        // 모바일: 1열
  md:grid-cols-2          // 태블릿: 2열
  lg:grid-cols-3          // 데스크톱: 3열
  gap-4 md:gap-6 lg:gap-8
">
```

### 컨테이너 패턴

```tsx
// 좋음 - 일관된 컨테이너
<div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">

// 또는 Tailwind container
<div className="container mx-auto px-4">
```

### 반응형 타이포그래피

```tsx
<h1 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold" />
<p className="text-sm md:text-base" />
```

## 4. 다크모드

```tsx
// next-themes 사용
import { ThemeProvider } from "next-themes";

// layout.tsx
<ThemeProvider attribute="class" defaultTheme="system" enableSystem>
  {children}
</ThemeProvider>

// 컴포넌트에서 (CSS 변수로 자동 전환)
<div className="bg-background text-foreground" />

// 명시적 다크모드 스타일이 필요한 경우
<div className="bg-white dark:bg-gray-900" />
```

## 5. 애니메이션

### Tailwind 내장

```tsx
<div className="transition-colors duration-200 hover:bg-accent" />
<div className="transition-transform hover:scale-105" />
<div className="animate-pulse" />  // 스켈레톤
<div className="animate-spin" />   // 로딩 스피너
```

### 커스텀 애니메이션

```css
/* globals.css */
@keyframes slide-up {
  from { transform: translateY(10px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}
```

```ts
// tailwind.config.ts
animation: {
  "slide-up": "slide-up 0.3s ease-out",
  "fade-in": "fade-in 0.2s ease-out",
},
```

## 6. 레이아웃 패턴

### Flexbox

```tsx
// 중앙 정렬
<div className="flex items-center justify-center" />

// 양쪽 정렬
<div className="flex items-center justify-between" />

// 세로 스택
<div className="flex flex-col gap-4" />
```

### Grid

```tsx
// 자동 채우기
<div className="grid grid-cols-[repeat(auto-fill,minmax(250px,1fr))] gap-4" />

// 사이드바 레이아웃
<div className="grid grid-cols-[250px_1fr] gap-6" />
```

## 7. cn() 유틸리티

```tsx
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// 사용
function Badge({ variant, className }: BadgeProps) {
  return (
    <span className={cn(
      "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium",
      variant === "success" && "bg-success text-success-foreground",
      variant === "warning" && "bg-warning text-warning-foreground",
      variant === "error" && "bg-destructive text-destructive-foreground",
      className // 외부에서 오버라이드 가능
    )} />
  );
}
```

## 8. 스크롤바 숨기기

```bash
pnpm add tailwind-scrollbar-hide
```

```tsx
<div className="overflow-y-auto scrollbar-hide">
  {/* 스크롤 가능하지만 스크롤바 숨김 */}
</div>
```

## 9. 자주 쓰는 패턴

```tsx
// 텍스트 줄임
<p className="truncate" />              // 한 줄
<p className="line-clamp-2" />          // 두 줄

// 비율 유지 이미지
<div className="aspect-video relative">
  <Image src={src} alt={alt} fill className="object-cover" />
</div>

// 구분선
<div className="h-px bg-border" />

// 오버레이
<div className="fixed inset-0 bg-background/80 backdrop-blur-sm" />

// 포커스 링
<button className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" />
```
