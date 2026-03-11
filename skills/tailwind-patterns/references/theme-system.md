# Tailwind 테마 시스템 레퍼런스

## CSS 변수 (shadcn/ui)

### 기본 변수

```css
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --card: 0 0% 100%;
    --card-foreground: 240 10% 3.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 240 10% 3.9%;
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
    --input: 240 5.9% 90%;
    --ring: 240 5.9% 10%;
    --radius: 0.5rem;
    --chart-1: 12 76% 61%;
    --chart-2: 173 58% 39%;
    --chart-3: 197 37% 24%;
    --chart-4: 43 74% 66%;
    --chart-5: 27 87% 67%;
  }

  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --card: 240 10% 3.9%;
    --card-foreground: 0 0% 98%;
    --popover: 240 10% 3.9%;
    --popover-foreground: 0 0% 98%;
    --primary: 0 0% 98%;
    --primary-foreground: 240 5.9% 10%;
    --secondary: 240 3.7% 15.9%;
    --secondary-foreground: 0 0% 98%;
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    --accent: 240 3.7% 15.9%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 3.7% 15.9%;
    --input: 240 3.7% 15.9%;
    --ring: 240 4.9% 83.9%;
  }
}
```

### 변수 사용 맵

| 변수 | Tailwind 클래스 | 용도 |
|----------|---------------|---------|
| `--background` | `bg-background` | 페이지 배경 |
| `--foreground` | `text-foreground` | 기본 텍스트 |
| `--primary` | `bg-primary`, `text-primary` | 버튼, CTA, 링크 |
| `--primary-foreground` | `text-primary-foreground` | primary 배경 위 텍스트 |
| `--secondary` | `bg-secondary` | 보조 버튼 |
| `--muted` | `bg-muted` | 은은한 배경 |
| `--muted-foreground` | `text-muted-foreground` | 보조 텍스트, 라벨 |
| `--accent` | `bg-accent` | 호버 상태, 하이라이트 |
| `--destructive` | `bg-destructive` | 삭제, 위험 동작 |
| `--border` | `border-border` | 모든 테두리 |
| `--input` | `border-input` | 입력 필드 테두리 |
| `--ring` | `ring-ring` | 포커스 링 |
| `--radius` | `rounded-*` | 테두리 반경 기본값 |
| `--card` | `bg-card` | 카드 배경 |
| `--popover` | `bg-popover` | 팝오버/드롭다운 배경 |

### 사이드바 변수

```css
:root {
  --sidebar-background: 0 0% 98%;
  --sidebar-foreground: 240 5.3% 26.1%;
  --sidebar-primary: 240 5.9% 10%;
  --sidebar-primary-foreground: 0 0% 98%;
  --sidebar-accent: 240 4.8% 95.9%;
  --sidebar-accent-foreground: 240 5.9% 10%;
  --sidebar-border: 220 13% 91%;
  --sidebar-ring: 240 5.9% 10%;
}
```

---

## 커스텀 색상 추가

### globals.css에 정의

```css
:root {
  --brand: 220 90% 56%;
  --brand-foreground: 0 0% 100%;
  --success: 142 76% 36%;
  --success-foreground: 0 0% 100%;
  --warning: 38 92% 50%;
  --warning-foreground: 0 0% 100%;
  --info: 199 89% 48%;
  --info-foreground: 0 0% 100%;
}

.dark {
  --brand: 220 90% 66%;
  --brand-foreground: 0 0% 100%;
  --success: 142 76% 46%;
  --warning: 38 92% 60%;
  --info: 199 89% 58%;
}
```

### tailwind.config.ts에 등록

```ts
import type { Config } from 'tailwindcss'

export default {
  theme: {
    extend: {
      colors: {
        brand: 'hsl(var(--brand))',
        'brand-foreground': 'hsl(var(--brand-foreground))',
        success: 'hsl(var(--success))',
        'success-foreground': 'hsl(var(--success-foreground))',
        warning: 'hsl(var(--warning))',
        'warning-foreground': 'hsl(var(--warning-foreground))',
        info: 'hsl(var(--info))',
        'info-foreground': 'hsl(var(--info-foreground))',
      },
    },
  },
} satisfies Config
```

### 사용법

```tsx
<div className="bg-brand text-brand-foreground" />
<Badge className="bg-success text-success-foreground">Active</Badge>
<Alert className="bg-warning text-warning-foreground">Warning</Alert>
```

---

## 다크 모드 설정

### next-themes

```bash
bun add next-themes
```

```tsx
// app/layout.tsx
import { ThemeProvider } from 'next-themes'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
```

```tsx
// components/theme-toggle.tsx
'use client'

import { useTheme } from 'next-themes'
import { Button } from '@/components/ui/button'
import { Moon, Sun } from 'lucide-react'

export function ThemeToggle() {
  const { setTheme, theme } = useTheme()

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
    >
      <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
    </Button>
  )
}
```

---

## 하드코딩된 색상: 절대 사용 금지

```tsx
// ❌ 절대 사용 금지
<div className="bg-blue-500 text-white" />
<div className="bg-[#1a1a1a]" />
<div className="text-gray-600" />
<div className="border-slate-200" />

// ✅ 항상 테마 변수를 사용
<div className="bg-primary text-primary-foreground" />
<div className="bg-background" />
<div className="text-muted-foreground" />
<div className="border-border" />
```

---

## 폰트 커스터마이징

```css
:root {
  --font-sans: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-serif: Georgia, serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;
}
```

## 테두리 반경 커스터마이징

```css
:root {
  --radius: 0.5rem;     /* 기본값 */
  /* --radius: 0.25rem; /* 날카로운, 기술적 느낌 */
  /* --radius: 0.75rem; /* 둥근 느낌 */
  /* --radius: 1rem;    /* 매우 둥근 느낌 */
  /* --radius: 1.3rem;  /* 알약 모양 */
}
```

---

## 공식 문서

- [Tailwind CSS](https://tailwindcss.com/docs)
- [shadcn/ui 테마](https://ui.shadcn.com/docs/theming)
- [shadcn/ui CSS 변수](https://ui.shadcn.com/docs/theming#css-variables)
- [next-themes](https://github.com/pacocoursey/next-themes)
