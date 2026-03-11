---
name: nextjs-testing
description: Next.js 테스트 가이드. Vitest 유닛 테스트, Cypress 컴포넌트/E2E 테스트. "테스트 작성", "유닛 테스트", "컴포넌트 테스트", "e2e 테스트", "vitest", "cypress" 등의 요청 시 사용.
version: 1.0.0
---

# Next.js 테스트 작성

## 참조 문서

상세 설정과 고급 패턴은 아래 참조 문서를 확인한다:

- [Vitest 상세 설정](references/vitest-config.md) - vitest.config.ts, path alias, 커버리지, next/* 모킹
- [Cypress 상세 설정](references/cypress-config.md) - cypress.config.ts, 컴포넌트/E2E devServer, support 파일
- [고급 패턴](references/patterns.md) - MSW, 픽스처, 커스텀 커맨드, 세션 관리, 환경별 테스트
- [문제 해결](references/troubleshooting.md) - Vitest/Cypress 문제 해결, CI/CD 설정

## 개요

Next.js 프로젝트에서 Vitest(유닛 테스트)와 Cypress(컴포넌트/E2E 테스트)를 조합하여 테스트를 작성한다.

| 테스트 유형 | 도구 | 대상 | 속도 |
|------------|------|------|------|
| 유닛 테스트 | Vitest | 유틸, Hook, Server Action, API Route, Store | 빠름 |
| 컴포넌트 테스트 | Cypress | React 컴포넌트 (실제 브라우저 렌더링) | 보통 |
| E2E 테스트 | Cypress | 전체 사용자 플로우 (페이지 간 이동, 폼 제출) | 느림 |

**도구 선택 이유:**
- **Vitest**: ESM 네이티브 지원, 빠른 실행, `@vitejs/plugin-react`로 Next.js JSX 변환 처리
- **Cypress**: 실제 브라우저 환경, 컴포넌트+E2E 단일 도구, Next.js 공식 지원 (`framework: 'next'`)

## 사전 요구사항

```bash
# Vitest (유닛 테스트)
pnpm add -D vitest @vitejs/plugin-react @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom

# Cypress (컴포넌트/E2E 테스트)
pnpm add -D cypress
```

## 파일 구조 및 네이밍 규칙

```
project/
├── __tests__/                    # Vitest 유닛 테스트
│   ├── lib/
│   │   └── utils.test.ts         # 유틸리티 함수 테스트
│   ├── hooks/
│   │   └── use-counter.test.ts   # Hook 테스트
│   ├── actions/
│   │   └── user.test.ts          # Server Action 테스트
│   ├── api/
│   │   └── users/
│   │       └── route.test.ts     # API Route 테스트
│   └── stores/
│       └── cart.test.ts          # Zustand 스토어 테스트
├── cypress/
│   ├── component/                # 컴포넌트 테스트
│   │   ├── button.cy.tsx
│   │   └── login-form.cy.tsx
│   ├── e2e/                      # E2E 테스트
│   │   ├── auth.cy.ts
│   │   └── checkout.cy.ts
│   ├── support/
│   │   ├── component.tsx         # 컴포넌트 테스트 셋업
│   │   ├── e2e.ts                # E2E 테스트 셋업
│   │   └── commands.ts           # 커스텀 커맨드
│   └── fixtures/                 # 테스트 데이터
│       └── users.json
├── vitest.config.ts
└── cypress.config.ts
```

**네이밍 규칙:**
- Vitest 유닛 테스트: `*.test.ts` / `*.test.tsx`
- Cypress 컴포넌트 테스트: `*.cy.tsx`
- Cypress E2E 테스트: `*.cy.ts`

## Vitest 설정 (요약)

```typescript
// vitest.config.ts
import react from '@vitejs/plugin-react';
import { resolve } from 'path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './'),
    },
  },
  test: {
    globals: false,
    environment: 'jsdom',
    include: ['__tests__/**/*.test.{ts,tsx}'],
    setupFiles: ['./vitest.setup.ts'],
    coverage: {
      provider: 'v8',
      include: ['lib/**', 'hooks/**', 'app/actions/**', 'app/api/**'],
      exclude: ['**/*.d.ts'],
    },
  },
});
```

```typescript
// vitest.setup.ts
import '@testing-library/jest-dom/vitest';
```

> 상세 설정은 [Vitest 상세 설정](references/vitest-config.md) 참조.

## 유닛 테스트 패턴 (Vitest)

### 유틸리티 함수

```typescript
// __tests__/lib/utils.test.ts
import { describe, it, expect } from 'vitest';
import { formatPrice, slugify, truncate } from '@/lib/utils';

describe('formatPrice', () => {
  it('should format number to KRW', () => {
    expect(formatPrice(10000)).toBe('₩10,000');
  });

  it('should handle zero', () => {
    expect(formatPrice(0)).toBe('₩0');
  });
});

describe('slugify', () => {
  it('should convert string to slug', () => {
    expect(slugify('Hello World')).toBe('hello-world');
  });

  it('should remove special characters', () => {
    expect(slugify('Hello @World!')).toBe('hello-world');
  });
});

describe('truncate', () => {
  it('should truncate long text', () => {
    expect(truncate('Lorem ipsum dolor sit amet', 10)).toBe('Lorem ipsu...');
  });

  it('should return original text if shorter than limit', () => {
    expect(truncate('Short', 10)).toBe('Short');
  });
});
```

### React Hook

```typescript
// __tests__/hooks/use-counter.test.ts
import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useCounter } from '@/hooks/use-counter';

describe('useCounter', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter());
    expect(result.current.count).toBe(0);
  });

  it('should initialize with custom value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });

  it('should increment', () => {
    const { result } = renderHook(() => useCounter());
    act(() => result.current.increment());
    expect(result.current.count).toBe(1);
  });

  it('should decrement', () => {
    const { result } = renderHook(() => useCounter(5));
    act(() => result.current.decrement());
    expect(result.current.count).toBe(4);
  });

  it('should reset to initial value', () => {
    const { result } = renderHook(() => useCounter(5));
    act(() => result.current.increment());
    act(() => result.current.reset());
    expect(result.current.count).toBe(5);
  });
});
```

### Server Action

```typescript
// __tests__/actions/user.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

// next/cache 모킹
vi.mock('next/cache', () => ({
  revalidateTag: vi.fn(),
  updateTag: vi.fn(),
}));

// next/headers 모킹
vi.mock('next/headers', () => ({
  cookies: vi.fn(() => ({
    get: vi.fn((name: string) => ({ name, value: 'mock-session-id' })),
    set: vi.fn(),
    delete: vi.fn(),
  })),
  headers: vi.fn(() => new Map([['authorization', 'Bearer mock-token']])),
}));

import { createUser, deleteUser } from '@/app/actions/user';
import { updateTag } from 'next/cache';

// DB 모킹 (Prisma 예시)
vi.mock('@/lib/db', () => ({
  db: {
    user: {
      create: vi.fn(),
      delete: vi.fn(),
    },
  },
}));

import { db } from '@/lib/db';

describe('User Server Actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('createUser', () => {
    it('should create a user and revalidate', async () => {
      const mockUser = { id: '1', name: 'John', email: 'john@test.com' };
      vi.mocked(db.user.create).mockResolvedValue(mockUser);

      const formData = new FormData();
      formData.set('name', 'John');
      formData.set('email', 'john@test.com');

      const result = await createUser(formData);

      expect(db.user.create).toHaveBeenCalledWith({
        data: { name: 'John', email: 'john@test.com' },
      });
      expect(updateTag).toHaveBeenCalledWith('users');
      expect(result).toEqual({ success: true });
    });

    it('should return error for invalid data', async () => {
      const formData = new FormData();
      formData.set('name', '');
      formData.set('email', 'invalid');

      const result = await createUser(formData);

      expect(result).toHaveProperty('error');
      expect(db.user.create).not.toHaveBeenCalled();
    });
  });

  describe('deleteUser', () => {
    it('should delete user by id', async () => {
      vi.mocked(db.user.delete).mockResolvedValue({ id: '1' } as any);

      const result = await deleteUser('1');

      expect(db.user.delete).toHaveBeenCalledWith({ where: { id: '1' } });
      expect(updateTag).toHaveBeenCalledWith('users');
      expect(result).toEqual({ success: true });
    });
  });
});
```

### API Route Handler

```typescript
// __tests__/api/users/route.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GET, POST } from '@/app/api/users/route';
import { NextRequest } from 'next/server';

vi.mock('@/lib/db', () => ({
  db: {
    user: {
      findMany: vi.fn(),
      create: vi.fn(),
    },
  },
}));

import { db } from '@/lib/db';

describe('GET /api/users', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return users list', async () => {
    const mockUsers = [{ id: '1', name: 'John' }];
    vi.mocked(db.user.findMany).mockResolvedValue(mockUsers);

    const request = new NextRequest('http://localhost:3000/api/users');
    const response = await GET(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toEqual(mockUsers);
  });

  it('should support search params', async () => {
    vi.mocked(db.user.findMany).mockResolvedValue([]);

    const request = new NextRequest('http://localhost:3000/api/users?search=john');
    await GET(request);

    expect(db.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          name: expect.objectContaining({ contains: 'john' }),
        }),
      }),
    );
  });
});

describe('POST /api/users', () => {
  it('should create a user', async () => {
    const mockUser = { id: '1', name: 'John', email: 'john@test.com' };
    vi.mocked(db.user.create).mockResolvedValue(mockUser);

    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify({ name: 'John', email: 'john@test.com' }),
    });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data).toEqual(mockUser);
  });

  it('should return 400 for invalid body', async () => {
    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify({ name: '' }),
    });
    const response = await POST(request);

    expect(response.status).toBe(400);
  });
});
```

### Zustand 스토어

```typescript
// __tests__/stores/cart.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { useCartStore } from '@/stores/cart';

describe('useCartStore', () => {
  beforeEach(() => {
    // 스토어 초기화
    useCartStore.setState({
      items: [],
      total: 0,
    });
  });

  it('should add item to cart', () => {
    const item = { id: '1', name: '상품', price: 10000, quantity: 1 };

    useCartStore.getState().addItem(item);

    const { items } = useCartStore.getState();
    expect(items).toHaveLength(1);
    expect(items[0]).toEqual(item);
  });

  it('should increase quantity for duplicate item', () => {
    const item = { id: '1', name: '상품', price: 10000, quantity: 1 };

    useCartStore.getState().addItem(item);
    useCartStore.getState().addItem(item);

    const { items } = useCartStore.getState();
    expect(items).toHaveLength(1);
    expect(items[0].quantity).toBe(2);
  });

  it('should remove item from cart', () => {
    const item = { id: '1', name: '상품', price: 10000, quantity: 1 };
    useCartStore.setState({ items: [item] });

    useCartStore.getState().removeItem('1');

    expect(useCartStore.getState().items).toHaveLength(0);
  });

  it('should calculate total', () => {
    useCartStore.setState({
      items: [
        { id: '1', name: '상품A', price: 10000, quantity: 2 },
        { id: '2', name: '상품B', price: 5000, quantity: 1 },
      ],
    });

    useCartStore.getState().calculateTotal();

    expect(useCartStore.getState().total).toBe(25000);
  });

  it('should clear cart', () => {
    useCartStore.setState({
      items: [{ id: '1', name: '상품', price: 10000, quantity: 1 }],
      total: 10000,
    });

    useCartStore.getState().clearCart();

    expect(useCartStore.getState().items).toHaveLength(0);
    expect(useCartStore.getState().total).toBe(0);
  });
});
```

## Cypress 컴포넌트 테스트 패턴

### 기본 컴포넌트 마운트

```tsx
// cypress/component/button.cy.tsx
import { Button } from '@/components/ui/button';

describe('Button', () => {
  it('should render with text', () => {
    cy.mount(<Button>클릭</Button>);
    cy.contains('클릭').should('be.visible');
  });

  it('should apply variant classes', () => {
    cy.mount(<Button variant="destructive">삭제</Button>);
    cy.get('button').should('have.class', 'bg-destructive');
  });

  it('should be disabled', () => {
    cy.mount(<Button disabled>비활성</Button>);
    cy.get('button').should('be.disabled');
  });
});
```

### 인터랙션 + 콜백 검증

```tsx
// cypress/component/counter.cy.tsx
import { Counter } from '@/components/counter';

describe('Counter', () => {
  it('should call onChange when incremented', () => {
    const onChange = cy.stub().as('onChange');
    cy.mount(<Counter initialValue={0} onChange={onChange} />);

    cy.contains('+').click();

    cy.get('@onChange').should('have.been.calledWith', 1);
  });

  it('should display current count', () => {
    cy.mount(<Counter initialValue={5} />);
    cy.get('[data-testid="count"]').should('have.text', '5');
  });

  it('should not go below zero', () => {
    cy.mount(<Counter initialValue={0} />);
    cy.contains('-').click();
    cy.get('[data-testid="count"]').should('have.text', '0');
  });
});
```

### 폼 컴포넌트

```tsx
// cypress/component/login-form.cy.tsx
import { LoginForm } from '@/components/login-form';

describe('LoginForm', () => {
  it('should submit with valid credentials', () => {
    const onSubmit = cy.stub().as('onSubmit');
    cy.mount(<LoginForm onSubmit={onSubmit} />);

    cy.get('input[name="email"]').type('user@test.com');
    cy.get('input[name="password"]').type('P@ssw0rd!');
    cy.get('button[type="submit"]').click();

    cy.get('@onSubmit').should('have.been.calledOnce');
  });

  it('should show validation errors', () => {
    cy.mount(<LoginForm onSubmit={cy.stub()} />);

    cy.get('button[type="submit"]').click();

    cy.contains('이메일을 입력해주세요').should('be.visible');
    cy.contains('비밀번호를 입력해주세요').should('be.visible');
  });

  it('should toggle password visibility', () => {
    cy.mount(<LoginForm onSubmit={cy.stub()} />);

    cy.get('input[name="password"]').should('have.attr', 'type', 'password');
    cy.get('[data-testid="toggle-password"]').click();
    cy.get('input[name="password"]').should('have.attr', 'type', 'text');
  });
});
```

### Next.js 기능 포함 컴포넌트

```tsx
// cypress/component/product-card.cy.tsx
import { ProductCard } from '@/components/product-card';

// next/image와 next/link는 Cypress 컴포넌트 테스트에서 자동으로 처리됨
// (framework: 'next' 설정 시)

describe('ProductCard', () => {
  const product = {
    id: '1',
    name: '테스트 상품',
    price: 15000,
    image: '/products/test.jpg',
    href: '/products/1',
  };

  it('should render product info', () => {
    cy.mount(<ProductCard {...product} />);

    cy.contains('테스트 상품').should('be.visible');
    cy.contains('₩15,000').should('be.visible');
    cy.get('img').should('have.attr', 'src').and('include', 'test.jpg');
  });

  it('should link to product page', () => {
    cy.mount(<ProductCard {...product} />);
    cy.get('a').should('have.attr', 'href', '/products/1');
  });
});
```

## Cypress E2E 테스트 패턴

### 페이지 네비게이션

```typescript
// cypress/e2e/navigation.cy.ts
describe('Navigation', () => {
  it('should navigate between pages', () => {
    cy.visit('/');

    cy.contains('상품').click();
    cy.url().should('include', '/products');
    cy.get('h1').should('contain', '상품 목록');

    cy.contains('회사 소개').click();
    cy.url().should('include', '/about');
  });

  it('should show 404 for unknown routes', () => {
    cy.visit('/unknown-page', { failOnStatusCode: false });
    cy.contains('페이지를 찾을 수 없습니다').should('be.visible');
  });
});
```

### 폼 제출 플로우

```typescript
// cypress/e2e/contact.cy.ts
describe('Contact Form', () => {
  beforeEach(() => {
    cy.visit('/contact');
  });

  it('should submit form successfully', () => {
    cy.intercept('POST', '/api/contact', {
      statusCode: 200,
      body: { success: true },
    }).as('submitContact');

    cy.get('input[name="name"]').type('홍길동');
    cy.get('input[name="email"]').type('hong@test.com');
    cy.get('textarea[name="message"]').type('문의 내용입니다.');
    cy.get('button[type="submit"]').click();

    cy.wait('@submitContact');
    cy.contains('문의가 접수되었습니다').should('be.visible');
  });

  it('should show validation errors on empty submit', () => {
    cy.get('button[type="submit"]').click();
    cy.get('[data-testid="error-name"]').should('be.visible');
    cy.get('[data-testid="error-email"]').should('be.visible');
  });
});
```

### 인증 플로우

```typescript
// cypress/e2e/auth.cy.ts
describe('Authentication', () => {
  it('should login and access dashboard', () => {
    cy.visit('/login');

    cy.get('input[name="email"]').type('admin@test.com');
    cy.get('input[name="password"]').type('P@ssw0rd!');
    cy.get('button[type="submit"]').click();

    cy.url().should('include', '/dashboard');
    cy.contains('대시보드').should('be.visible');
  });

  it('should redirect unauthenticated users to login', () => {
    cy.visit('/dashboard');
    cy.url().should('include', '/login');
  });

  it('should logout', () => {
    // 세션 캐싱으로 빠른 로그인
    cy.session('admin', () => {
      cy.visit('/login');
      cy.get('input[name="email"]').type('admin@test.com');
      cy.get('input[name="password"]').type('P@ssw0rd!');
      cy.get('button[type="submit"]').click();
      cy.url().should('include', '/dashboard');
    });

    cy.visit('/dashboard');
    cy.get('[data-testid="logout-button"]').click();
    cy.url().should('include', '/login');
  });
});
```

### API 인터셉트/스텁

```typescript
// cypress/e2e/products.cy.ts
describe('Products Page', () => {
  beforeEach(() => {
    // API 응답 스텁
    cy.intercept('GET', '/api/products*', {
      fixture: 'products.json',
    }).as('getProducts');

    cy.visit('/products');
    cy.wait('@getProducts');
  });

  it('should display product list', () => {
    cy.get('[data-testid="product-card"]').should('have.length.greaterThan', 0);
  });

  it('should filter products by search', () => {
    cy.intercept('GET', '/api/products?search=키보드*', {
      body: [{ id: '1', name: '기계식 키보드', price: 89000 }],
    }).as('searchProducts');

    cy.get('input[placeholder="검색"]').type('키보드');
    cy.wait('@searchProducts');

    cy.get('[data-testid="product-card"]').should('have.length', 1);
    cy.contains('기계식 키보드').should('be.visible');
  });

  it('should handle API error', () => {
    cy.intercept('GET', '/api/products*', {
      statusCode: 500,
      body: { error: 'Internal Server Error' },
    }).as('getProductsError');

    cy.visit('/products');
    cy.wait('@getProductsError');

    cy.contains('오류가 발생했습니다').should('be.visible');
  });

  it('should add product to cart', () => {
    cy.intercept('POST', '/api/cart', {
      statusCode: 200,
      body: { success: true },
    }).as('addToCart');

    cy.get('[data-testid="product-card"]').first().within(() => {
      cy.contains('장바구니').click();
    });

    cy.wait('@addToCart');
    cy.contains('장바구니에 추가되었습니다').should('be.visible');
  });
});
```

## 테스트 실행 명령어

```json
// package.json scripts
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:cov": "vitest run --coverage",
    "cy:open": "cypress open",
    "cy:component": "cypress run --component",
    "cy:e2e": "cypress run --e2e",
    "cy:e2e:headed": "cypress run --e2e --headed"
  }
}
```

```bash
# Vitest 유닛 테스트
pnpm test                    # 전체 실행
pnpm test:watch              # Watch 모드
pnpm test:cov                # 커버리지 포함

# Cypress 컴포넌트 테스트
pnpm cy:open                 # GUI 열기 (컴포넌트/E2E 선택)
pnpm cy:component            # 헤드리스 실행

# Cypress E2E 테스트
pnpm cy:e2e                  # 헤드리스 실행
pnpm cy:e2e:headed           # 브라우저 표시
```

## Server Component 테스트 전략

Server Components는 직접 유닛 테스트할 수 없다. 대신 다음 전략을 사용한다:

| 대상 | 테스트 방법 |
|------|-----------|
| 데이터 페칭 함수 | Vitest 유닛 테스트 (함수 단독 테스트) |
| Server Action | Vitest 유닛 테스트 (next/cache, next/headers 모킹) |
| 렌더링 결과 | Cypress E2E (전체 페이지 방문하여 검증) |
| 클라이언트 인터랙션 | Cypress 컴포넌트 테스트 (Client Component 단위) |

## 체크리스트

### Vitest

- [ ] `vitest.config.ts`에 `@vitejs/plugin-react` 플러그인 설정
- [ ] `vitest.setup.ts`에 `@testing-library/jest-dom/vitest` import
- [ ] `@/` path alias가 `tsconfig.json`과 일치
- [ ] Server Action 테스트 시 `next/cache`, `next/headers` 모킹
- [ ] Zustand 스토어 테스트 시 `beforeEach`에서 `.setState()` 초기화
- [ ] 각 유닛에 정상 케이스 + 에러 케이스 테스트

### Cypress

- [ ] `cypress.config.ts`에 `framework: 'next'`, `bundler: 'webpack'` 설정
- [ ] `cypress/support/component.tsx`에 globals.css import + Provider 래핑
- [ ] E2E 테스트 시 `cy.intercept()`로 API 스텁 처리
- [ ] `data-testid` 속성으로 요소 선택 (CSS 클래스 의존 방지)
- [ ] 인증 플로우에 `cy.session()` 사용하여 테스트 속도 향상

### 공통

- [ ] 테스트 파일 네이밍: Vitest=`*.test.ts(x)`, Cypress=`*.cy.ts(x)`
- [ ] Mock 데이터는 팩토리 함수로 생성 (`createMockUser()` 패턴)
- [ ] `beforeEach`에서 상태/Mock 초기화
- [ ] CI에서 Cypress는 headless 모드로 실행
