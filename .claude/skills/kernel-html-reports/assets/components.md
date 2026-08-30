# 컴포넌트 레퍼런스

`template.html`의 CSS로 렌더링되는 보고서 컴포넌트 모음.
문서 = 표지(`.rhead`) + 요약(`.summary`) + 장(`<section class="sec">`) 여러 개 + `.foot`.

## 공통 규칙

- **본문 폭은 790px 고정, 세로로 흐른다.** 슬라이드처럼 "넘치면 나눈다"가 아니라, **읽기 흐름이 끊기지 않게** 쓴다.
- **장(`.sec`)마다 색을 정한다.** `<section class="sec" style="--c:var(--a2); --ct:var(--a2t); --bgc:var(--a2b)">`
  - `--c` 고스트 번호·규칙선·불릿, `--ct` 라벨 글자, `--bgc` 고스트 번호 채움·톤 콜아웃 배경.
  - 장 순서대로 `a1 → a2 → a3` 순환. 리스크·경고 장은 `risk`.
  - 장 **안**의 카드/지표 여러 개는 각 요소에 `style="--c:…; --ct:…"`로 다시 a1 → a2 → a3 순환.
- **장 머리에는 `data-n`을 준다.** `<div class="sech" data-n="01">` — 왼쪽 여백의 큰 고스트 번호가 여기서 나온다. 빠뜨리면 그 장만 번호 없이 뜬다.
- **한 요소의 색은 한 곳에서만 드러낸다.** 장의 색은 고스트 번호가 지고 제목에 밑줄을 겹치지 않는다. 지표의 색은 숫자가 지고 상단 막대를 겹치지 않는다. 겹치면 화려해지는 것이 아니라 **위계가 무너진다.**
- **목차는 자동.** `<section class="sec" id="s2" data-toc="장 제목">` 의 `data-toc` 값이 좌측 목차에 뜬다. 목차 마크업을 손으로 쓰지 않는다.
- **등장 애니메이션**: 화면에 들어올 때 나타낼 요소에 `data-anim`. 같은 덩어리에서 순서를 주려면 `style="--d:1"`(0,1,2…). 대부분 `--d` 없이 `data-anim`만으로 충분하다.
- **강조**: 제목 강조는 `<span class="mark">…</span>`(표지 `h1`에만, 단색). 본문 강조는 `<b>…</b>`. 부가정보는 `class="lift"`. 코드·명령어는 `<span class="mono">/clear</span>`.
- **이모지 미사용.** 라벨은 텍스트로.
- **인쇄가 최종 형태다.** 장 하나가 A4 한 페이지에서 새로 시작하고, `tw`·`cards`·`stats`·`steps`·`kv`·`callout`·`quote`·`code`·`banner`는 **'그림 한 장'처럼 통째로** 한 페이지에 들어간다(템플릿이 처리).
  - 게다가 **앞의 소제목(`h3`)과 뒤의 주석(`.cap`)도 그 블록에 붙어 다닌다.** 즉 인쇄에서 묶이는 단위는 「소제목 + 그림 + 주석」한 덩어리다.
  - 그러므로 **그 덩어리가 A4 한 페이지를 넘으면 안 된다.** 넘으면 브라우저가 규칙을 무시하고 가장 보기 싫게 쪼갠다. 표는 12행 이하, `steps`는 6단계 이하(단계 설명 2~3줄), 카드는 한 줄에 2~3장.
  - 그래도 넘칠 양이면 소제목을 하나 더 두고 **블록을 둘로 나눈다**.
- **한글 어절은 잘리지 않는다**(`word-break:keep-all`). 다만 칸 폭보다 긴 한 덩어리(긴 영문 URL 등)는 강제로 끊긴다.

---

## 1. 표지 (rhead)

```html
<header class="rhead">
  <div class="eyebrow" data-anim style="--d:0"><span class="dot"></span><b>분석 보고서</b><span class="en">· REPORT</span></div>
  <h1 data-anim style="--d:1">보고서 제목<br><span class="mark">강조 부분</span></h1>
  <p class="sub" data-anim style="--d:2">무엇을 다루고 무엇을 주장하는지 한두 문장.</p>
  <dl class="meta" data-anim style="--d:3">
    <div><dt>작성</dt><dd>이름</dd></div>
    <div><dt>일자</dt><dd>2026-07-29</dd></div>
    <div><dt>대상</dt><dd>독자</dd></div>
  </dl>
</header>
```
- `meta` 항목은 2~4개. 없는 항목(버전·검토자 등)은 지운다.

## 2. 핵심 요약 (summary) — 표지 바로 아래 1개

```html
<section class="summary" data-anim>
  <div class="sk">EXECUTIVE SUMMARY</div>
  <h2>한 문장 결론</h2>
  <p>배경·발견·결론을 3~5문장으로.</p>
  <ul class="pts">
    <li><b>발견</b> — 근거 한 줄</li>
  </ul>
</section>
```
- 이 블록만은 본문을 다 쓴 **뒤에** 채운다(요약이 본문과 어긋나지 않게).

## 3. 장 헤더 (sech) — 모든 `.sec`의 첫 요소

```html
<section class="sec" id="s1" data-toc="장 제목"
         style="--c:var(--a1); --ct:var(--a1t); --bgc:var(--a1b)">
  <div class="sech">
    <div class="no" data-anim>01 · BACKGROUND</div>
    <h2 data-anim style="--d:1">장 제목</h2>
    <p class="lead" data-anim style="--d:2">이 장이 답하려는 질문 한 문장.</p>
  </div>
  ...본문...
</section>
```
- **`.no` → `h2` → `.lead` 세 요소는 전 장 필수.** 한 장만 `lead`가 없으면 그 장의 위계가 튄다.
- **`.sech`는 하단 헤어라인으로 본문과 끊긴다**(표지 `.rhead`와 같은 장치). 리드는 본문보다 확실히 큰 데크 문장(화면 19.5px vs 본문 16.5px)이다. 이 선·크기차·아래 여백은 **장 머리를 한 덩어리로 떼어 놓는 유일한 장치**이므로 지면을 맞추려고 줄이지 않는다(SKILL.md 원칙 9).
- **리드는 한 문장.** 두세 문장을 넣으면 데크가 아니라 문단이 되어, 크기를 키워 놔도 본문과 구분되지 않는다.
- **모든 장은 인쇄에서 새 페이지에서 시작한다 — 이 강제를 끄지 않는다**(SKILL.md 절대 원칙 7). `class="sec cont"`는 그 강제를 꺼서 앞 `.sec`에 이어 붙이는데, **유일한 용도는 긴 장 하나를 두 `.sec`로 쪼개 놓고 인쇄에서 원래대로 한 장으로 보이게 할 때**다. 이때 뒤쪽 `.sec`는 같은 장의 연장이므로 `.no`/`h2`/`.lead` 장 머리를 다시 넣지 않는다. **자투리 페이지나 채움률을 이유로 쓰면 안 된다** — 그러면 그 장의 `h2`가 페이지 중간에서 시작해 앞 장에 딸린 소제목처럼 읽힌다.

## 4. 본문 · 리스트

```html
<p data-anim>본문 문단. 한 문단 3~5문장. <b>강조</b></p>
<h3 data-anim>소제목</h3>
<h4 data-anim>더 작은 소제목</h4>

<ul class="pts" data-anim>
  <li><b>항목</b> — 설명</li>
</ul>

<ol class="nums" data-anim>          <!-- 순서·우선순위가 있을 때 -->
  <li><b>권고 1</b> — 실행 내용</li>
</ol>
```

## 5. 표 (tw + table)

```html
<div class="figw" data-anim>
  <div class="tw">
    <table>
      <thead><tr><th>구분</th><th>항목</th><th class="num">수치</th></tr></thead>
      <tbody>
        <tr><td>행 이름</td><td>내용</td><td class="num">1,240</td></tr>
      </tbody>
    </table>
  </div>
  <p class="cap">표 1. 표 설명 · 출처: 출처</p>
</div>
```
- **주석을 다는 표는 반드시 `.figw`로 감싼다.** 그래야 「표 + 주석」이 인쇄에서 한 덩어리로 묶여 주석만 다음 장으로 떨어지지 않는다. (`.cap`의 `break-before:avoid`만으로는 표가 페이지를 꽉 채운 경우 브라우저가 규칙을 포기한다.)
- 주석이 없는 표는 `.tw`만 써도 된다.
- 「표 + 주석」이 한 덩어리이므로 그만큼 표를 짧게 잡는다.
- **표에 딸린 긴 부연 설명은 주석에 넣지 말고, 표 뒤에 일반 문단으로 쓴다.** 부연까지 덩어리에 넣으면 한 페이지를 넘겨 오히려 갈라진다. 주석은 「표 번호 + 한 줄 설명 + 출처」로 끝낸다.
- **표는 원문 목록을 대체하지 않는다.** 원문이 「표 + 항목별 설명」이면 보고서도 「표 + 항목별 설명」(표 → `.cap` → `pts`)으로 간다. 항목별 설명을 표의 '비고' 칸이나 표 앞 도입 문단에 욱여넣으면 사실이 조용히 사라진다(SKILL.md 원칙 5).
  - '비고' 칸은 **한 줄로 끝나는 꼬리표**만 담는다. 두 문장이 필요하면 그건 본문이다.
  - 도입 문단은 **표를 읽는 법**을 알려 주는 1~3문장이다. 개별 행의 사연을 여기에 몰아넣지 않는다.
- 숫자 열의 `th`/`td`에 `class="num"`(우측 정렬 + 자릿수 정렬).
- 열은 **5개 이하**. 그보다 많으면 표를 나누거나 카드로 바꾼다.
- 행은 **12개 이하**. 그보다 길면 인쇄에서 한 페이지를 넘겨 표가 갈라진다(이때 `thead`는 다시 찍히지만, 나누는 편이 낫다).
- **첫 열은 짧은 라벨**(대략 12자 이내). 첫 열과 머리행은 줄바꿈되지 않으므로(`white-space:nowrap`) 키워드가 항상 한 줄로 보인다. 긴 문장을 첫 열에 넣으면 표가 옆으로 넘치니, 꼭 필요하면 그 칸에만 `<td class="wrap">`을 준다.
- `thead` 색은 장의 `--bgc`/`--ct`를 자동으로 따른다.

## 6. 콜아웃 (callout)

```html
<div class="callout tone" data-anim>              <!-- tone = 배경 채움 -->
  <div class="ck">NOTE</div>
  <p>짚고 넘어갈 전제·주의점.</p>
</div>

<div class="callout" data-anim style="--c:var(--risk); --ct:var(--riskT); --bgc:var(--riskB)">
  <div class="ck">RISK</div>
  <p>위험·한계.</p>
</div>
```
- 라벨 예: `NOTE` `RISK` `한계` `가정` `권고`. 한 장에 **2개 이하**.

## 7. 지표 타일 (stats)

```html
<div class="stats" data-anim>          <!-- 2개면 class="stats two" -->
  <div class="stat" style="--c:var(--a1); --ct:var(--a1t)">
    <div class="sl">지표명</div>
    <div class="sv">42<small>%</small></div>
    <div class="sd">보조 설명 한 줄</div>
  </div>
  <!-- a2, a3 순환 -->
</div>
```
- 3개(또는 2개)까지. 값은 짧게, 단위는 `<small>`로.

## 8. 카드 (cards)

```html
<div class="cards" data-anim>          <!-- 3열은 class="cards three" -->
  <div class="card" style="--c:var(--a1); --ct:var(--a1t)">
    <div class="idx">01</div><h3>카드 제목</h3>
    <p>2~3줄 설명.</p>
  </div>
</div>
```
- 카드 안에 `<ul class="pts">`도 가능. 3열 카드의 설명은 2줄 이내.

## 9. 단계 (steps) — 세로 타임라인

```html
<div class="steps" data-anim>
  <div class="stp" style="--c:var(--a1); --ct:var(--a1t)">
    <div class="sn">STEP 01</div><h3>단계명</h3><p>설명</p>
  </div>
  <!-- a2, a3 순환. 3~6단계 -->
</div>
```
- **인쇄에서 통째로 한 페이지에 들어간다.** 그러니 한 블록에 **6단계 이하, 단계 설명 2~3줄**을 지킨다. 단계가 많거나 설명이 길면 소제목을 하나 더 두고 블록을 둘로 나눈다.

## 10. 정의 목록 (kv) — 용어·항목 정의

```html
<div class="kv" data-anim>
  <div class="row"><div class="k">용어</div><div class="d">정의 설명</div></div>
  <div class="row"><div class="k">용어</div><div class="d">정의 설명</div></div>
</div>
```

## 11. 인용 (quote) / 코드 (code)

```html
<div class="quote" data-anim style="--c:var(--a2)">
  <p>인용 문장.</p>
  <div class="by">— 출처 · 직함</div>
</div>

<div class="code" data-anim><pre>$ 명령어
출력</pre></div>
```
- `code` 안은 `<pre>` 그대로. HTML 특수문자는 `&lt;` `&amp;`로 이스케이프.

## 12. 결론 배너 / 참고문헌 / 푸터

```html
<div class="banner" data-anim>맺음 문장 — <b>핵심</b></div>

<ol class="refs" data-anim>
  <li>저자, 「제목」, 발행처, 2025.</li>       <!-- 번호 [1] 자동 -->
</ol>

<footer class="foot">
  <div><b>보고서 제목</b> · 작성자</div>
  <div>2026-07-29</div>
</footer>
```

---

## 분량 감각

- **장(`.sec`)의 개수는 자료가 정한다.** 정해진 상한은 없다. 자료가 12개 장으로 나뉘고 각 장이 한 페이지를 넘긴다면 12개로 간다 — 억지로 묶으면 장 안이 `h3`만으로 눌려 도리어 읽기 나빠진다.
- 대신 **한 장은 A4 반 페이지 이상**을 채워야 한다. 장이 새 페이지에서 시작하므로 짧은 장은 남은 지면을 그대로 버린다. 적정 분량은 **A4 1~3페이지**(문단 3~6개 + 시각 요소 1~2개). **절반도 못 채우는 장**은 앞뒤 장과 **실제로 합치거나**(`h2`를 하나로 만들고 원래 장들은 `h3`로 내린다) 내용을 보강한다. `class="sec cont"`로 페이지 나눔만 끄는 것은 금지다 — 장 제목이 페이지 중간에 뜬다. 두 수단으로 안 되면 자투리를 그대로 두고 사용자에게 알린다. 실측은 `printcheck.ps1`.
- 문단은 3~5문장. 6문장을 넘으면 나눈다.
- 한 장에 같은 컴포넌트를 **연속 3번 이상 쓰지 않는다**(표-표-표 금지). 서술 → 시각 요소 → 서술로 리듬을 준다.
- **간격 층위는 손대지 않는다.** 「문단 28px < 소제목 뒤 36px < 블록 사이 46px < 소제목 앞 108px < 장 머리→첫 소제목 116px」이 사다리이고, **장 머리 뒤(32px)만 예외로 좁다**(도입 문단을 장 머리에 붙여 두기 위해). 어느 한 칸만 넓히면 그 칸이 도리어 뭉쳐 보인다. 페이지가 넘치면 `--pgap`·`--pfs`나 분량으로 해결한다(SKILL.md 원칙 9).
- **블록을 연달아 놓을 때 간격은 템플릿이 알아서 준다.** 표 → 콜아웃, 카드 → 단계처럼 시각 블록이 붙어 나오면 `:is(…)+:is(…)` 규칙이 간격을 키운다. 마크업에 여백용 `<br>`이나 인라인 `style="margin-top:…"`을 넣지 않는다. **다만 새 컴포넌트를 추가하면 그 클래스를 `:is()` 목록 양쪽에 넣어야** 규칙이 적용된다.
- 시각 요소 없이 문단만 5개 이상 이어지면, 하나를 `pts`·`kv`·`callout`으로 바꾼다.

---

## 쓰지 말 것 (전 컴포넌트 공통)

인쇄와 실측을 동시에 깨뜨리는 것들이다. 화면에서는 멀쩡해 보이므로 발견이 늦다.

| 쓰지 말 것 | 무슨 일이 일어나는가 | 대신 |
|---|---|---|
| `opacity` (등장 애니메이션 제외) | 인쇄 시 **합성 레이어**가 생겨 그 글자가 독립 텍스트 스트림이 된다. `printcheck.ps1`의 '스트림 하나 = 페이지 하나' 가정이 깨져 **페이지 0쪽으로 보고**된다 | 옅은 단색(`--a1b` 등)으로 채운다 |
| `background-clip:text` 그라데이션 글자 | 인쇄에서 글자가 **통째로 사라진다** | `.mark` 처럼 단색 |
| `color:transparent` + `-webkit-text-stroke` | 위와 같다 | 옅은 단색 채움 |
| `mix-blend-mode` · `filter` | 래스터화되어 텍스트가 이미지가 된다 | 쓰지 않는다 |
| 색 리터럴(`#2E6BFF`) | 테마 교체가 불가능해진다 | 토큰(`var(--a1)`)만 |
| `inline-flex` + `border-radius` 배지 | 별도 페인트 레이어가 생겨 위와 같은 사고를 낸다 | `inline-block` |
| 글자 위 `box-shadow: inset` 형광 밑줄 | 인쇄에서 **취소선처럼** 읽힌다 | 굵기(`<b>`)로만 강조 |

`[data-anim]`의 `opacity`·`transform`은 예외다 — 인쇄 CSS가 이미 무력화한다. 다만 **화면 측정 도구는 그 시작 위치를 실제 위치로 오인**하므로, 재기 전에 중화해야 한다(`slidecheck.ps1`이 그렇게 한다).
