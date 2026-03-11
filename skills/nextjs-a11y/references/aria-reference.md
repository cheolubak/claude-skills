# ARIA Role, 속성 및 상태 참고 자료

ARIA(Accessible Rich Internet Applications)의 role, state, property에 대한 빠른 참고 가이드입니다. 사용 예제와 흔한 실수를 포함합니다.

---

## 목차

1. [ARIA 사용 규칙](#aria-사용-규칙)
2. [랜드마크 Role (Landmark Roles)](#랜드마크-role-landmark-roles)
3. [위젯 Role (Widget Roles)](#위젯-role-widget-roles)
4. [문서 구조 Role (Document Structure Roles)](#문서-구조-role-document-structure-roles)
5. [ARIA 상태 및 속성 (States & Properties)](#aria-상태-및-속성-states--properties)
   - [위젯 속성 (Widget Attributes)](#위젯-속성-widget-attributes)
   - [라이브 리전 속성 (Live Region Attributes)](#라이브-리전-속성-live-region-attributes)
   - [관계 속성 (Relationship Attributes)](#관계-속성-relationship-attributes)
   - [드래그 앤 드롭 속성 (Drag-and-Drop Attributes)](#드래그-앤-드롭-속성-drag-and-drop-attributes)

---

## ARIA 사용 규칙

이 다섯 가지 규칙은 기본 원칙입니다. 이를 위반하는 것이 ARIA 관련 접근성 문제의 가장 흔한 원인입니다.

### 규칙 1: 네이티브 HTML로 충분하면 ARIA를 사용하지 마세요

네이티브 HTML 요소에는 내장된 의미론(semantics), 키보드 동작, 포커스 관리가 있습니다. ARIA는 의미론만 추가하며, 동작은 추가하지 않습니다.

```tsx
// 나쁜 예: div에 ARIA role 사용
<div role="button" tabIndex={0} onClick={handleClick} onKeyDown={handleKeyDown}>
  Submit
</div>

// 좋은 예: 네이티브 HTML 버튼
<button onClick={handleClick}>Submit</button>
```

### 규칙 2: 반드시 필요한 경우가 아니면 네이티브 의미론을 변경하지 마세요

```tsx
// 나쁜 예: heading을 버튼으로 변경
<h2 role="button">Section Title</h2>

// 좋은 예: heading 안에 버튼 배치
<h2><button>Section Title</button></h2>
```

### 규칙 3: 모든 인터랙티브 ARIA 컨트롤은 키보드로 접근 가능해야 합니다

`role="button"`을 사용하면 요소는 포커스 가능해야 하고 `Enter`와 `Space`에 반응해야 합니다. `role="slider"`를 사용하면 화살표 키에 반응해야 합니다. ARIA는 키보드 동작을 제공하지 않으므로 직접 구현해야 합니다.

### 규칙 4: 포커스 가능한 요소에 role="presentation" 또는 aria-hidden="true"를 사용하지 마세요

```tsx
// 나쁜 예: 보조 기술에서 숨겨졌지만 여전히 포커스 가능
<button aria-hidden="true">Close</button>

// 나쁜 예: 포커스 가능한 요소에 presentation role
<button role="presentation">Close</button>

// 좋은 예: 숨겨야 한다면 탭 순서에서도 제거
<button aria-hidden="true" tabIndex={-1} style={{ display: "none" }}>Close</button>
```

### 규칙 5: 모든 인터랙티브 요소에는 접근 가능한 이름이 있어야 합니다

모든 인터랙티브 요소는 보조 기술로 식별 가능해야 합니다.

```tsx
// 나쁜 예: 접근 가능한 이름 없음
<button><svg>...</svg></button>

// 좋은 예: aria-label 사용
<button aria-label="Close dialog"><svg aria-hidden="true">...</svg></button>

// 좋은 예: 보이는 텍스트
<button><svg aria-hidden="true">...</svg> Close</button>

// 좋은 예: aria-labelledby 사용
<button aria-labelledby="close-label"><span id="close-label" className="sr-only">Close dialog</span><svg aria-hidden="true">...</svg></button>
```

---

## 랜드마크 Role (Landmark Roles)

랜드마크 role은 페이지의 대규모 영역을 식별합니다. 스크린 리더 사용자는 랜드마크 간에 직접 이동할 수 있습니다.

### banner

**목적:** 사이트 전체 헤더 콘텐츠 (로고, 사이트 제목, 글로벌 내비게이션).

**HTML 동등 요소:** `<header>` (`<article>`, `<aside>`, `<main>`, `<nav>`, `<section>` 안에 중첩되지 않은 경우)

**유효한 값:** 해당 없음 (불리언 role)

**사용법:**

```tsx
// 권장: 시맨틱 HTML 사용
<header>
  <h1>My Site</h1>
  <nav>...</nav>
</header>

// ARIA 동등 표현 (<header>를 사용할 수 없는 경우에만)
<div role="banner">
  <h1>My Site</h1>
</div>
```

**흔한 실수:**
- 페이지당 두 개 이상의 `banner` 랜드마크를 사용하는 경우.
- `<article>` 안에 `<header>`를 중첩하고 `banner`가 될 것으로 기대하는 경우 (되지 않음).

---

### navigation

**목적:** 내비게이션 링크의 모음.

**HTML 동등 요소:** `<nav>`

**사용법:**

```tsx
// 여러 nav 랜드마크는 구별되는 레이블이 필요
<nav aria-label="Main navigation">
  <ul>...</ul>
</nav>

<nav aria-label="Footer navigation">
  <ul>...</ul>
</nav>
```

**흔한 실수:**
- 여러 `<nav>` 요소에 구별되는 `aria-label` 값이 없는 경우.
- 내비게이션이 아닌 콘텐츠에 `<nav>`를 사용하는 경우 (예: 태그 목록).

---

### main

**목적:** 페이지의 주요 콘텐츠.

**HTML 동등 요소:** `<main>`

**사용법:**

```tsx
<main id="main-content" tabIndex={-1}>
  {/* tabIndex={-1}은 건너뛰기 링크를 위한 프로그래밍적 포커스를 허용 */}
  {children}
</main>
```

**흔한 실수:**
- 한 번에 두 개 이상의 `<main>` 요소가 보이는 경우.
- 건너뛰기 링크 타겟을 위한 `id`를 포함하지 않는 경우.

---

### complementary

**목적:** 주요 콘텐츠를 보충하는 콘텐츠 (사이드바, 관련 링크).

**HTML 동등 요소:** `<aside>`

**사용법:**

```tsx
<aside aria-label="Related articles">
  <h2>Related Articles</h2>
  <ul>...</ul>
</aside>
```

**흔한 실수:**
- 주요 콘텐츠와 보완적이지 않은 콘텐츠에 `<aside>`를 사용하는 경우.
- 레이블 없이 `<aside>`를 깊이 중첩하는 경우.

---

### contentinfo

**목적:** 푸터 정보 (저작권, 법적 링크, 연락처 정보).

**HTML 동등 요소:** `<footer>` (`<article>`, `<aside>`, `<main>`, `<nav>`, `<section>` 안에 중첩되지 않은 경우)

**사용법:**

```tsx
<footer>
  <p>&copy; 2025 My Company</p>
  <nav aria-label="Footer links">...</nav>
</footer>
```

**흔한 실수:**
- 페이지당 두 개 이상의 `contentinfo` 랜드마크를 사용하는 경우.
- 섹션 안에서 `<footer>`를 사용하고 `contentinfo` 랜드마크가 될 것으로 기대하는 경우.

---

### search

**목적:** 검색 기능이 포함된 영역.

**HTML 동등 요소:** `<search>` (HTML5.2+)

**사용법:**

```tsx
// 최신 HTML
<search>
  <form role="search">
    <label htmlFor="site-search">Search</label>
    <input id="site-search" type="search" />
    <button type="submit">Search</button>
  </form>
</search>

// 폴백
<form role="search" aria-label="Site search">
  <label htmlFor="site-search">Search</label>
  <input id="site-search" type="search" />
  <button type="submit">Search</button>
</form>
```

**흔한 실수:**
- 여러 검색 영역이 있을 때 검색 폼에 레이블을 제공하지 않는 경우.
- 폼 컨테이너 대신 input에 `role="search"`를 사용하는 경우.

---

### form

**목적:** 접근 가능한 이름이 있는 폼을 포함하는 영역.

**HTML 동등 요소:** `<form>` (`aria-label` 또는 `aria-labelledby`가 있는 경우)

**사용법:**

```tsx
<form aria-labelledby="form-title">
  <h2 id="form-title">Contact Us</h2>
  <label htmlFor="name">Name</label>
  <input id="name" type="text" />
</form>
```

**흔한 실수:**
- 접근 가능한 이름이 없는 `<form>`은 랜드마크로 노출되지 않음.
- `<form>` 요소에 중복으로 `role="form"`을 사용하는 경우.

---

### region

**목적:** 사용자가 내비게이션할 수 있을 만큼 중요한 콘텐츠 섹션을 위한 범용 랜드마크.

**HTML 동등 요소:** `<section>` (접근 가능한 이름이 있는 경우)

**사용법:**

```tsx
<section aria-labelledby="section-title">
  <h2 id="section-title">Latest News</h2>
  <ul>...</ul>
</section>
```

**흔한 실수:**
- `aria-label` 또는 `aria-labelledby`가 없는 `<section>`은 랜드마크가 아님.
- `region` 랜드마크를 과도하게 사용하는 경우 -- 정말 중요한 페이지 섹션에만 사용해야 함.

---

## 위젯 Role (Widget Roles)

위젯 role은 인터랙티브 UI 컴포넌트를 식별합니다. 이러한 role을 사용할 때는 기대되는 키보드 동작을 직접 구현해야 합니다.

### button

**목적:** 동작을 실행하는 클릭 가능한 요소.

**HTML 동등 요소:** `<button>`

**기대되는 키보드 동작:** `Enter`와 `Space`로 활성화.

```tsx
// <button>을 사용할 수 없는 경우에만 role="button" 사용
<span role="button" tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      handleClick();
    }
  }}
>
  Action
</span>
```

---

### checkbox

**목적:** 이중 상태(또는 삼중 상태)의 체크 가능한 입력.

**HTML 동등 요소:** `<input type="checkbox">`

**기대되는 키보드 동작:** `Space`로 토글.

**주요 속성:** `aria-checked` ("true", "false", 또는 "mixed")

```tsx
<span
  role="checkbox"
  aria-checked={isChecked}
  tabIndex={0}
  onClick={toggle}
  onKeyDown={(e) => { if (e.key === " ") { e.preventDefault(); toggle(); } }}
>
  Accept terms
</span>
```

---

### dialog

**목적:** 페이지 위에 겹쳐지는 다이얼로그 창.

**HTML 동등 요소:** `<dialog>`

**기대되는 키보드 동작:** `Escape`로 닫기; `Tab`이 내부에 갇힘.

**주요 속성:** `aria-modal`, `aria-labelledby`

```tsx
<dialog aria-labelledby="dialog-title" aria-modal="true">
  <h2 id="dialog-title">Confirm Action</h2>
  <p>Are you sure?</p>
  <button>Confirm</button>
  <button>Cancel</button>
</dialog>
```

---

### link

**목적:** 내비게이션 하이퍼링크.

**HTML 동등 요소:** `<a href="...">`

**기대되는 키보드 동작:** `Enter`로 활성화.

```tsx
// <a>를 사용할 수 없는 경우에만 사용
<span role="link" tabIndex={0} onClick={() => router.push("/page")}>
  Go to page
</span>
```

---

### menuitem

**목적:** 메뉴(드롭다운 또는 컨텍스트 메뉴)의 항목.

**기대되는 키보드 동작:** `Enter`로 활성화; `ArrowUp`/`ArrowDown`으로 내비게이션.

**관련 role:** `menu`, `menubar`, `menuitemcheckbox`, `menuitemradio`

```tsx
<ul role="menu">
  <li role="menuitem" tabIndex={-1}>Cut</li>
  <li role="menuitem" tabIndex={-1}>Copy</li>
  <li role="menuitem" tabIndex={-1}>Paste</li>
</ul>
```

---

### option

**목적:** listbox 내의 선택 가능한 항목.

**기대되는 키보드 동작:** `ArrowUp`/`ArrowDown`으로 내비게이션; `Enter`로 선택.

**주요 속성:** `aria-selected`

**관련 role:** `listbox`

```tsx
<ul role="listbox" aria-label="Choose a color">
  <li role="option" aria-selected={selected === "red"}>Red</li>
  <li role="option" aria-selected={selected === "blue"}>Blue</li>
  <li role="option" aria-selected={selected === "green"}>Green</li>
</ul>
```

---

### radio

**목적:** 라디오 그룹 내의 선택 가능한 항목 (하나만 선택 가능).

**HTML 동등 요소:** `<input type="radio">`

**기대되는 키보드 동작:** `ArrowUp`/`ArrowDown` 또는 `ArrowLeft`/`ArrowRight`로 내비게이션; 선택이 포커스를 따름.

**주요 속성:** `aria-checked`

**관련 role:** `radiogroup`

```tsx
<div role="radiogroup" aria-label="Delivery method">
  <span role="radio" aria-checked={method === "standard"} tabIndex={method === "standard" ? 0 : -1}>Standard</span>
  <span role="radio" aria-checked={method === "express"} tabIndex={method === "express" ? 0 : -1}>Express</span>
</div>
```

---

### slider

**목적:** 사용자가 범위에서 값을 선택할 수 있는 입력.

**HTML 동등 요소:** `<input type="range">`

**기대되는 키보드 동작:** `ArrowLeft`/`ArrowDown`으로 감소; `ArrowRight`/`ArrowUp`으로 증가; `Home`/`End`로 최소/최대.

**주요 속성:** `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-valuetext`

```tsx
<div
  role="slider"
  aria-valuenow={volume}
  aria-valuemin={0}
  aria-valuemax={100}
  aria-valuetext={`${volume}%`}
  aria-label="Volume"
  tabIndex={0}
>
  <div style={{ width: `${volume}%` }} className="slider-fill" />
</div>
```

---

### switch

**목적:** 켜짐과 꺼짐 상태 사이의 토글.

**기대되는 키보드 동작:** `Space` 또는 `Enter`로 토글.

**주요 속성:** `aria-checked` ("true" 또는 "false")

```tsx
<button
  role="switch"
  aria-checked={isDarkMode}
  onClick={toggleDarkMode}
>
  Dark mode
</button>
```

---

### tab

**목적:** tablist 내의 탭.

**기대되는 키보드 동작:** `ArrowLeft`/`ArrowRight`로 내비게이션; `Home`/`End`로 처음/마지막.

**주요 속성:** `aria-selected`, `aria-controls`

**관련 role:** `tablist`, `tabpanel`

전체 예제는 [patterns.md의 Tabs 패턴](./patterns.md#tabs)을 참조하세요.

---

### textbox

**목적:** 텍스트 입력 필드.

**HTML 동등 요소:** `<input type="text">`, `<textarea>`

**주요 속성:** `aria-multiline`, `aria-placeholder`, `aria-required`, `aria-invalid`

```tsx
// 네이티브 요소를 권장
<textarea aria-label="Comments" />

// ARIA textbox (네이티브 요소를 사용할 수 없는 경우에만)
<div role="textbox" aria-multiline="true" contentEditable="true" aria-label="Comments" tabIndex={0} />
```

---

### tooltip

**목적:** 요소에 대한 설명 텍스트를 표시하는 팝업.

**주요 속성:** 트리거에 `aria-describedby`를 사용.

전체 예제는 [patterns.md의 Tooltip 패턴](./patterns.md#tooltip)을 참조하세요.

---

### combobox

**목적:** 텍스트 입력과 팝업 listbox를 결합한 복합 위젯.

**주요 속성:** `aria-expanded`, `aria-controls`, `aria-autocomplete`, `aria-activedescendant`

**관련 role:** `listbox`, `option`

전체 예제는 [patterns.md의 Combobox 패턴](./patterns.md#combobox--autocomplete)을 참조하세요.

---

### alertdialog

**목적:** 중요한 메시지와 함께 즉각적인 주의가 필요한 다이얼로그.

**기대되는 키보드 동작:** `dialog`와 동일 -- `Escape`로 닫기, 포커스 갇힘.

**주요 속성:** `aria-labelledby`, `aria-describedby`, `aria-modal`

```tsx
<div role="alertdialog" aria-modal="true" aria-labelledby="alert-title" aria-describedby="alert-desc">
  <h2 id="alert-title">Delete Account</h2>
  <p id="alert-desc">This action cannot be undone. All data will be permanently deleted.</p>
  <button>Cancel</button>
  <button>Delete</button>
</div>
```

---

### progressbar

**목적:** 장시간 실행 작업의 진행 상태를 표시함.

**HTML 동등 요소:** `<progress>`

**주요 속성:** `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-valuetext`

```tsx
// 확정적 (Determinate)
<div role="progressbar" aria-valuenow={75} aria-valuemin={0} aria-valuemax={100} aria-label="Upload progress">
  <div style={{ width: "75%" }} />
</div>

// 불확정적 (Indeterminate, aria-valuenow 없음)
<div role="progressbar" aria-label="Loading content">
  <div className="spinner" />
</div>
```

---

### separator (포커스 가능)

**목적:** 섹션 크기를 조절하는 데 사용할 수 있는 포커스 가능한 구분선 (스플리터).

**기대되는 키보드 동작:** `ArrowLeft`/`ArrowRight` 또는 `ArrowUp`/`ArrowDown`으로 크기 조절.

**주요 속성:** `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-orientation`

```tsx
<div
  role="separator"
  aria-valuenow={50}
  aria-valuemin={0}
  aria-valuemax={100}
  aria-orientation="vertical"
  aria-label="Resize panels"
  tabIndex={0}
/>
```

---

### tree / treeitem

**목적:** 계층적 목록 (파일 탐색기, 중첩 메뉴).

**기대되는 키보드 동작:** `ArrowUp`/`ArrowDown`으로 내비게이션; `ArrowRight`로 확장; `ArrowLeft`로 축소.

**주요 속성:** `aria-expanded` (확장 가능한 treeitem에서)

**관련 role:** `tree`, `treeitem`, `group`

```tsx
<ul role="tree" aria-label="File explorer">
  <li role="treeitem" aria-expanded={true}>
    src
    <ul role="group">
      <li role="treeitem">index.ts</li>
      <li role="treeitem">utils.ts</li>
    </ul>
  </li>
  <li role="treeitem" aria-expanded={false}>
    public
  </li>
</ul>
```

---

## 문서 구조 Role (Document Structure Roles)

이 role은 문서 콘텐츠의 구조를 설명합니다.

### article

**목적:** 독립적인 구성물 (블로그 포스트, 뉴스 기사, 댓글, 포럼 글).

**HTML 동등 요소:** `<article>`

```tsx
<article aria-labelledby="post-title">
  <h2 id="post-title">Blog Post Title</h2>
  <p>Content...</p>
</article>
```

---

### heading

**목적:** 페이지 섹션의 heading.

**HTML 동등 요소:** `<h1>`부터 `<h6>`

**주요 속성:** `aria-level` (1-6)

```tsx
// 시맨틱 HTML 권장
<h1>Page Title</h1>
<h2>Section Title</h2>

// ARIA heading (필요한 경우에만)
<div role="heading" aria-level={2}>Section Title</div>
```

---

### list / listitem

**목적:** 항목의 그룹.

**HTML 동등 요소:** `<ul>`/`<ol>` 및 `<li>`

```tsx
// 시맨틱 HTML 권장
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
</ul>

// ARIA 동등 표현 (필요한 경우에만)
<div role="list">
  <div role="listitem">Item 1</div>
  <div role="listitem">Item 2</div>
</div>
```

**흔한 실수:** 일부 CSS 리셋(예: Safari에서 `list-style: none`)은 목록 의미론을 제거합니다. 이를 복원하려면 `role="list"`를 추가하세요.

---

### table / row / cell / rowheader / columnheader

**목적:** 행과 열로 구성된 데이터.

**HTML 동등 요소:** `<table>`, `<tr>`, `<td>`, `<th>`

```tsx
// 시맨틱 HTML 권장
<table>
  <caption>Quarterly Revenue</caption>
  <thead>
    <tr>
      <th scope="col">Quarter</th>
      <th scope="col">Revenue</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Q1</th>
      <td>$1.2M</td>
    </tr>
  </tbody>
</table>
```

---

### img

**목적:** 이미지 콘텐츠의 컨테이너 (SVG 또는 이미지 그룹에 유용).

**주요 속성:** `aria-label` 또는 `aria-labelledby`

```tsx
<svg role="img" aria-label="Company logo">
  <title>Company Logo</title>
  {/* SVG paths */}
</svg>
```

---

### figure

**목적:** 선택적 캡션이 있는 콘텐츠, 일반적으로 이미지, 코드 스니펫 또는 다이어그램.

**HTML 동등 요소:** `<figure>` 및 `<figcaption>`

```tsx
<figure>
  <Image src="/chart.png" alt="Sales trend showing 25% growth" width={600} height={400} />
  <figcaption>Figure 1: Quarterly sales trend</figcaption>
</figure>
```

---

### group

**목적:** 페이지 요약의 일부가 되지 않는 UI 객체의 집합 (복합 위젯 내부에서 사용).

```tsx
<div role="radiogroup" aria-label="Size">
  <div role="group" aria-label="Standard sizes">
    <span role="radio" aria-checked="false">Small</span>
    <span role="radio" aria-checked="true">Medium</span>
    <span role="radio" aria-checked="false">Large</span>
  </div>
</div>
```

---

### presentation / none

**목적:** 요소의 암묵적 ARIA 의미론을 제거합니다. 레이아웃 테이블이나 장식용 컨테이너에 주로 사용됩니다.

```tsx
// 레이아웃 테이블 (데이터 테이블이 아님)
<table role="presentation">
  <tr>
    <td>Left column</td>
    <td>Right column</td>
  </tr>
</table>
```

**흔한 실수:** 포커스 가능하거나 인터랙티브한 요소에는 절대 사용하지 마세요.

---

## ARIA 상태 및 속성 (States & Properties)

### 위젯 속성 (Widget Attributes)

#### aria-expanded

**목적:** 접을 수 있는 요소가 현재 확장되었는지 접혀있는지를 나타냅니다.

**유효한 값:** `"true"`, `"false"`

**사용 대상:** 확장 가능한 콘텐츠를 제어하는 버튼 (아코디언, 드롭다운, 트리 아이템).

```tsx
<button aria-expanded={isOpen} aria-controls="panel-1">
  Section Title
</button>
<div id="panel-1" hidden={!isOpen}>
  Panel content
</div>
```

**흔한 실수:**
- `"true"`와 `"false"` 사이를 토글하지 않는 경우 (정적으로 방치).
- 트리거 버튼 대신 콘텐츠 패널에 `aria-expanded`를 추가하는 경우.

---

#### aria-selected

**목적:** 선택 가능한 항목 목록에서 현재 선택 상태를 나타냅니다.

**유효한 값:** `"true"`, `"false"`

**사용 대상:** `option`, `tab`, `row`, `gridcell`

```tsx
<button role="tab" aria-selected={activeTab === 0}>
  Tab 1
</button>
```

**흔한 실수:**
- 지원하지 않는 요소에 `aria-selected`를 사용하는 경우 (예: `menuitem`).
- 선택되지 않은 항목에 `aria-selected="false"`를 설정하지 않는 경우 (`option`과 `tab`의 경우 완전히 생략하는 것도 유효함).

---

#### aria-checked

**목적:** 체크박스, 라디오 버튼, 스위치의 체크 상태를 나타냅니다.

**유효한 값:** `"true"`, `"false"`, `"mixed"` (삼중 상태 체크박스용)

**사용 대상:** `checkbox`, `radio`, `switch`, `menuitemcheckbox`, `menuitemradio`

```tsx
<button role="switch" aria-checked={isEnabled}>
  Notifications
</button>
```

**흔한 실수:**
- 탭이나 옵션에 `aria-selected` 대신 `aria-checked`를 사용하는 경우.
- "전체 선택" 체크박스에 `"mixed"` 상태를 구현하지 않는 경우.

---

#### aria-disabled

**목적:** 요소가 인식 가능하지만 조작 불가능함을 나타냅니다.

**유효한 값:** `"true"`, `"false"`

**사용 대상:** 모든 인터랙티브 요소.

```tsx
// aria-disabled는 요소를 접근성 트리와 포커스 가능 상태로 유지
<button aria-disabled={!isValid} onClick={isValid ? handleSubmit : undefined}>
  Submit
</button>
```

**흔한 실수:**
- HTML `disabled` 속성과 혼동하는 경우. `disabled`는 요소를 탭 순서에서 제거하고 비활성화 스타일을 적용합니다. `aria-disabled`는 포커스 가능 상태를 유지하므로 발견 가능성이 더 좋지만, 동작을 직접 방지해야 합니다.
- `aria-disabled="true"`일 때 동작을 방지하지 않는 경우 (ARIA는 동작을 변경하지 않음).

---

#### aria-hidden

**목적:** 시각적으로는 보이지만 보조 기술에서 요소를 숨깁니다.

**유효한 값:** `"true"`, `"false"`

**사용 대상:** 장식용 요소, 텍스트 레이블이 있는 아이콘, 중복 콘텐츠.

```tsx
// 보이는 레이블이 있는 아이콘
<button>
  <svg aria-hidden="true">...</svg>
  Close
</button>

// 장식용 구분선
<hr aria-hidden="true" />
```

**흔한 실수:**
- 포커스 가능한 요소에 `aria-hidden="true"`를 사용하는 경우 (요소가 여전히 포커스를 받을 수 있지만 음성으로 전달되지 않음).
- 포커스 가능한 자식이 있는 부모에 `aria-hidden="true"`를 사용하는 경우 (일부 스크린 리더에서 해당 자식이 포커스 불가능해짐).
- `aria-hidden="true"` 조상 안의 콘텐츠를 "숨김 해제"하기 위해 `aria-hidden="false"`를 사용하는 경우 (작동하지 않음).

---

#### aria-pressed

**목적:** 토글 버튼의 눌림 상태를 나타냅니다.

**유효한 값:** `"true"`, `"false"`, `"mixed"`

**사용 대상:** 눌림과 안 눌림 상태 사이를 토글하는 버튼.

```tsx
<button aria-pressed={isBold} onClick={toggleBold}>
  Bold
</button>
```

**흔한 실수:**
- `aria-pressed`와 `aria-checked`를 혼동하는 경우. 토글 버튼에는 `aria-pressed`를, 체크박스, 스위치, 라디오 버튼에는 `aria-checked`를 사용하세요.
- 버튼이 아닌 요소에 `aria-pressed`를 사용하는 경우.

---

#### aria-required

**목적:** 제출 전에 사용자 입력이 필요함을 나타냅니다.

**유효한 값:** `"true"`, `"false"`

**사용 대상:** 폼 입력, combobox, textbox.

```tsx
<label htmlFor="email">Email (required)</label>
<input id="email" type="email" aria-required="true" required />
```

**흔한 실수:**
- 필드가 필수임을 나타내는 시각적 표시 없이 `aria-required`를 사용하는 경우.
- 프로그래밍적 표시 없이 별표(*)에만 의존하는 경우.

---

#### aria-invalid

**목적:** 입력된 값이 기대 형식에 맞지 않음을 나타냅니다.

**유효한 값:** `"true"`, `"false"`, `"grammar"`, `"spelling"`

**사용 대상:** 유효성 검증 후의 폼 입력.

```tsx
<input
  id="email"
  type="email"
  aria-invalid={hasError}
  aria-describedby={hasError ? "email-error" : undefined}
/>
{hasError && <span id="email-error" role="alert">Please enter a valid email address.</span>}
```

**흔한 실수:**
- 사용자가 필드와 상호작용하기 전에 `aria-invalid="true"`를 설정하는 경우 (blur 또는 submit 시에 검증).
- `aria-describedby`를 통해 연관된 오류 메시지를 제공하지 않는 경우.

---

#### aria-sort

**목적:** 테이블 열 또는 행의 정렬 방향을 나타냅니다.

**유효한 값:** `"ascending"`, `"descending"`, `"none"`, `"other"`

**사용 대상:** 정렬 가능한 테이블의 `<th>` 요소.

```tsx
<th scope="col" aria-sort={sortCol === "name" ? sortDir : undefined}>
  <button onClick={() => sortBy("name")}>Name</button>
</th>
```

**흔한 실수:**
- 현재 정렬된 열뿐만 아니라 모든 열에 `aria-sort`를 설정하는 경우.
- 정렬 가능하지만 현재 정렬되지 않은 열에 `"none"`을 제공하지 않는 경우 (`aria-sort`를 완전히 생략하는 것도 허용됨).

---

#### aria-valuenow / aria-valuemin / aria-valuemax / aria-valuetext

**목적:** 범위 위젯의 현재 값과 범위를 정의합니다.

**사용 대상:** `slider`, `progressbar`, `scrollbar`, `separator` (포커스 가능한 경우), `spinbutton`

```tsx
<div
  role="slider"
  aria-valuenow={50}
  aria-valuemin={0}
  aria-valuemax={100}
  aria-valuetext="50 percent"
  aria-label="Volume"
  tabIndex={0}
/>
```

**흔한 실수:**
- 숫자 값이 의미가 없을 때 `aria-valuetext`를 생략하는 경우 (예: "낮음/중간/높음" 슬라이더는 `aria-valuetext`를 사용해야 함).
- 최소/최대 범위 밖의 `aria-valuenow`를 설정하는 경우.

---

#### aria-current

**목적:** 집합 또는 컨텍스트 내에서 현재 항목을 나타냅니다.

**유효한 값:** `"page"`, `"step"`, `"location"`, `"date"`, `"time"`, `"true"`, `"false"`

**사용 대상:** 내비게이션의 링크, 마법사의 단계, 캘린더의 날짜.

```tsx
// 내비게이션의 현재 페이지
<Link href="/about" aria-current={pathname === "/about" ? "page" : undefined}>
  About
</Link>

// 마법사의 현재 단계
<li aria-current={currentStep === 2 ? "step" : undefined}>
  Step 2: Payment
</li>
```

**흔한 실수:**
- 내비게이션 항목에 `aria-current` 대신 `aria-selected`를 사용하는 경우 (`aria-current="page"` 사용).
- 항목이 더 이상 현재가 아닐 때 `aria-current`를 제거하지 않는 경우.

---

#### aria-busy

**목적:** 요소가 수정 중이며 보조 기술이 변경 사항을 알리기 전에 기다려야 함을 나타냅니다.

**유효한 값:** `"true"`, `"false"`

**사용 대상:** 콘텐츠가 로딩 또는 업데이트 중인 컨테이너.

```tsx
<div role="feed" aria-busy={isLoading}>
  {isLoading ? <Skeleton /> : <ArticleList articles={articles} />}
</div>
```

**흔한 실수:**
- 로딩이 완료되었을 때 `aria-busy="false"`를 설정하지 않는 경우 (일부 스크린 리더가 이를 기다림).
- 컨테이너 대신 개별 항목에 `aria-busy`를 사용하는 경우.

---

### 라이브 리전 속성 (Live Region Attributes)

#### aria-live

**목적:** 영역이 동적으로 업데이트될 것임을 나타내고, 알림의 우선순위를 정의합니다.

**유효한 값:** `"off"`, `"polite"`, `"assertive"`

| 값 | 사용 시기 |
|-------|-------------|
| `"off"` | 기본값. 업데이트가 알려지지 않음. |
| `"polite"` | 사용자가 유휴 상태일 때 업데이트를 알림. 비긴급 메시지(상태, 결과 수)에 사용. |
| `"assertive"` | 현재 음성을 중단하고 즉시 업데이트를 알림. 긴급 메시지(오류, 알림)에 사용. |

```tsx
// polite: 검색 결과 수
<div aria-live="polite">
  {count} results found
</div>

// assertive: 오류 메시지
<div aria-live="assertive">
  {error && <p>Error: {error}</p>}
</div>
```

**흔한 실수:**
- 콘텐츠와 동시에 `aria-live`를 요소에 추가하는 경우 (영역이 먼저 DOM에 존재해야 하고, 그 후에 콘텐츠를 주입해야 함).
- 비긴급 업데이트에 `"assertive"`를 사용하는 경우 (사용자를 방해함).
- 많은 자식이 있는 컨테이너에 `aria-live`를 추가하는 경우 (과도한 알림 발생).

---

#### aria-atomic

**목적:** 보조 기술이 라이브 리전 내의 전체 또는 변경된 노드만 표시할지를 나타냅니다.

**유효한 값:** `"true"`, `"false"`

```tsx
// 일부가 변경되면 전체 영역을 알림
<div aria-live="polite" aria-atomic="true">
  Showing {start}-{end} of {total} results
</div>

// 변경된 부분만 알림
<div aria-live="polite" aria-atomic="false">
  <span>Message 1</span>
  <span>Message 2</span>  {/* 이 새로운 span만 알려짐 */}
</div>
```

**흔한 실수:**
- 채팅 로그에 `aria-atomic="true"`를 사용하는 경우 (매 메시지마다 전체 로그를 다시 읽게 됨).
- `aria-live` 없이 `aria-atomic`을 설정하는 경우 (라이브 리전 없이는 효과 없음).

---

#### aria-relevant

**목적:** 라이브 리전에서 어떤 유형의 변경을 알릴지를 지정합니다.

**유효한 값:** `"additions"`, `"removals"`, `"text"`, `"all"` (또는 공백으로 구분된 조합)

**기본값:** `"additions text"`

```tsx
// 항목이 추가되거나 제거될 때 알림
<ul aria-live="polite" aria-relevant="additions removals">
  {notifications.map((n) => <li key={n.id}>{n.text}</li>)}
</ul>
```

**흔한 실수:**
- 추가만 필요할 때 `aria-relevant="all"`을 사용하는 경우 (과도한 알림 발생).
- `aria-live` 없이 `aria-relevant`를 사용하는 경우.

---

### 관계 속성 (Relationship Attributes)

#### aria-label

**목적:** 요소에 접근 가능한 이름을 제공합니다 (보이는 텍스트를 대체).

**유효한 값:** 모든 문자열.

**사용 대상:** 보이는 텍스트 레이블이 없는 요소, 또는 보이는 텍스트가 충분하지 않은 경우.

```tsx
<button aria-label="Close dialog">
  <XIcon aria-hidden="true" />
</button>

<nav aria-label="Main navigation">
  <ul>...</ul>
</nav>
```

**흔한 실수:**
- 보이는 텍스트가 있을 때 `aria-label`을 사용하는 경우 (보이는 텍스트를 덮어쓰므로 음성 입력 사용자에게 불일치가 발생).
- 중복 레이블링: `<button>Search</button>`에 `aria-label="Search button"` -- 이름이 이미 "Search"임.
- 무시될 수 있는 비인터랙티브, 비랜드마크 요소에 `aria-label`을 사용하는 경우.

---

#### aria-labelledby

**목적:** 현재 요소에 레이블을 제공하는 요소를 식별합니다 (ID로 참조).

**유효한 값:** 공백으로 구분된 ID 목록.

```tsx
<h2 id="billing-heading">Billing Address</h2>
<form aria-labelledby="billing-heading">
  ...
</form>

{/* 여러 레이블 */}
<span id="row-name">John Smith</span>
<button aria-labelledby="row-name delete-label">
  <span id="delete-label">Delete</span>
</button>
{/* "John Smith Delete"로 알려짐 */}
```

**흔한 실수:**
- DOM에 존재하지 않는 ID를 참조하는 경우.
- 근처에 보이는 레이블이 이미 있을 때 `aria-labelledby`를 사용하는 경우 (폼 필드에는 `<label>`의 `htmlFor`를 대신 사용).

---

#### aria-describedby

**목적:** 현재 요소를 설명하는 요소를 식별합니다 (보충 정보).

**유효한 값:** 공백으로 구분된 ID 목록.

```tsx
<label htmlFor="password">Password</label>
<input
  id="password"
  type="password"
  aria-describedby="password-requirements"
/>
<p id="password-requirements">
  Must be at least 8 characters with one uppercase letter and one number.
</p>
```

**흔한 실수:**
- `aria-labelledby`와 혼동하는 경우. `aria-labelledby`는 접근 가능한 이름(기본 레이블)을 제공하고, `aria-describedby`는 보충 설명을 제공합니다.
- 오류 메시지에 `aria-describedby`를 사용하지 않는 경우 (스크린 리더는 레이블 후에 설명을 알림).

---

#### aria-controls

**목적:** 현재 요소가 제어하는 요소를 식별합니다.

**유효한 값:** 공백으로 구분된 ID 목록.

```tsx
<button aria-controls="settings-panel" aria-expanded={isOpen}>
  Settings
</button>
<div id="settings-panel" hidden={!isOpen}>
  Settings content
</div>
```

**흔한 실수:**
- DOM에 아직 존재하지 않는 요소를 참조하는 경우 (제어되는 요소는 숨겨져 있더라도 존재해야 함).
- 참고: 스크린 리더 간 `aria-controls` 지원이 일관적이지 않습니다. 주로 JAWS 사용자에게 유용합니다. 관계를 전달하는 유일한 방법으로 의존하지 마세요.

---

#### aria-owns

**목적:** 시각적/컨텍스트적으로는 자식이지만 DOM 자식이 아닌 요소를 식별합니다 (접근성 트리를 위한 부모 재지정).

**유효한 값:** 공백으로 구분된 ID 목록.

```tsx
{/* 메뉴가 포털로 렌더링되는 메뉴 버튼 */}
<button aria-owns="context-menu" aria-haspopup="true">
  Options
</button>

{/* 포털을 통해 DOM의 다른 곳에 렌더링됨 */}
<ul id="context-menu" role="menu">
  <li role="menuitem">Edit</li>
  <li role="menuitem">Delete</li>
</ul>
```

**흔한 실수:**
- DOM 구조를 수정할 수 있는데 `aria-owns`를 사용하는 경우 (ARIA 부모 재지정보다 DOM 순서를 수정하는 것이 좋음).
- 순환적이거나 충돌하는 소유권 (요소는 하나의 `aria-owns` 부모만 가질 수 있음).

---

#### aria-activedescendant

**목적:** DOM 포커스를 컨테이너에 유지하면서 복합 위젯 내에서 현재 활성 요소를 식별합니다.

**유효한 값:** 활성 자손 요소의 ID.

**사용 대상:** `combobox`, `listbox`, `grid`, `tree`, `tablist`

```tsx
<input
  role="combobox"
  aria-activedescendant={activeOptionId}
  aria-expanded={isOpen}
  aria-controls="listbox"
/>
<ul id="listbox" role="listbox">
  <li id="option-1" role="option" aria-selected={activeOptionId === "option-1"}>
    Option 1
  </li>
  <li id="option-2" role="option" aria-selected={activeOptionId === "option-2"}>
    Option 2
  </li>
</ul>
```

**흔한 실수:**
- `aria-activedescendant`를 사용하는 대신 DOM 포커스를 자손으로 이동하는 경우 (포커스는 복합 위젯 컨테이너에 유지되어야 함).
- 사용자가 옵션을 탐색할 때 값을 업데이트하지 않는 경우.
- 위젯이 소유한 요소 밖의 요소 ID를 참조하는 경우.

---

#### aria-errormessage

**목적:** 현재 요소에 대한 오류 메시지를 제공하는 요소를 식별합니다. 오류 상태에 대해 `aria-describedby`보다 더 구체적입니다.

**유효한 값:** 오류 메시지 요소의 ID.

```tsx
<input
  id="email"
  type="email"
  aria-invalid={hasError}
  aria-errormessage={hasError ? "email-error" : undefined}
/>
{hasError && (
  <span id="email-error" role="alert">
    Please enter a valid email address.
  </span>
)}
```

**흔한 실수:**
- `aria-invalid="true"` 설정 없이 `aria-errormessage`를 사용하는 경우 (입력이 invalid일 때만 오류 메시지가 노출됨).
- 참고: `aria-errormessage`에 대한 브라우저 및 스크린 리더 지원은 아직 확대 중입니다. 필요한 경우 `aria-describedby`를 폴백으로 사용하세요.

---

### 드래그 앤 드롭 속성 (Drag-and-Drop Attributes)

#### aria-grabbed (더 이상 사용되지 않음)

**목적:** 드래그 앤 드롭 작업에서 요소가 잡힌 상태인지를 나타내는 데 사용되었습니다. ARIA 1.1에서 더 이상 사용되지 않습니다.

**대체 방법:** `aria-roledescription`과 라이브 리전을 사용하여 드래그 상태를 설명합니다.

```tsx
// 현대적 접근 방식
<div
  role="listitem"
  aria-roledescription="draggable item"
  aria-label={`${item.name}, position ${index + 1} of ${total}`}
  tabIndex={0}
>
  {item.name}
</div>

<div aria-live="assertive">
  {dragStatus && <p>{dragStatus}</p>}
</div>
```

---

#### aria-dropeffect (더 이상 사용되지 않음)

**목적:** 객체가 대상에 드롭될 때 무슨 일이 일어나는지 설명하는 데 사용되었습니다. ARIA 1.1에서 더 이상 사용되지 않습니다.

**대체 방법:** 라이브 리전을 사용하여 드롭 결과와 사용 가능한 동작을 알립니다.

---

## 빠른 참고: 어떤 속성을 사용할까?

| 필요한 기능 | 속성 |
|------|-----------|
| 요소에 이름 지정 (보이는 텍스트 없음) | `aria-label` |
| 요소에 이름 지정 (보이는 텍스트가 다른 곳에 존재) | `aria-labelledby` |
| 보충 설명 추가 | `aria-describedby` |
| 입력에 오류 메시지 표시 | `aria-errormessage` + `aria-invalid` |
| 열림/닫힘 상태 표시 | `aria-expanded` |
| 켜짐/꺼짐 상태 표시 (토글 버튼) | `aria-pressed` |
| 켜짐/꺼짐 상태 표시 (체크박스/스위치) | `aria-checked` |
| 선택된 항목 표시 (탭, 옵션) | `aria-selected` |
| 현재 페이지/단계 표시 | `aria-current` |
| 정중하게 동적 변경 알림 | `aria-live="polite"` |
| 긴급하게 즉시 변경 알림 | `aria-live="assertive"` 또는 `role="alert"` |
| 장식 콘텐츠를 보조 기술에서 숨기기 | `aria-hidden="true"` |
| 입력을 필수로 표시 | `aria-required="true"` |
| 입력을 잘못됨으로 표시 | `aria-invalid="true"` |
| 로딩 상태 표시 | `aria-busy="true"` |
| 포커스를 이동하지 않고 활성 옵션 추적 | `aria-activedescendant` |
| 버튼을 제어하는 패널에 연결 | `aria-controls` |
| 정렬 방향 표시 | `aria-sort` |
| 범위 위젯의 값 제공 | `aria-valuenow` / `aria-valuemin` / `aria-valuemax` |
