# React 모범 사례

**버전 1.0.0**
Vercel Engineering
2026년 1월

> **참고:**
> 이 문서는 주로 에이전트와 LLM이 Vercel에서 React 및 Next.js 코드베이스를 유지보수, 생성, 리팩토링할 때 따르기 위한 것입니다. 사람이 읽어도 유용하지만, 여기의 가이드라인은 AI 지원 워크플로우에 의한 자동화와 일관성에 최적화되어 있습니다.

---

## 개요

React 및 Next.js 애플리케이션을 위한 종합 성능 최적화 가이드로, AI 에이전트와 LLM을 위해 설계되었습니다. 8개 카테고리에 걸쳐 40개 이상의 규칙을 포함하며, 치명적(워터폴 제거, 번들 크기 축소)에서 점진적(고급 패턴)까지 영향도별로 우선순위가 매겨져 있습니다. 각 규칙에는 상세한 설명, 잘못된 구현과 올바른 구현을 비교하는 실제 예시, 자동 리팩토링 및 코드 생성을 안내하는 구체적인 영향 지표가 포함되어 있습니다.

---

## 목차

1. [워터폴 제거](#1-워터폴-제거) — **CRITICAL**
   - 1.1 [필요할 때까지 Await 지연하기](#11-필요할-때까지-await-지연하기)
   - 1.2 [의존성 기반 병렬화](#12-의존성-기반-병렬화)
   - 1.3 [API 라우트에서 워터폴 체인 방지](#13-api-라우트에서-워터폴-체인-방지)
   - 1.4 [독립 작업에 Promise.all() 사용](#14-독립-작업에-promiseall-사용)
   - 1.5 [전략적 Suspense 경계](#15-전략적-suspense-경계)
2. [번들 크기 최적화](#2-번들-크기-최적화) — **CRITICAL**
   - 2.1 [배럴 파일 임포트 지양](#21-배럴-파일-임포트-지양)
   - 2.2 [조건부 모듈 로딩](#22-조건부-모듈-로딩)
   - 2.3 [비핵심 서드파티 라이브러리 지연 로딩](#23-비핵심-서드파티-라이브러리-지연-로딩)
   - 2.4 [무거운 컴포넌트의 동적 임포트](#24-무거운-컴포넌트의-동적-임포트)
   - 2.5 [사용자 의도 기반 프리로드](#25-사용자-의도-기반-프리로드)
3. [서버 사이드 성능](#3-서버-사이드-성능) — **HIGH**
   - 3.1 [Server Actions을 API 라우트처럼 인증하기](#31-server-actions을-api-라우트처럼-인증하기)
   - 3.2 [RSC Props에서 중복 직렬화 방지](#32-rsc-props에서-중복-직렬화-방지)
   - 3.3 [요청 간 LRU 캐싱](#33-요청-간-lru-캐싱)
   - 3.4 [RSC 경계에서 직렬화 최소화](#34-rsc-경계에서-직렬화-최소화)
   - 3.5 [컴포넌트 합성을 통한 병렬 데이터 페칭](#35-컴포넌트-합성을-통한-병렬-데이터-페칭)
   - 3.6 [React.cache()를 이용한 요청별 중복 제거](#36-reactcache를-이용한-요청별-중복-제거)
   - 3.7 [논블로킹 작업에 after() 사용](#37-논블로킹-작업에-after-사용)
4. [클라이언트 사이드 데이터 페칭](#4-클라이언트-사이드-데이터-페칭) — **MEDIUM-HIGH**
   - 4.1 [글로벌 이벤트 리스너 중복 제거](#41-글로벌-이벤트-리스너-중복-제거)
   - 4.2 [스크롤 성능을 위한 패시브 이벤트 리스너 사용](#42-스크롤-성능을-위한-패시브-이벤트-리스너-사용)
   - 4.3 [자동 중복 제거를 위한 SWR 사용](#43-자동-중복-제거를-위한-swr-사용)
   - 4.4 [localStorage 데이터 버전 관리 및 최소화](#44-localstorage-데이터-버전-관리-및-최소화)
5. [리렌더 최적화](#5-리렌더-최적화) — **MEDIUM**
   - 5.1 [상태 읽기를 사용 시점으로 지연](#51-상태-읽기를-사용-시점으로-지연)
   - 5.2 [메모이제이션된 컴포넌트로 추출](#52-메모이제이션된-컴포넌트로-추출)
   - 5.3 [Effect 의존성 좁히기](#53-effect-의존성-좁히기)
   - 5.4 [파생 상태 구독](#54-파생-상태-구독)
   - 5.5 [함수형 setState 업데이트 사용](#55-함수형-setstate-업데이트-사용)
   - 5.6 [지연 상태 초기화 사용](#56-지연-상태-초기화-사용)
   - 5.7 [긴급하지 않은 업데이트에 Transitions 사용](#57-긴급하지-않은-업데이트에-transitions-사용)
6. [렌더링 성능](#6-렌더링-성능) — **MEDIUM**
   - 6.1 [SVG 요소 대신 래퍼에 애니메이션 적용](#61-svg-요소-대신-래퍼에-애니메이션-적용)
   - 6.2 [긴 목록에 CSS content-visibility 적용](#62-긴-목록에-css-content-visibility-적용)
   - 6.3 [정적 JSX 요소 호이스팅](#63-정적-jsx-요소-호이스팅)
   - 6.4 [SVG 정밀도 최적화](#64-svg-정밀도-최적화)
   - 6.5 [깜빡임 없이 하이드레이션 불일치 방지](#65-깜빡임-없이-하이드레이션-불일치-방지)
   - 6.6 [표시/숨김에 Activity 컴포넌트 사용](#66-표시숨김에-activity-컴포넌트-사용)
   - 6.7 [명시적 조건부 렌더링 사용](#67-명시적-조건부-렌더링-사용)
7. [JavaScript 성능](#7-javascript-성능) — **LOW-MEDIUM**
   - 7.1 [DOM CSS 변경 일괄 처리](#71-dom-css-변경-일괄-처리)
   - 7.2 [반복 조회를 위한 인덱스 맵 구축](#72-반복-조회를-위한-인덱스-맵-구축)
   - 7.3 [루프에서 속성 접근 캐싱](#73-루프에서-속성-접근-캐싱)
   - 7.4 [반복 함수 호출 캐싱](#74-반복-함수-호출-캐싱)
   - 7.5 [Storage API 호출 캐싱](#75-storage-api-호출-캐싱)
   - 7.6 [여러 배열 반복 결합](#76-여러-배열-반복-결합)
   - 7.7 [배열 비교 시 조기 길이 검사](#77-배열-비교-시-조기-길이-검사)
   - 7.8 [함수에서 조기 반환](#78-함수에서-조기-반환)
   - 7.9 [RegExp 생성 호이스팅](#79-regexp-생성-호이스팅)
   - 7.10 [정렬 대신 루프로 Min/Max 찾기](#710-정렬-대신-루프로-minmax-찾기)
   - 7.11 [O(1) 조회를 위한 Set/Map 사용](#711-o1-조회를-위한-setmap-사용)
   - 7.12 [불변성을 위해 sort() 대신 toSorted() 사용](#712-불변성을-위해-sort-대신-tosorted-사용)
8. [고급 패턴](#8-고급-패턴) — **LOW**
   - 8.1 [Ref에 이벤트 핸들러 저장](#81-ref에-이벤트-핸들러-저장)
   - 8.2 [안정적 콜백 참조를 위한 useLatest](#82-안정적-콜백-참조를-위한-uselatest)

---

## 1. 워터폴 제거

**영향: CRITICAL**

워터폴은 성능 저하의 1순위 원인입니다. 각각의 순차적 await는 전체 네트워크 지연 시간을 추가합니다. 이를 제거하면 가장 큰 성능 향상을 얻을 수 있습니다.

### 1.1 필요할 때까지 Await 지연하기

**영향: HIGH (사용되지 않는 코드 경로의 블로킹 방지)**

`await` 연산을 실제로 사용되는 분기 내부로 이동하여, 필요하지 않은 코드 경로가 블로킹되는 것을 방지합니다.

**잘못된 예: 두 분기 모두 블로킹**

```typescript
async function handleRequest(userId: string, skipProcessing: boolean) {
  const userData = await fetchUserData(userId)

  if (skipProcessing) {
    // 즉시 반환하지만 여전히 userData를 기다림
    return { skipped: true }
  }

  // 이 분기만 userData를 사용함
  return processUserData(userData)
}
```

**올바른 예: 필요할 때만 블로킹**

```typescript
async function handleRequest(userId: string, skipProcessing: boolean) {
  if (skipProcessing) {
    // 기다리지 않고 즉시 반환
    return { skipped: true }
  }

  // 필요할 때만 데이터 페칭
  const userData = await fetchUserData(userId)
  return processUserData(userData)
}
```

**또 다른 예: 조기 반환 최적화**

```typescript
// 잘못된 예: 항상 권한을 가져옴
async function updateResource(resourceId: string, userId: string) {
  const permissions = await fetchPermissions(userId)
  const resource = await getResource(resourceId)

  if (!resource) {
    return { error: 'Not found' }
  }

  if (!permissions.canEdit) {
    return { error: 'Forbidden' }
  }

  return await updateResourceData(resource, permissions)
}

// 올바른 예: 필요할 때만 가져옴
async function updateResource(resourceId: string, userId: string) {
  const resource = await getResource(resourceId)

  if (!resource) {
    return { error: 'Not found' }
  }

  const permissions = await fetchPermissions(userId)

  if (!permissions.canEdit) {
    return { error: 'Forbidden' }
  }

  return await updateResourceData(resource, permissions)
}
```

이 최적화는 건너뛰는 분기가 자주 실행되거나, 지연된 작업이 비용이 큰 경우에 특히 유용합니다.

### 1.2 의존성 기반 병렬화

**영향: CRITICAL (2~10배 개선)**

부분적 의존성이 있는 작업에는 `better-all`을 사용하여 병렬성을 극대화합니다. 각 작업을 가능한 가장 빠른 시점에 자동으로 시작합니다.

**잘못된 예: profile이 config를 불필요하게 기다림**

```typescript
const [user, config] = await Promise.all([
  fetchUser(),
  fetchConfig()
])
const profile = await fetchProfile(user.id)
```

**올바른 예: config과 profile이 병렬로 실행됨**

```typescript
import { all } from 'better-all'

const { user, config, profile } = await all({
  async user() { return fetchUser() },
  async config() { return fetchConfig() },
  async profile() {
    return fetchProfile((await this.$.user).id)
  }
})
```

참조: [https://github.com/shuding/better-all](https://github.com/shuding/better-all)

### 1.3 API 라우트에서 워터폴 체인 방지

**영향: CRITICAL (2~10배 개선)**

API 라우트와 Server Actions에서 독립적인 작업은 await하지 않더라도 즉시 시작합니다.

**잘못된 예: config이 auth를 기다리고, data가 둘 다 기다림**

```typescript
export async function GET(request: Request) {
  const session = await auth()
  const config = await fetchConfig()
  const data = await fetchData(session.user.id)
  return Response.json({ data, config })
}
```

**올바른 예: auth와 config이 즉시 시작됨**

```typescript
export async function GET(request: Request) {
  const sessionPromise = auth()
  const configPromise = fetchConfig()
  const session = await sessionPromise
  const [config, data] = await Promise.all([
    configPromise,
    fetchData(session.user.id)
  ])
  return Response.json({ data, config })
}
```

더 복잡한 의존성 체인이 있는 작업에는 `better-all`을 사용하여 자동으로 병렬성을 극대화할 수 있습니다 (의존성 기반 병렬화 참조).

### 1.4 독립 작업에 Promise.all() 사용

**영향: CRITICAL (2~10배 개선)**

비동기 작업 간에 상호 의존성이 없는 경우, `Promise.all()`을 사용하여 동시에 실행합니다.

**잘못된 예: 순차 실행, 3회 왕복**

```typescript
const user = await fetchUser()
const posts = await fetchPosts()
const comments = await fetchComments()
```

**올바른 예: 병렬 실행, 1회 왕복**

```typescript
const [user, posts, comments] = await Promise.all([
  fetchUser(),
  fetchPosts(),
  fetchComments()
])
```

### 1.5 전략적 Suspense 경계

**영향: HIGH (더 빠른 초기 페인트)**

비동기 컴포넌트에서 JSX를 반환하기 전에 데이터를 기다리는 대신, Suspense 경계를 사용하여 데이터가 로드되는 동안 래퍼 UI를 더 빨리 표시합니다.

**잘못된 예: 데이터 페칭에 의해 래퍼가 블로킹됨**

```tsx
async function Page() {
  const data = await fetchData() // 전체 페이지를 블로킹

  return (
    <div>
      <div>Sidebar</div>
      <div>Header</div>
      <div>
        <DataDisplay data={data} />
      </div>
      <div>Footer</div>
    </div>
  )
}
```

중간 섹션만 데이터가 필요한데도 전체 레이아웃이 데이터를 기다립니다.

**올바른 예: 래퍼가 즉시 표시되고, 데이터가 스트리밍됨**

```tsx
function Page() {
  return (
    <div>
      <div>Sidebar</div>
      <div>Header</div>
      <div>
        <Suspense fallback={<Skeleton />}>
          <DataDisplay />
        </Suspense>
      </div>
      <div>Footer</div>
    </div>
  )
}

async function DataDisplay() {
  const data = await fetchData() // 이 컴포넌트만 블로킹
  return <div>{data.content}</div>
}
```

Sidebar, Header, Footer는 즉시 렌더링됩니다. DataDisplay만 데이터를 기다립니다.

**대안: 컴포넌트 간 promise 공유**

```tsx
function Page() {
  // 페칭을 즉시 시작하되, await하지 않음
  const dataPromise = fetchData()

  return (
    <div>
      <div>Sidebar</div>
      <div>Header</div>
      <Suspense fallback={<Skeleton />}>
        <DataDisplay dataPromise={dataPromise} />
        <DataSummary dataPromise={dataPromise} />
      </Suspense>
      <div>Footer</div>
    </div>
  )
}

function DataDisplay({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise) // promise를 언래핑
  return <div>{data.content}</div>
}

function DataSummary({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise) // 같은 promise를 재사용
  return <div>{data.summary}</div>
}
```

두 컴포넌트가 같은 promise를 공유하므로, 페칭은 한 번만 발생합니다. 레이아웃은 즉시 렌더링되고 두 컴포넌트는 함께 기다립니다.

**이 패턴을 사용하지 말아야 할 때:**

- 레이아웃 결정에 필요한 핵심 데이터 (위치에 영향)

- 스크롤 없이 보이는 영역의 SEO 핵심 콘텐츠

- Suspense 오버헤드가 가치 없는 작고 빠른 쿼리

- 레이아웃 시프트를 피하고 싶을 때 (로딩 -> 콘텐츠 전환)

**트레이드오프:** 더 빠른 초기 페인트 vs 잠재적 레이아웃 시프트. UX 우선순위에 따라 선택하세요.

---

## 2. 번들 크기 최적화

**영향: CRITICAL**

초기 번들 크기를 줄이면 Time to Interactive와 Largest Contentful Paint가 개선됩니다.

### 2.1 배럴 파일 임포트 지양

**영향: CRITICAL (200~800ms 임포트 비용, 느린 빌드)**

사용하지 않는 수천 개의 모듈 로드를 방지하기 위해, 배럴 파일 대신 소스 파일에서 직접 임포트합니다. **배럴 파일**은 여러 모듈을 재내보내는 진입점입니다 (예: `export * from './module'`을 수행하는 `index.js`).

인기 있는 아이콘 및 컴포넌트 라이브러리는 진입 파일에 **최대 10,000개의 재내보내기**가 있을 수 있습니다. 많은 React 패키지에서 **임포트하는 데만 200~800ms가 소요**되어, 개발 속도와 프로덕션 콜드 스타트 모두에 영향을 줍니다.

**트리 쉐이킹이 도움이 되지 않는 이유:** 라이브러리가 external로 표시되면(번들되지 않으면), 번들러가 최적화할 수 없습니다. 트리 쉐이킹을 활성화하기 위해 번들하면, 전체 모듈 그래프를 분석하느라 빌드가 상당히 느려집니다.

**잘못된 예: 전체 라이브러리를 임포트**

```tsx
import { Check, X, Menu } from 'lucide-react'
// 1,583개의 모듈을 로드, 개발 환경에서 ~2.8초 추가
// 런타임 비용: 매 콜드 스타트마다 200~800ms

import { Button, TextField } from '@mui/material'
// 2,225개의 모듈을 로드, 개발 환경에서 ~4.2초 추가
```

**올바른 예: 필요한 것만 임포트**

```tsx
import Check from 'lucide-react/dist/esm/icons/check'
import X from 'lucide-react/dist/esm/icons/x'
import Menu from 'lucide-react/dist/esm/icons/menu'
// 3개의 모듈만 로드 (~2KB vs ~1MB)

import Button from '@mui/material/Button'
import TextField from '@mui/material/TextField'
// 사용하는 것만 로드
```

**대안: Next.js 13.5+**

```js
// next.config.js - optimizePackageImports 사용
module.exports = {
  experimental: {
    optimizePackageImports: ['lucide-react', '@mui/material']
  }
}

// 그러면 편리한 배럴 임포트를 유지할 수 있습니다:
import { Check, X, Menu } from 'lucide-react'
// 빌드 시 자동으로 직접 임포트로 변환됨
```

직접 임포트는 개발 부팅 15~70% 빠르게, 빌드 28% 빠르게, 콜드 스타트 40% 빠르게, 그리고 HMR을 크게 빠르게 만듭니다.

주로 영향 받는 라이브러리: `lucide-react`, `@mui/material`, `@mui/icons-material`, `@tabler/icons-react`, `react-icons`, `@headlessui/react`, `@radix-ui/react-*`, `lodash`, `ramda`, `date-fns`, `rxjs`, `react-use`.

참조: [https://vercel.com/blog/how-we-optimized-package-imports-in-next-js](https://vercel.com/blog/how-we-optimized-package-imports-in-next-js)

### 2.2 조건부 모듈 로딩

**영향: HIGH (필요할 때만 대용량 데이터 로드)**

기능이 활성화될 때만 대용량 데이터나 모듈을 로드합니다.

**예: 애니메이션 프레임 지연 로딩**

```tsx
function AnimationPlayer({ enabled, setEnabled }: { enabled: boolean; setEnabled: React.Dispatch<React.SetStateAction<boolean>> }) {
  const [frames, setFrames] = useState<Frame[] | null>(null)

  useEffect(() => {
    if (enabled && !frames && typeof window !== 'undefined') {
      import('./animation-frames.js')
        .then(mod => setFrames(mod.frames))
        .catch(() => setEnabled(false))
    }
  }, [enabled, frames, setEnabled])

  if (!frames) return <Skeleton />
  return <Canvas frames={frames} />
}
```

`typeof window !== 'undefined'` 검사는 SSR을 위해 이 모듈이 번들되는 것을 방지하여, 서버 번들 크기와 빌드 속도를 최적화합니다.

### 2.3 비핵심 서드파티 라이브러리 지연 로딩

**영향: MEDIUM (하이드레이션 후 로드)**

분석, 로깅, 에러 추적은 사용자 상호작용을 블로킹하지 않습니다. 하이드레이션 후에 로드합니다.

**잘못된 예: 초기 번들을 블로킹**

```tsx
import { Analytics } from '@vercel/analytics/react'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
```

**올바른 예: 하이드레이션 후 로드**

```tsx
import dynamic from 'next/dynamic'

const Analytics = dynamic(
  () => import('@vercel/analytics/react').then(m => m.Analytics),
  { ssr: false }
)

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
```

### 2.4 무거운 컴포넌트의 동적 임포트

**영향: CRITICAL (TTI와 LCP에 직접 영향)**

초기 렌더링에 필요하지 않은 대형 컴포넌트를 `next/dynamic`으로 지연 로딩합니다.

**잘못된 예: Monaco가 메인 청크와 함께 번들됨 ~300KB**

```tsx
import { MonacoEditor } from './monaco-editor'

function CodePanel({ code }: { code: string }) {
  return <MonacoEditor value={code} />
}
```

**올바른 예: Monaco가 필요 시 로드됨**

```tsx
import dynamic from 'next/dynamic'

const MonacoEditor = dynamic(
  () => import('./monaco-editor').then(m => m.MonacoEditor),
  { ssr: false }
)

function CodePanel({ code }: { code: string }) {
  return <MonacoEditor value={code} />
}
```

### 2.5 사용자 의도 기반 프리로드

**영향: MEDIUM (체감 지연 시간 감소)**

무거운 번들을 필요하기 전에 미리 로드하여 체감 지연 시간을 줄입니다.

**예: 호버/포커스 시 프리로드**

```tsx
function EditorButton({ onClick }: { onClick: () => void }) {
  const preload = () => {
    if (typeof window !== 'undefined') {
      void import('./monaco-editor')
    }
  }

  return (
    <button
      onMouseEnter={preload}
      onFocus={preload}
      onClick={onClick}
    >
      Open Editor
    </button>
  )
}
```

**예: 기능 플래그 활성화 시 프리로드**

```tsx
function FlagsProvider({ children, flags }: Props) {
  useEffect(() => {
    if (flags.editorEnabled && typeof window !== 'undefined') {
      void import('./monaco-editor').then(mod => mod.init())
    }
  }, [flags.editorEnabled])

  return <FlagsContext.Provider value={flags}>
    {children}
  </FlagsContext.Provider>
}
```

`typeof window !== 'undefined'` 검사는 SSR을 위해 프리로드된 모듈이 번들되는 것을 방지하여, 서버 번들 크기와 빌드 속도를 최적화합니다.

---

## 3. 서버 사이드 성능

**영향: HIGH**

서버 사이드 렌더링과 데이터 페칭을 최적화하면 서버 사이드 워터폴을 제거하고 응답 시간을 단축할 수 있습니다.

### 3.1 Server Actions을 API 라우트처럼 인증하기

**영향: CRITICAL (서버 변이에 대한 무단 접근 방지)**

Server Actions (`"use server"` 함수)은 API 라우트와 마찬가지로 공개 엔드포인트로 노출됩니다. 항상 각 Server Action **내부에서** 인증과 권한을 검증하세요. 미들웨어, 레이아웃 가드, 페이지 수준 검사에만 의존하지 마세요. Server Actions은 직접 호출될 수 있습니다.

Next.js 문서에 명시적으로 다음과 같이 기술되어 있습니다: "Server Actions을 공개 API 엔드포인트와 동일한 보안 고려사항으로 취급하고, 사용자가 변이를 수행할 권한이 있는지 확인하세요."

**잘못된 예: 인증 검사 없음**

```typescript
'use server'

export async function deleteUser(userId: string) {
  // 누구나 호출 가능! 인증 검사 없음
  await db.user.delete({ where: { id: userId } })
  return { success: true }
}
```

**올바른 예: 액션 내부에서 인증**

```typescript
'use server'

import { verifySession } from '@/lib/auth'
import { unauthorized } from '@/lib/errors'

export async function deleteUser(userId: string) {
  // 항상 액션 내부에서 인증 검사
  const session = await verifySession()

  if (!session) {
    throw unauthorized('Must be logged in')
  }

  // 권한도 검사
  if (session.user.role !== 'admin' && session.user.id !== userId) {
    throw unauthorized('Cannot delete other users')
  }

  await db.user.delete({ where: { id: userId } })
  return { success: true }
}
```

**입력 유효성 검사 포함:**

```typescript
'use server'

import { verifySession } from '@/lib/auth'
import { z } from 'zod'

const updateProfileSchema = z.object({
  userId: z.string().uuid(),
  name: z.string().min(1).max(100),
  email: z.string().email()
})

export async function updateProfile(data: unknown) {
  // 먼저 입력 유효성 검사
  const validated = updateProfileSchema.parse(data)

  // 그 다음 인증
  const session = await verifySession()
  if (!session) {
    throw new Error('Unauthorized')
  }

  // 그 다음 권한 확인
  if (session.user.id !== validated.userId) {
    throw new Error('Can only update own profile')
  }

  // 마지막으로 변이 수행
  await db.user.update({
    where: { id: validated.userId },
    data: {
      name: validated.name,
      email: validated.email
    }
  })

  return { success: true }
}
```

참조: [https://nextjs.org/docs/app/guides/authentication](https://nextjs.org/docs/app/guides/authentication)

### 3.2 RSC Props에서 중복 직렬화 방지

**영향: LOW (중복 직렬화를 방지하여 네트워크 페이로드 감소)**

RSC에서 클라이언트로의 직렬화는 값이 아닌 객체 참조로 중복을 제거합니다. 같은 참조 = 한 번 직렬화; 새 참조 = 다시 직렬화. 변환(`.toSorted()`, `.filter()`, `.map()`)은 서버가 아닌 클라이언트에서 수행합니다.

**잘못된 예: 배열 중복**

```tsx
// RSC: 6개 문자열 전송 (2개 배열 x 3개 항목)
<ClientList usernames={usernames} usernamesOrdered={usernames.toSorted()} />
```

**올바른 예: 3개 문자열 전송**

```tsx
// RSC: 한 번 전송
<ClientList usernames={usernames} />

// 클라이언트: 여기서 변환
'use client'
const sorted = useMemo(() => [...usernames].sort(), [usernames])
```

**중첩 중복 제거 동작:**

```tsx
// string[] - 모든 것을 중복
usernames={['a','b']} sorted={usernames.toSorted()} // 4개 문자열 전송

// object[] - 배열 구조만 중복
users={[{id:1},{id:2}]} sorted={users.toSorted()} // 2개 배열 + 2개 고유 객체 전송 (4개가 아님)
```

중복 제거는 재귀적으로 작동합니다. 데이터 타입에 따라 영향이 다릅니다:

- `string[]`, `number[]`, `boolean[]`: **높은 영향** - 배열 + 모든 프리미티브가 완전히 중복됨

- `object[]`: **낮은 영향** - 배열이 중복되지만, 중첩 객체는 참조로 중복 제거됨

**중복 제거를 깨뜨리는 연산: 새 참조 생성**

- 배열: `.toSorted()`, `.filter()`, `.map()`, `.slice()`, `[...arr]`

- 객체: `{...obj}`, `Object.assign()`, `structuredClone()`, `JSON.parse(JSON.stringify())`

**추가 예시:**

```tsx
// ❌ 잘못된 예
<C users={users} active={users.filter(u => u.active)} />
<C product={product} productName={product.name} />

// ✅ 올바른 예
<C users={users} />
<C product={product} />
// 필터링/구조분해는 클라이언트에서 수행
```

**예외:** 변환 비용이 크거나 클라이언트가 원본 데이터를 필요로 하지 않을 때 파생 데이터를 전달합니다.

### 3.3 요청 간 LRU 캐싱

**영향: HIGH (요청 간 캐싱)**

`React.cache()`는 하나의 요청 내에서만 작동합니다. 순차적 요청 간에 공유되는 데이터(사용자가 버튼 A를 클릭한 후 버튼 B를 클릭)에는 LRU 캐시를 사용합니다.

**구현:**

```typescript
import { LRUCache } from 'lru-cache'

const cache = new LRUCache<string, any>({
  max: 1000,
  ttl: 5 * 60 * 1000  // 5분
})

export async function getUser(id: string) {
  const cached = cache.get(id)
  if (cached) return cached

  const user = await db.user.findUnique({ where: { id } })
  cache.set(id, user)
  return user
}

// 요청 1: DB 쿼리, 결과 캐싱
// 요청 2: 캐시 히트, DB 쿼리 없음
```

순차적 사용자 액션이 수초 이내에 같은 데이터를 필요로 하는 여러 엔드포인트를 호출할 때 사용합니다.

**Vercel의 [Fluid Compute](https://vercel.com/docs/fluid-compute)와 함께:** 여러 동시 요청이 같은 함수 인스턴스와 캐시를 공유할 수 있으므로 LRU 캐싱이 특히 효과적입니다. Redis와 같은 외부 스토리지 없이도 캐시가 요청 간에 유지됩니다.

**전통적인 서버리스에서:** 각 호출이 격리되어 실행되므로, 프로세스 간 캐싱에는 Redis를 고려하세요.

참조: [https://github.com/isaacs/node-lru-cache](https://github.com/isaacs/node-lru-cache)

### 3.4 RSC 경계에서 직렬화 최소화

**영향: HIGH (데이터 전송 크기 감소)**

React 서버/클라이언트 경계는 모든 객체 속성을 문자열로 직렬화하여 HTML 응답과 후속 RSC 요청에 포함합니다. 이 직렬화된 데이터는 페이지 무게와 로드 시간에 직접 영향을 미치므로, **크기가 매우 중요합니다**. 클라이언트가 실제로 사용하는 필드만 전달하세요.

**잘못된 예: 50개 필드 모두 직렬화**

```tsx
async function Page() {
  const user = await fetchUser()  // 50개 필드
  return <Profile user={user} />
}

'use client'
function Profile({ user }: { user: User }) {
  return <div>{user.name}</div>  // 1개 필드만 사용
}
```

**올바른 예: 1개 필드만 직렬화**

```tsx
async function Page() {
  const user = await fetchUser()
  return <Profile name={user.name} />
}

'use client'
function Profile({ name }: { name: string }) {
  return <div>{name}</div>
}
```

### 3.5 컴포넌트 합성을 통한 병렬 데이터 페칭

**영향: CRITICAL (서버 사이드 워터폴 제거)**

React Server Components는 트리 내에서 순차적으로 실행됩니다. 합성(composition)으로 구조를 변경하여 데이터 페칭을 병렬화합니다.

**잘못된 예: Sidebar가 Page의 페칭 완료를 기다림**

```tsx
export default async function Page() {
  const header = await fetchHeader()
  return (
    <div>
      <div>{header}</div>
      <Sidebar />
    </div>
  )
}

async function Sidebar() {
  const items = await fetchSidebarItems()
  return <nav>{items.map(renderItem)}</nav>
}
```

**올바른 예: 둘 다 동시에 페칭**

```tsx
async function Header() {
  const data = await fetchHeader()
  return <div>{data}</div>
}

async function Sidebar() {
  const items = await fetchSidebarItems()
  return <nav>{items.map(renderItem)}</nav>
}

export default function Page() {
  return (
    <div>
      <Header />
      <Sidebar />
    </div>
  )
}
```

**children prop을 사용한 대안:**

```tsx
async function Header() {
  const data = await fetchHeader()
  return <div>{data}</div>
}

async function Sidebar() {
  const items = await fetchSidebarItems()
  return <nav>{items.map(renderItem)}</nav>
}

function Layout({ children }: { children: ReactNode }) {
  return (
    <div>
      <Header />
      {children}
    </div>
  )
}

export default function Page() {
  return (
    <Layout>
      <Sidebar />
    </Layout>
  )
}
```

### 3.6 React.cache()를 이용한 요청별 중복 제거

**영향: MEDIUM (요청 내 중복 제거)**

서버 사이드 요청 중복 제거에 `React.cache()`를 사용합니다. 인증 및 데이터베이스 쿼리가 가장 큰 혜택을 받습니다.

**사용법:**

```typescript
import { cache } from 'react'

export const getCurrentUser = cache(async () => {
  const session = await auth()
  if (!session?.user?.id) return null
  return await db.user.findUnique({
    where: { id: session.user.id }
  })
})
```

단일 요청 내에서 `getCurrentUser()`를 여러 번 호출해도 쿼리는 한 번만 실행됩니다.

**인라인 객체를 인수로 사용하지 마세요:**

`React.cache()`는 캐시 히트를 결정하기 위해 얕은 동등성(`Object.is`)을 사용합니다. 인라인 객체는 호출할 때마다 새 참조를 생성하여 캐시 히트를 방지합니다.

**잘못된 예: 항상 캐시 미스**

```typescript
const getUser = cache(async (params: { uid: number }) => {
  return await db.user.findUnique({ where: { id: params.uid } })
})

// 호출할 때마다 새 객체를 생성, 캐시 히트 불가
getUser({ uid: 1 })
getUser({ uid: 1 })  // 캐시 미스, 쿼리 재실행
```

**올바른 예: 캐시 히트**

```typescript
const getUser = cache(async (uid: number) => {
  return await db.user.findUnique({ where: { id: uid } })
})

// 프리미티브 인수는 값 동등성 사용
getUser(1)
getUser(1)  // 캐시 히트, 캐시된 결과 반환
```

객체를 전달해야 하는 경우, 같은 참조를 전달하세요:

```typescript
const params = { uid: 1 }
getUser(params)  // 쿼리 실행
getUser(params)  // 캐시 히트 (같은 참조)
```

**Next.js 관련 참고:**

Next.js에서는 `fetch` API가 자동으로 요청 메모이제이션으로 확장됩니다. 같은 URL과 옵션으로의 요청은 단일 요청 내에서 자동으로 중복 제거되므로, `fetch` 호출에는 `React.cache()`가 필요하지 않습니다. 하지만 `React.cache()`는 다른 비동기 작업에 여전히 필수적입니다:

- 데이터베이스 쿼리 (Prisma, Drizzle 등)

- 무거운 계산

- 인증 검사

- 파일 시스템 작업

- fetch가 아닌 모든 비동기 작업

컴포넌트 트리 전체에서 이러한 작업을 중복 제거하기 위해 `React.cache()`를 사용하세요.

참조: [https://react.dev/reference/react/cache](https://react.dev/reference/react/cache)

### 3.7 논블로킹 작업에 after() 사용

**영향: MEDIUM (더 빠른 응답 시간)**

Next.js의 `after()`를 사용하여 응답이 전송된 후 실행해야 할 작업을 예약합니다. 로깅, 분석 및 기타 부수 효과가 응답을 블로킹하는 것을 방지합니다.

**잘못된 예: 응답을 블로킹**

```tsx
import { logUserAction } from '@/app/utils'

export async function POST(request: Request) {
  // 변이 수행
  await updateDatabase(request)

  // 로깅이 응답을 블로킹
  const userAgent = request.headers.get('user-agent') || 'unknown'
  await logUserAction({ userAgent })

  return new Response(JSON.stringify({ status: 'success' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  })
}
```

**올바른 예: 논블로킹**

```tsx
import { after } from 'next/server'
import { headers, cookies } from 'next/headers'
import { logUserAction } from '@/app/utils'

export async function POST(request: Request) {
  // 변이 수행
  await updateDatabase(request)

  // 응답 전송 후 로깅
  after(async () => {
    const userAgent = (await headers()).get('user-agent') || 'unknown'
    const sessionCookie = (await cookies()).get('session-id')?.value || 'anonymous'

    logUserAction({ sessionCookie, userAgent })
  })

  return new Response(JSON.stringify({ status: 'success' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  })
}
```

응답은 즉시 전송되고, 로깅은 백그라운드에서 수행됩니다.

**주요 사용 사례:**

- 분석 추적

- 감사 로깅

- 알림 전송

- 캐시 무효화

- 정리 작업

**중요 참고:**

- `after()`는 응답이 실패하거나 리디렉트되어도 실행됩니다

- Server Actions, Route Handlers, Server Components에서 동작합니다

참조: [https://nextjs.org/docs/app/api-reference/functions/after](https://nextjs.org/docs/app/api-reference/functions/after)

---

## 4. 클라이언트 사이드 데이터 페칭

**영향: MEDIUM-HIGH**

자동 중복 제거와 효율적인 데이터 페칭 패턴으로 불필요한 네트워크 요청을 줄입니다.

### 4.1 글로벌 이벤트 리스너 중복 제거

**영향: LOW (N개 컴포넌트에 하나의 리스너)**

`useSWRSubscription()`을 사용하여 컴포넌트 인스턴스 간에 글로벌 이벤트 리스너를 공유합니다.

**잘못된 예: N개 인스턴스 = N개 리스너**

```tsx
function useKeyboardShortcut(key: string, callback: () => void) {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && e.key === key) {
        callback()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [key, callback])
}
```

`useKeyboardShortcut` 훅을 여러 번 사용하면, 각 인스턴스가 새 리스너를 등록합니다.

**올바른 예: N개 인스턴스 = 1개 리스너**

```tsx
import useSWRSubscription from 'swr/subscription'

// 키별 콜백을 추적하는 모듈 수준 Map
const keyCallbacks = new Map<string, Set<() => void>>()

function useKeyboardShortcut(key: string, callback: () => void) {
  // Map에 이 콜백 등록
  useEffect(() => {
    if (!keyCallbacks.has(key)) {
      keyCallbacks.set(key, new Set())
    }
    keyCallbacks.get(key)!.add(callback)

    return () => {
      const set = keyCallbacks.get(key)
      if (set) {
        set.delete(callback)
        if (set.size === 0) {
          keyCallbacks.delete(key)
        }
      }
    }
  }, [key, callback])

  useSWRSubscription('global-keydown', () => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && keyCallbacks.has(e.key)) {
        keyCallbacks.get(e.key)!.forEach(cb => cb())
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  })
}

function Profile() {
  // 여러 단축키가 같은 리스너를 공유
  useKeyboardShortcut('p', () => { /* ... */ })
  useKeyboardShortcut('k', () => { /* ... */ })
  // ...
}
```

### 4.2 스크롤 성능을 위한 패시브 이벤트 리스너 사용

**영향: MEDIUM (이벤트 리스너로 인한 스크롤 지연 제거)**

터치 및 휠 이벤트 리스너에 `{ passive: true }`를 추가하여 즉각적인 스크롤을 활성화합니다. 브라우저는 보통 `preventDefault()`가 호출되는지 확인하기 위해 리스너 실행이 끝날 때까지 기다리며, 이로 인해 스크롤이 지연됩니다.

**잘못된 예:**

```typescript
useEffect(() => {
  const handleTouch = (e: TouchEvent) => console.log(e.touches[0].clientX)
  const handleWheel = (e: WheelEvent) => console.log(e.deltaY)

  document.addEventListener('touchstart', handleTouch)
  document.addEventListener('wheel', handleWheel)

  return () => {
    document.removeEventListener('touchstart', handleTouch)
    document.removeEventListener('wheel', handleWheel)
  }
}, [])
```

**올바른 예:**

```typescript
useEffect(() => {
  const handleTouch = (e: TouchEvent) => console.log(e.touches[0].clientX)
  const handleWheel = (e: WheelEvent) => console.log(e.deltaY)

  document.addEventListener('touchstart', handleTouch, { passive: true })
  document.addEventListener('wheel', handleWheel, { passive: true })

  return () => {
    document.removeEventListener('touchstart', handleTouch)
    document.removeEventListener('wheel', handleWheel)
  }
}, [])
```

**패시브를 사용할 때:** 추적/분석, 로깅, `preventDefault()`를 호출하지 않는 모든 리스너.

**패시브를 사용하지 말아야 할 때:** 커스텀 스와이프 제스처, 커스텀 줌 컨트롤 구현, 또는 `preventDefault()`가 필요한 모든 리스너.

### 4.3 자동 중복 제거를 위한 SWR 사용

**영향: MEDIUM-HIGH (자동 중복 제거)**

SWR은 컴포넌트 인스턴스 간에 요청 중복 제거, 캐싱, 재검증을 활성화합니다.

**잘못된 예: 중복 제거 없음, 각 인스턴스가 페칭**

```tsx
function UserList() {
  const [users, setUsers] = useState([])
  useEffect(() => {
    fetch('/api/users')
      .then(r => r.json())
      .then(setUsers)
  }, [])
}
```

**올바른 예: 여러 인스턴스가 하나의 요청을 공유**

```tsx
import useSWR from 'swr'

function UserList() {
  const { data: users } = useSWR('/api/users', fetcher)
}
```

**불변 데이터의 경우:**

```tsx
import { useImmutableSWR } from '@/lib/swr'

function StaticContent() {
  const { data } = useImmutableSWR('/api/config', fetcher)
}
```

**변이의 경우:**

```tsx
import { useSWRMutation } from 'swr/mutation'

function UpdateButton() {
  const { trigger } = useSWRMutation('/api/user', updateUser)
  return <button onClick={() => trigger()}>Update</button>
}
```

참조: [https://swr.vercel.app](https://swr.vercel.app)

### 4.4 localStorage 데이터 버전 관리 및 최소화

**영향: MEDIUM (스키마 충돌 방지, 저장 크기 감소)**

키에 버전 접두사를 추가하고 필요한 필드만 저장합니다. 스키마 충돌과 민감한 데이터의 우발적 저장을 방지합니다.

**잘못된 예:**

```typescript
// 버전 없음, 모든 것을 저장, 에러 처리 없음
localStorage.setItem('userConfig', JSON.stringify(fullUserObject))
const data = localStorage.getItem('userConfig')
```

**올바른 예:**

```typescript
const VERSION = 'v2'

function saveConfig(config: { theme: string; language: string }) {
  try {
    localStorage.setItem(`userConfig:${VERSION}`, JSON.stringify(config))
  } catch {
    // 시크릿/프라이빗 브라우징, 용량 초과, 비활성화 시 예외 발생
  }
}

function loadConfig() {
  try {
    const data = localStorage.getItem(`userConfig:${VERSION}`)
    return data ? JSON.parse(data) : null
  } catch {
    return null
  }
}

// v1에서 v2로 마이그레이션
function migrate() {
  try {
    const v1 = localStorage.getItem('userConfig:v1')
    if (v1) {
      const old = JSON.parse(v1)
      saveConfig({ theme: old.darkMode ? 'dark' : 'light', language: old.lang })
      localStorage.removeItem('userConfig:v1')
    }
  } catch {}
}
```

**서버 응답에서 최소 필드만 저장:**

```typescript
// User 객체에 20개 이상의 필드가 있지만, UI에 필요한 것만 저장
function cachePrefs(user: FullUser) {
  try {
    localStorage.setItem('prefs:v1', JSON.stringify({
      theme: user.preferences.theme,
      notifications: user.preferences.notifications
    }))
  } catch {}
}
```

**항상 try-catch로 감싸세요:** `getItem()`과 `setItem()`은 시크릿/프라이빗 브라우징(Safari, Firefox), 용량 초과, 비활성화 시 예외를 발생시킵니다.

**장점:** 버전 관리를 통한 스키마 진화, 저장 크기 감소, 토큰/PII/내부 플래그 저장 방지.

---

## 5. 리렌더 최적화

**영향: MEDIUM**

불필요한 리렌더를 줄이면 낭비되는 연산을 최소화하고 UI 반응성을 향상시킵니다.

### 5.1 상태 읽기를 사용 시점으로 지연

**영향: MEDIUM (불필요한 구독 방지)**

콜백 내부에서만 읽는다면 동적 상태(searchParams, localStorage)를 구독하지 마세요.

**잘못된 예: 모든 searchParams 변경을 구독**

```tsx
function ShareButton({ chatId }: { chatId: string }) {
  const searchParams = useSearchParams()

  const handleShare = () => {
    const ref = searchParams.get('ref')
    shareChat(chatId, { ref })
  }

  return <button onClick={handleShare}>Share</button>
}
```

**올바른 예: 요청 시 읽기, 구독 없음**

```tsx
function ShareButton({ chatId }: { chatId: string }) {
  const handleShare = () => {
    const params = new URLSearchParams(window.location.search)
    const ref = params.get('ref')
    shareChat(chatId, { ref })
  }

  return <button onClick={handleShare}>Share</button>
}
```

### 5.2 메모이제이션된 컴포넌트로 추출

**영향: MEDIUM (조기 반환 가능)**

비용이 큰 작업을 메모이제이션된 컴포넌트로 추출하여 계산 전에 조기 반환을 가능하게 합니다.

**잘못된 예: 로딩 중에도 아바타를 계산**

```tsx
function Profile({ user, loading }: Props) {
  const avatar = useMemo(() => {
    const id = computeAvatarId(user)
    return <Avatar id={id} />
  }, [user])

  if (loading) return <Skeleton />
  return <div>{avatar}</div>
}
```

**올바른 예: 로딩 시 계산을 건너뜀**

```tsx
const UserAvatar = memo(function UserAvatar({ user }: { user: User }) {
  const id = useMemo(() => computeAvatarId(user), [user])
  return <Avatar id={id} />
})

function Profile({ user, loading }: Props) {
  if (loading) return <Skeleton />
  return (
    <div>
      <UserAvatar user={user} />
    </div>
  )
}
```

**참고:** 프로젝트에 [React Compiler](https://react.dev/learn/react-compiler)가 활성화되어 있다면, `memo()`와 `useMemo()`를 사용한 수동 메모이제이션이 필요하지 않습니다. 컴파일러가 자동으로 리렌더를 최적화합니다.

### 5.3 Effect 의존성 좁히기

**영향: LOW (effect 재실행 최소화)**

객체 대신 프리미티브 의존성을 지정하여 effect 재실행을 최소화합니다.

**잘못된 예: user의 모든 필드 변경 시 재실행**

```tsx
useEffect(() => {
  console.log(user.id)
}, [user])
```

**올바른 예: id가 변경될 때만 재실행**

```tsx
useEffect(() => {
  console.log(user.id)
}, [user.id])
```

**파생 상태의 경우, effect 외부에서 계산:**

```tsx
// 잘못된 예: width=767, 766, 765...에서 실행
useEffect(() => {
  if (width < 768) {
    enableMobileMode()
  }
}, [width])

// 올바른 예: boolean 전환 시에만 실행
const isMobile = width < 768
useEffect(() => {
  if (isMobile) {
    enableMobileMode()
  }
}, [isMobile])
```

### 5.4 파생 상태 구독

**영향: MEDIUM (리렌더 빈도 감소)**

리렌더 빈도를 줄이기 위해 연속 값 대신 파생된 boolean 상태를 구독합니다.

**잘못된 예: 픽셀 변경마다 리렌더**

```tsx
function Sidebar() {
  const width = useWindowWidth()  // 지속적으로 업데이트
  const isMobile = width < 768
  return <nav className={isMobile ? 'mobile' : 'desktop'} />
}
```

**올바른 예: boolean이 변경될 때만 리렌더**

```tsx
function Sidebar() {
  const isMobile = useMediaQuery('(max-width: 767px)')
  return <nav className={isMobile ? 'mobile' : 'desktop'} />
}
```

### 5.5 함수형 setState 업데이트 사용

**영향: MEDIUM (오래된 클로저와 불필요한 콜백 재생성 방지)**

현재 상태 값에 기반하여 상태를 업데이트할 때, 상태 변수를 직접 참조하는 대신 setState의 함수형 업데이트 형태를 사용합니다. 이는 오래된 클로저를 방지하고, 불필요한 의존성을 제거하며, 안정적인 콜백 참조를 생성합니다.

**잘못된 예: 상태를 의존성으로 필요**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems)

  // 콜백이 items에 의존해야 하므로, items가 변경될 때마다 재생성됨
  const addItems = useCallback((newItems: Item[]) => {
    setItems([...items, ...newItems])
  }, [items])  // ❌ items 의존성으로 인한 재생성

  // 의존성을 빠뜨리면 오래된 클로저 위험
  const removeItem = useCallback((id: string) => {
    setItems(items.filter(item => item.id !== id))
  }, [])  // ❌ items 의존성 누락 - 오래된 items를 사용함!

  return <ItemsEditor items={items} onAdd={addItems} onRemove={removeItem} />
}
```

첫 번째 콜백은 `items`가 변경될 때마다 재생성되어, 자식 컴포넌트의 불필요한 리렌더를 유발할 수 있습니다. 두 번째 콜백은 오래된 클로저 버그가 있어, 항상 초기 `items` 값을 참조합니다.

**올바른 예: 안정적인 콜백, 오래된 클로저 없음**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems)

  // 안정적인 콜백, 재생성되지 않음
  const addItems = useCallback((newItems: Item[]) => {
    setItems(curr => [...curr, ...newItems])
  }, [])  // ✅ 의존성 불필요

  // 항상 최신 상태를 사용, 오래된 클로저 위험 없음
  const removeItem = useCallback((id: string) => {
    setItems(curr => curr.filter(item => item.id !== id))
  }, [])  // ✅ 안전하고 안정적

  return <ItemsEditor items={items} onAdd={addItems} onRemove={removeItem} />
}
```

**장점:**

1. **안정적인 콜백 참조** - 상태 변경 시 콜백을 재생성할 필요 없음

2. **오래된 클로저 없음** - 항상 최신 상태 값으로 작동

3. **적은 의존성** - 의존성 배열을 단순화하고 메모리 누수를 감소

4. **버그 방지** - React 클로저 버그의 가장 흔한 원인을 제거

**함수형 업데이트를 사용할 때:**

- 현재 상태 값에 의존하는 모든 setState

- 상태가 필요한 useCallback/useMemo 내부

- 상태를 참조하는 이벤트 핸들러

- 상태를 업데이트하는 비동기 작업

**직접 업데이트가 괜찮은 경우:**

- 정적 값으로 상태 설정: `setCount(0)`

- props/인수에서만 상태 설정: `setName(newName)`

- 상태가 이전 값에 의존하지 않는 경우

**참고:** 프로젝트에 [React Compiler](https://react.dev/learn/react-compiler)가 활성화되어 있다면, 컴파일러가 일부 경우를 자동으로 최적화할 수 있지만, 정확성과 오래된 클로저 버그 방지를 위해 함수형 업데이트가 여전히 권장됩니다.

### 5.6 지연 상태 초기화 사용

**영향: MEDIUM (매 렌더마다 낭비되는 계산)**

비용이 큰 초기값에는 `useState`에 함수를 전달합니다. 함수 형태가 없으면, 값이 한 번만 사용되더라도 초기화 코드가 매 렌더마다 실행됩니다.

**잘못된 예: 매 렌더마다 실행**

```tsx
function FilteredList({ items }: { items: Item[] }) {
  // buildSearchIndex()가 초기화 후에도 매 렌더마다 실행됨
  const [searchIndex, setSearchIndex] = useState(buildSearchIndex(items))
  const [query, setQuery] = useState('')

  // query가 변경되면, buildSearchIndex가 불필요하게 다시 실행됨
  return <SearchResults index={searchIndex} query={query} />
}

function UserProfile() {
  // JSON.parse가 매 렌더마다 실행됨
  const [settings, setSettings] = useState(
    JSON.parse(localStorage.getItem('settings') || '{}')
  )

  return <SettingsForm settings={settings} onChange={setSettings} />
}
```

**올바른 예: 한 번만 실행**

```tsx
function FilteredList({ items }: { items: Item[] }) {
  // buildSearchIndex()가 초기 렌더 시에만 실행됨
  const [searchIndex, setSearchIndex] = useState(() => buildSearchIndex(items))
  const [query, setQuery] = useState('')

  return <SearchResults index={searchIndex} query={query} />
}

function UserProfile() {
  // JSON.parse가 초기 렌더 시에만 실행됨
  const [settings, setSettings] = useState(() => {
    const stored = localStorage.getItem('settings')
    return stored ? JSON.parse(stored) : {}
  })

  return <SettingsForm settings={settings} onChange={setSettings} />
}
```

localStorage/sessionStorage에서 초기값을 계산할 때, 데이터 구조(인덱스, 맵)를 구축할 때, DOM에서 읽을 때, 무거운 변환을 수행할 때 지연 초기화를 사용합니다.

단순 프리미티브(`useState(0)`), 직접 참조(`useState(props.value)`), 저렴한 리터럴(`useState({})`)에는 함수 형태가 불필요합니다.

### 5.7 긴급하지 않은 업데이트에 Transitions 사용

**영향: MEDIUM (UI 반응성 유지)**

빈번하고 긴급하지 않은 상태 업데이트를 Transition으로 표시하여 UI 반응성을 유지합니다.

**잘못된 예: 스크롤할 때마다 UI 블로킹**

```tsx
function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)
  useEffect(() => {
    const handler = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])
}
```

**올바른 예: 논블로킹 업데이트**

```tsx
import { startTransition } from 'react'

function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)
  useEffect(() => {
    const handler = () => {
      startTransition(() => setScrollY(window.scrollY))
    }
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])
}
```

---

## 6. 렌더링 성능

**영향: MEDIUM**

렌더링 프로세스를 최적화하면 브라우저가 수행해야 하는 작업이 줄어듭니다.

### 6.1 SVG 요소 대신 래퍼에 애니메이션 적용

**영향: LOW (하드웨어 가속 활성화)**

많은 브라우저에서 SVG 요소에 대한 CSS3 애니메이션의 하드웨어 가속이 없습니다. SVG를 `<div>`로 감싸고 래퍼에 애니메이션을 적용하세요.

**잘못된 예: SVG에 직접 애니메이션 - 하드웨어 가속 없음**

```tsx
function LoadingSpinner() {
  return (
    <svg
      className="animate-spin"
      width="24"
      height="24"
      viewBox="0 0 24 24"
    >
      <circle cx="12" cy="12" r="10" stroke="currentColor" />
    </svg>
  )
}
```

**올바른 예: 래퍼 div에 애니메이션 - 하드웨어 가속**

```tsx
function LoadingSpinner() {
  return (
    <div className="animate-spin">
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
      >
        <circle cx="12" cy="12" r="10" stroke="currentColor" />
      </svg>
    </div>
  )
}
```

이것은 모든 CSS transform과 transition(`transform`, `opacity`, `translate`, `scale`, `rotate`)에 적용됩니다. 래퍼 div는 브라우저가 더 부드러운 애니메이션을 위해 GPU 가속을 사용할 수 있게 합니다.

### 6.2 긴 목록에 CSS content-visibility 적용

**영향: HIGH (더 빠른 초기 렌더)**

`content-visibility: auto`를 적용하여 화면 밖 렌더링을 지연시킵니다.

**CSS:**

```css
.message-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px;
}
```

**예:**

```tsx
function MessageList({ messages }: { messages: Message[] }) {
  return (
    <div className="overflow-y-auto h-screen">
      {messages.map(msg => (
        <div key={msg.id} className="message-item">
          <Avatar user={msg.author} />
          <div>{msg.content}</div>
        </div>
      ))}
    </div>
  )
}
```

1000개 메시지의 경우, 브라우저가 ~990개 화면 밖 항목의 레이아웃/페인트를 건너뜁니다 (10배 빠른 초기 렌더).

### 6.3 정적 JSX 요소 호이스팅

**영향: LOW (재생성 방지)**

정적 JSX를 컴포넌트 외부로 추출하여 재생성을 방지합니다.

**잘못된 예: 매 렌더마다 요소를 재생성**

```tsx
function LoadingSkeleton() {
  return <div className="animate-pulse h-20 bg-gray-200" />
}

function Container() {
  return (
    <div>
      {loading && <LoadingSkeleton />}
    </div>
  )
}
```

**올바른 예: 같은 요소를 재사용**

```tsx
const loadingSkeleton = (
  <div className="animate-pulse h-20 bg-gray-200" />
)

function Container() {
  return (
    <div>
      {loading && loadingSkeleton}
    </div>
  )
}
```

이것은 특히 매 렌더마다 재생성하기에 비용이 큰 대형 정적 SVG 노드에 유용합니다.

**참고:** 프로젝트에 [React Compiler](https://react.dev/learn/react-compiler)가 활성화되어 있다면, 컴파일러가 자동으로 정적 JSX 요소를 호이스팅하고 컴포넌트 리렌더를 최적화하므로, 수동 호이스팅이 불필요합니다.

### 6.4 SVG 정밀도 최적화

**영향: LOW (파일 크기 감소)**

SVG 좌표 정밀도를 줄여 파일 크기를 줄입니다. 최적 정밀도는 viewBox 크기에 따라 다르지만, 일반적으로 정밀도를 줄이는 것을 고려해야 합니다.

**잘못된 예: 과도한 정밀도**

```svg
<path d="M 10.293847 20.847362 L 30.938472 40.192837" />
```

**올바른 예: 소수점 1자리**

```svg
<path d="M 10.3 20.8 L 30.9 40.2" />
```

**SVGO로 자동화:**

```bash
npx svgo --precision=1 --multipass icon.svg
```

### 6.5 깜빡임 없이 하이드레이션 불일치 방지

**영향: MEDIUM (시각적 깜빡임과 하이드레이션 에러 방지)**

클라이언트 사이드 저장소(localStorage, 쿠키)에 의존하는 콘텐츠를 렌더링할 때, React가 하이드레이션하기 전에 DOM을 업데이트하는 동기 스크립트를 삽입하여 SSR 문제와 하이드레이션 후 깜빡임을 모두 방지합니다.

**잘못된 예: SSR을 깨뜨림**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  // localStorage는 서버에서 사용할 수 없음 - 에러 발생
  const theme = localStorage.getItem('theme') || 'light'

  return (
    <div className={theme}>
      {children}
    </div>
  )
}
```

`localStorage`가 정의되지 않아 서버 사이드 렌더링이 실패합니다.

**잘못된 예: 시각적 깜빡임**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState('light')

  useEffect(() => {
    // 하이드레이션 후 실행 - 눈에 보이는 깜빡임 유발
    const stored = localStorage.getItem('theme')
    if (stored) {
      setTheme(stored)
    }
  }, [])

  return (
    <div className={theme}>
      {children}
    </div>
  )
}
```

컴포넌트가 먼저 기본값(`light`)으로 렌더링한 후 하이드레이션 후 업데이트되어, 잘못된 콘텐츠가 눈에 보이게 깜빡입니다.

**올바른 예: 깜빡임 없음, 하이드레이션 불일치 없음**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  return (
    <>
      <div id="theme-wrapper">
        {children}
      </div>
      <script
        dangerouslySetInnerHTML={{
          __html: `
            (function() {
              try {
                var theme = localStorage.getItem('theme') || 'light';
                var el = document.getElementById('theme-wrapper');
                if (el) el.className = theme;
              } catch (e) {}
            })();
          `,
        }}
      />
    </>
  )
}
```

인라인 스크립트가 요소를 표시하기 전에 동기적으로 실행되어, DOM이 이미 올바른 값을 가지게 합니다. 깜빡임 없음, 하이드레이션 불일치 없음.

이 패턴은 테마 토글, 사용자 설정, 인증 상태, 기본값의 깜빡임 없이 즉시 렌더링해야 하는 모든 클라이언트 전용 데이터에 특히 유용합니다.

### 6.6 표시/숨김에 Activity 컴포넌트 사용

**영향: MEDIUM (상태/DOM 보존)**

자주 가시성이 전환되는 비용이 큰 컴포넌트에 React의 `<Activity>`를 사용하여 상태/DOM을 보존합니다.

**사용법:**

```tsx
import { Activity } from 'react'

function Dropdown({ isOpen }: Props) {
  return (
    <Activity mode={isOpen ? 'visible' : 'hidden'}>
      <ExpensiveMenu />
    </Activity>
  )
}
```

비용이 큰 리렌더와 상태 손실을 방지합니다.

### 6.7 명시적 조건부 렌더링 사용

**영향: LOW (0 또는 NaN 렌더링 방지)**

조건이 `0`, `NaN` 또는 렌더링되는 기타 falsy 값이 될 수 있을 때, 조건부 렌더링에 `&&` 대신 명시적 삼항 연산자(`? :`)를 사용합니다.

**잘못된 예: count가 0일 때 "0"을 렌더링**

```tsx
function Badge({ count }: { count: number }) {
  return (
    <div>
      {count && <span className="badge">{count}</span>}
    </div>
  )
}

// count = 0일 때 렌더링: <div>0</div>
// count = 5일 때 렌더링: <div><span class="badge">5</span></div>
```

**올바른 예: count가 0일 때 아무것도 렌더링하지 않음**

```tsx
function Badge({ count }: { count: number }) {
  return (
    <div>
      {count > 0 ? <span className="badge">{count}</span> : null}
    </div>
  )
}

// count = 0일 때 렌더링: <div></div>
// count = 5일 때 렌더링: <div><span class="badge">5</span></div>
```

---

## 7. JavaScript 성능

**영향: LOW-MEDIUM**

핫 경로에 대한 마이크로 최적화가 누적되면 의미 있는 개선이 됩니다.

### 7.1 DOM CSS 변경 일괄 처리

**영향: MEDIUM (리플로우/리페인트 감소)**

스타일 쓰기와 레이아웃 읽기를 인터리빙하지 마세요. 스타일 변경 사이에 레이아웃 속성(`offsetWidth`, `getBoundingClientRect()`, `getComputedStyle()` 등)을 읽으면, 브라우저가 동기 리플로우를 강제로 트리거합니다.

**잘못된 예: 인터리빙된 읽기와 쓰기가 리플로우를 강제**

```typescript
function updateElementStyles(element: HTMLElement) {
  element.style.width = '100px'
  const width = element.offsetWidth  // 리플로우 강제
  element.style.height = '200px'
  const height = element.offsetHeight  // 또 다른 리플로우 강제
}
```

**올바른 예: 쓰기를 일괄 처리한 후 한 번 읽기**

```typescript
function updateElementStyles(element: HTMLElement) {
  element.classList.add('highlighted-box')

  const { width, height } = element.getBoundingClientRect()
}
```

**더 좋은 방법: CSS 클래스 사용**

가능하면 인라인 스타일보다 CSS 클래스를 선호하세요. CSS 파일은 브라우저에 의해 캐시되고, 클래스는 관심사 분리가 더 좋으며 유지보수가 더 쉽습니다.

### 7.2 반복 조회를 위한 인덱스 맵 구축

**영향: LOW-MEDIUM (1M 연산을 2K 연산으로)**

같은 키로 여러 번 `.find()` 호출하는 경우 Map을 사용해야 합니다.

**잘못된 예 (조회당 O(n)):**

```typescript
function processOrders(orders: Order[], users: User[]) {
  return orders.map(order => ({
    ...order,
    user: users.find(u => u.id === order.userId)
  }))
}
```

**올바른 예 (조회당 O(1)):**

```typescript
function processOrders(orders: Order[], users: User[]) {
  const userById = new Map(users.map(u => [u.id, u]))

  return orders.map(order => ({
    ...order,
    user: userById.get(order.userId)
  }))
}
```

맵을 한 번 구축(O(n))한 후, 모든 조회는 O(1)입니다.

1000개 주문 x 1000명 사용자의 경우: 1M 연산 -> 2K 연산.

### 7.3 루프에서 속성 접근 캐싱

**영향: LOW-MEDIUM (조회 횟수 감소)**

핫 경로에서 객체 속성 조회를 캐싱합니다.

**잘못된 예: N회 반복마다 3번 조회**

```typescript
for (let i = 0; i < arr.length; i++) {
  process(obj.config.settings.value)
}
```

**올바른 예: 총 1번 조회**

```typescript
const value = obj.config.settings.value
const len = arr.length
for (let i = 0; i < len; i++) {
  process(value)
}
```

### 7.4 반복 함수 호출 캐싱

**영향: MEDIUM (중복 계산 방지)**

렌더 중에 같은 입력으로 같은 함수가 반복 호출될 때, 모듈 수준 Map을 사용하여 함수 결과를 캐싱합니다.

**잘못된 예: 중복 계산**

```typescript
function ProjectList({ projects }: { projects: Project[] }) {
  return (
    <div>
      {projects.map(project => {
        // 같은 프로젝트 이름에 대해 slugify()가 100번 이상 호출됨
        const slug = slugify(project.name)

        return <ProjectCard key={project.id} slug={slug} />
      })}
    </div>
  )
}
```

**올바른 예: 캐시된 결과**

```typescript
// 모듈 수준 캐시
const slugifyCache = new Map<string, string>()

function cachedSlugify(text: string): string {
  if (slugifyCache.has(text)) {
    return slugifyCache.get(text)!
  }
  const result = slugify(text)
  slugifyCache.set(text, result)
  return result
}

function ProjectList({ projects }: { projects: Project[] }) {
  return (
    <div>
      {projects.map(project => {
        // 고유 프로젝트 이름당 한 번만 계산됨
        const slug = cachedSlugify(project.name)

        return <ProjectCard key={project.id} slug={slug} />
      })}
    </div>
  )
}
```

**단일 값 함수를 위한 더 간단한 패턴:**

```typescript
let isLoggedInCache: boolean | null = null

function isLoggedIn(): boolean {
  if (isLoggedInCache !== null) {
    return isLoggedInCache
  }

  isLoggedInCache = document.cookie.includes('auth=')
  return isLoggedInCache
}

// 인증 변경 시 캐시 초기화
function onAuthChange() {
  isLoggedInCache = null
}
```

Map(훅이 아닌)을 사용하면 유틸리티, 이벤트 핸들러 등 React 컴포넌트가 아닌 곳에서도 작동합니다.

참조: [https://vercel.com/blog/how-we-made-the-vercel-dashboard-twice-as-fast](https://vercel.com/blog/how-we-made-the-vercel-dashboard-twice-as-fast)

### 7.5 Storage API 호출 캐싱

**영향: LOW-MEDIUM (비용이 큰 I/O 감소)**

`localStorage`, `sessionStorage`, `document.cookie`는 동기적이고 비용이 큽니다. 읽기를 메모리에 캐싱합니다.

**잘못된 예: 호출할 때마다 스토리지를 읽음**

```typescript
function getTheme() {
  return localStorage.getItem('theme') ?? 'light'
}
// 10번 호출 = 10번 스토리지 읽기
```

**올바른 예: Map 캐시**

```typescript
const storageCache = new Map<string, string | null>()

function getLocalStorage(key: string) {
  if (!storageCache.has(key)) {
    storageCache.set(key, localStorage.getItem(key))
  }
  return storageCache.get(key)
}

function setLocalStorage(key: string, value: string) {
  localStorage.setItem(key, value)
  storageCache.set(key, value)  // 캐시 동기화 유지
}
```

Map(훅이 아닌)을 사용하면 유틸리티, 이벤트 핸들러 등 React 컴포넌트가 아닌 곳에서도 작동합니다.

**쿠키 캐싱:**

```typescript
let cookieCache: Record<string, string> | null = null

function getCookie(name: string) {
  if (!cookieCache) {
    cookieCache = Object.fromEntries(
      document.cookie.split('; ').map(c => c.split('='))
    )
  }
  return cookieCache[name]
}
```

**중요: 외부 변경 시 무효화**

```typescript
window.addEventListener('storage', (e) => {
  if (e.key) storageCache.delete(e.key)
})

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') {
    storageCache.clear()
  }
})
```

스토리지가 외부에서 변경될 수 있는 경우(다른 탭, 서버 설정 쿠키), 캐시를 무효화합니다:

### 7.6 여러 배열 반복 결합

**영향: LOW-MEDIUM (반복 횟수 감소)**

여러 `.filter()` 또는 `.map()` 호출은 배열을 여러 번 반복합니다. 하나의 루프로 결합합니다.

**잘못된 예: 3회 반복**

```typescript
const admins = users.filter(u => u.isAdmin)
const testers = users.filter(u => u.isTester)
const inactive = users.filter(u => !u.isActive)
```

**올바른 예: 1회 반복**

```typescript
const admins: User[] = []
const testers: User[] = []
const inactive: User[] = []

for (const user of users) {
  if (user.isAdmin) admins.push(user)
  if (user.isTester) testers.push(user)
  if (!user.isActive) inactive.push(user)
}
```

### 7.7 배열 비교 시 조기 길이 검사

**영향: MEDIUM-HIGH (길이가 다를 때 비용이 큰 연산 방지)**

비용이 큰 연산(정렬, 깊은 동등성, 직렬화)으로 배열을 비교할 때, 먼저 길이를 검사합니다. 길이가 다르면 배열은 같을 수 없습니다.

실제 애플리케이션에서 이 최적화는 비교가 핫 경로(이벤트 핸들러, 렌더 루프)에서 실행될 때 특히 유용합니다.

**잘못된 예: 항상 비용이 큰 비교를 실행**

```typescript
function hasChanges(current: string[], original: string[]) {
  // 길이가 다를 때도 항상 정렬하고 결합
  return current.sort().join() !== original.sort().join()
}
```

`current.length`가 5이고 `original.length`가 100일 때도 두 번의 O(n log n) 정렬이 실행됩니다. 배열을 결합하고 문자열을 비교하는 오버헤드도 있습니다.

**올바른 예 (O(1) 길이 검사 먼저):**

```typescript
function hasChanges(current: string[], original: string[]) {
  // 길이가 다르면 조기 반환
  if (current.length !== original.length) {
    return true
  }
  // 길이가 같을 때만 정렬
  const currentSorted = current.toSorted()
  const originalSorted = original.toSorted()
  for (let i = 0; i < currentSorted.length; i++) {
    if (currentSorted[i] !== originalSorted[i]) {
      return true
    }
  }
  return false
}
```

이 새로운 접근 방식이 더 효율적인 이유:

- 길이가 다를 때 정렬과 결합의 오버헤드를 방지

- 결합된 문자열의 메모리 소비를 방지 (특히 큰 배열에서 중요)

- 원본 배열의 변이를 방지

- 차이가 발견되면 조기 반환

### 7.8 함수에서 조기 반환

**영향: LOW-MEDIUM (불필요한 계산 방지)**

결과가 결정되면 조기에 반환하여 불필요한 처리를 건너뜁니다.

**잘못된 예: 답을 찾은 후에도 모든 항목을 처리**

```typescript
function validateUsers(users: User[]) {
  let hasError = false
  let errorMessage = ''

  for (const user of users) {
    if (!user.email) {
      hasError = true
      errorMessage = 'Email required'
    }
    if (!user.name) {
      hasError = true
      errorMessage = 'Name required'
    }
    // 에러를 찾은 후에도 계속 모든 사용자를 검사
  }

  return hasError ? { valid: false, error: errorMessage } : { valid: true }
}
```

**올바른 예: 첫 번째 에러에서 즉시 반환**

```typescript
function validateUsers(users: User[]) {
  for (const user of users) {
    if (!user.email) {
      return { valid: false, error: 'Email required' }
    }
    if (!user.name) {
      return { valid: false, error: 'Name required' }
    }
  }

  return { valid: true }
}
```

### 7.9 RegExp 생성 호이스팅

**영향: LOW-MEDIUM (재생성 방지)**

렌더 내부에서 RegExp를 생성하지 마세요. 모듈 스코프로 호이스팅하거나 `useMemo()`로 메모이제이션합니다.

**잘못된 예: 매 렌더마다 새 RegExp**

```tsx
function Highlighter({ text, query }: Props) {
  const regex = new RegExp(`(${query})`, 'gi')
  const parts = text.split(regex)
  return <>{parts.map((part, i) => ...)}</>
}
```

**올바른 예: 메모이제이션 또는 호이스팅**

```tsx
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function Highlighter({ text, query }: Props) {
  const regex = useMemo(
    () => new RegExp(`(${escapeRegex(query)})`, 'gi'),
    [query]
  )
  const parts = text.split(regex)
  return <>{parts.map((part, i) => ...)}</>
}
```

**경고: 전역 정규식은 가변 상태를 가짐**

```typescript
const regex = /foo/g
regex.test('foo')  // true, lastIndex = 3
regex.test('foo')  // false, lastIndex = 0
```

전역 정규식(`/g`)은 가변 `lastIndex` 상태를 가집니다:

### 7.10 정렬 대신 루프로 Min/Max 찾기

**영향: LOW (O(n log n) 대신 O(n))**

가장 작거나 큰 요소를 찾는 데는 배열을 한 번만 순회하면 됩니다. 정렬은 낭비적이고 느립니다.

**잘못된 예 (O(n log n) - 최신 항목을 찾기 위해 정렬):**

```typescript
interface Project {
  id: string
  name: string
  updatedAt: number
}

function getLatestProject(projects: Project[]) {
  const sorted = [...projects].sort((a, b) => b.updatedAt - a.updatedAt)
  return sorted[0]
}
```

최대값을 찾기 위해 전체 배열을 정렬합니다.

**잘못된 예 (O(n log n) - 가장 오래된 것과 최신 것을 위해 정렬):**

```typescript
function getOldestAndNewest(projects: Project[]) {
  const sorted = [...projects].sort((a, b) => a.updatedAt - b.updatedAt)
  return { oldest: sorted[0], newest: sorted[sorted.length - 1] }
}
```

min/max만 필요할 때 여전히 불필요하게 정렬합니다.

**올바른 예 (O(n) - 단일 루프):**

```typescript
function getLatestProject(projects: Project[]) {
  if (projects.length === 0) return null

  let latest = projects[0]

  for (let i = 1; i < projects.length; i++) {
    if (projects[i].updatedAt > latest.updatedAt) {
      latest = projects[i]
    }
  }

  return latest
}

function getOldestAndNewest(projects: Project[]) {
  if (projects.length === 0) return { oldest: null, newest: null }

  let oldest = projects[0]
  let newest = projects[0]

  for (let i = 1; i < projects.length; i++) {
    if (projects[i].updatedAt < oldest.updatedAt) oldest = projects[i]
    if (projects[i].updatedAt > newest.updatedAt) newest = projects[i]
  }

  return { oldest, newest }
}
```

배열을 한 번 순회, 복사 없음, 정렬 없음.

**대안: 작은 배열에 Math.min/Math.max**

```typescript
const numbers = [5, 2, 8, 1, 9]
const min = Math.min(...numbers)
const max = Math.max(...numbers)
```

이것은 작은 배열에서는 동작하지만, 스프레드 연산자 제한으로 인해 매우 큰 배열에서는 느리거나 에러를 발생시킬 수 있습니다. 최대 배열 길이는 Chrome 143에서 약 124000, Safari 18에서 약 638000입니다; 정확한 숫자는 다를 수 있습니다 - [피들](https://jsfiddle.net/qw1jabsx/4/)을 참조하세요. 안정성을 위해 루프 접근 방식을 사용하세요.

### 7.11 O(1) 조회를 위한 Set/Map 사용

**영향: LOW-MEDIUM (O(n)에서 O(1)로)**

반복 멤버십 검사를 위해 배열을 Set/Map으로 변환합니다.

**잘못된 예 (검사당 O(n)):**

```typescript
const allowedIds = ['a', 'b', 'c', ...]
items.filter(item => allowedIds.includes(item.id))
```

**올바른 예 (검사당 O(1)):**

```typescript
const allowedIds = new Set(['a', 'b', 'c', ...])
items.filter(item => allowedIds.has(item.id))
```

### 7.12 불변성을 위해 sort() 대신 toSorted() 사용

**영향: MEDIUM-HIGH (React 상태의 변이 버그 방지)**

`.sort()`는 배열을 원본에서 직접 변이시키며, React 상태와 props에 버그를 유발할 수 있습니다. `.toSorted()`를 사용하여 변이 없이 새로운 정렬된 배열을 생성합니다.

**잘못된 예: 원본 배열을 변이**

```typescript
function UserList({ users }: { users: User[] }) {
  // users prop 배열을 변이시킴!
  const sorted = useMemo(
    () => users.sort((a, b) => a.name.localeCompare(b.name)),
    [users]
  )
  return <div>{sorted.map(renderUser)}</div>
}
```

**올바른 예: 새 배열을 생성**

```typescript
function UserList({ users }: { users: User[] }) {
  // 새 정렬된 배열을 생성, 원본은 변경되지 않음
  const sorted = useMemo(
    () => users.toSorted((a, b) => a.name.localeCompare(b.name)),
    [users]
  )
  return <div>{sorted.map(renderUser)}</div>
}
```

**React에서 이것이 중요한 이유:**

1. Props/상태 변이는 React의 불변성 모델을 위반 - React는 props와 상태가 읽기 전용으로 취급되기를 기대

2. 오래된 클로저 버그 유발 - 클로저(콜백, effect) 내에서 배열을 변이시키면 예상치 못한 동작이 발생할 수 있음

**브라우저 지원: 이전 브라우저를 위한 폴백**

```typescript
// 이전 브라우저를 위한 폴백
const sorted = [...items].sort((a, b) => a.value - b.value)
```

`.toSorted()`는 모든 최신 브라우저에서 사용 가능합니다(Chrome 110+, Safari 16+, Firefox 115+, Node.js 20+). 이전 환경에서는 스프레드 연산자를 사용하세요:

**기타 불변 배열 메서드:**

- `.toSorted()` - 불변 정렬

- `.toReversed()` - 불변 역순

- `.toSpliced()` - 불변 splice

- `.with()` - 불변 요소 교체

---

## 8. 고급 패턴

**영향: LOW**

세심한 구현이 필요한 특정 경우를 위한 고급 패턴입니다.

### 8.1 Ref에 이벤트 핸들러 저장

**영향: LOW (안정적인 구독)**

콜백 변경 시 다시 구독하지 않아야 하는 effect에서 사용되는 콜백을 ref에 저장합니다.

**잘못된 예: 매 렌더마다 다시 구독**

```tsx
function useWindowEvent(event: string, handler: (e) => void) {
  useEffect(() => {
    window.addEventListener(event, handler)
    return () => window.removeEventListener(event, handler)
  }, [event, handler])
}
```

**올바른 예: 안정적인 구독**

```tsx
import { useEffectEvent } from 'react'

function useWindowEvent(event: string, handler: (e) => void) {
  const onEvent = useEffectEvent(handler)

  useEffect(() => {
    window.addEventListener(event, onEvent)
    return () => window.removeEventListener(event, onEvent)
  }, [event])
}
```

**대안: 최신 React를 사용 중이라면 `useEffectEvent` 사용:**

`useEffectEvent`는 같은 패턴에 대해 더 깔끔한 API를 제공합니다: 항상 핸들러의 최신 버전을 호출하는 안정적인 함수 참조를 생성합니다.

### 8.2 안정적 콜백 참조를 위한 useLatest

**영향: LOW (effect 재실행 방지)**

의존성 배열에 추가하지 않고 콜백에서 최신 값에 접근합니다. 오래된 클로저를 방지하면서 effect 재실행을 방지합니다.

**구현:**

```typescript
function useLatest<T>(value: T) {
  const ref = useRef(value)
  useLayoutEffect(() => {
    ref.current = value
  }, [value])
  return ref
}
```

**잘못된 예: 콜백 변경마다 effect가 재실행**

```tsx
function SearchInput({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState('')

  useEffect(() => {
    const timeout = setTimeout(() => onSearch(query), 300)
    return () => clearTimeout(timeout)
  }, [query, onSearch])
}
```

**올바른 예: 안정적인 effect, 최신 콜백**

```tsx
function SearchInput({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState('')
  const onSearchRef = useLatest(onSearch)

  useEffect(() => {
    const timeout = setTimeout(() => onSearchRef.current(query), 300)
    return () => clearTimeout(timeout)
  }, [query])
}
```

---

## 참고 자료

1. [https://react.dev](https://react.dev)
2. [https://nextjs.org](https://nextjs.org)
3. [https://swr.vercel.app](https://swr.vercel.app)
4. [https://github.com/shuding/better-all](https://github.com/shuding/better-all)
5. [https://github.com/isaacs/node-lru-cache](https://github.com/isaacs/node-lru-cache)
6. [https://vercel.com/blog/how-we-optimized-package-imports-in-next-js](https://vercel.com/blog/how-we-optimized-package-imports-in-next-js)
7. [https://vercel.com/blog/how-we-made-the-vercel-dashboard-twice-as-fast](https://vercel.com/blog/how-we-made-the-vercel-dashboard-twice-as-fast)
