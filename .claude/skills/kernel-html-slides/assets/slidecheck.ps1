<#
  html-slides 넘침 검증기.
  슬라이드 HTML을 Chrome(없으면 Edge) 헤드리스로 열어, 슬라이드마다
  '내용이 1280x720 캔버스 안에 들어오는지'를 실측한다.

  사용:  powershell -ExecutionPolicy Bypass -File slidecheck.ps1 "C:\경로\슬라이드.html"

  왜 눈으로 보면 안 되는가
    .slide 는 overflow:hidden 이라, 넘친 내용은 화면에서 '그냥 안 보인다'.
    한 줄이 잘려 나가도 레이아웃이 깨지지 않으므로 육안으로는 멀쩡해 보인다.
    그래서 재야 한다.

  읽는 법
    - 여유(px)가 음수면 그 슬라이드는 넘쳤다 → 항목을 줄이거나 슬라이드를 나눈다.
    - 여유가 20px 미만이면 폰트 로딩·줄바꿈 차이로 넘칠 수 있는 경계다.
    - 표지(cover)는 세로 가운데 정렬이라 여유가 크게 나오는 것이 정상이다.
#>
param(
  [Parameter(Mandatory=$true)][string]$Html,
  [int]$MinSlack = 0
)

$ErrorActionPreference = 'Stop'
$Html = (Resolve-Path $Html).Path
$src  = Get-Content $Html -Raw -Encoding UTF8

# --- 측정 스크립트를 사본에 심는다(원본은 건드리지 않는다) -------------------
# deck 의 scale 변환을 잠시 끄고, 슬라이드마다 가장 아래 요소의 바닥을 잰다.
# 캔버스 높이에서 아래 패딩을 뺀 값이 '내용이 들어와야 할 선'이다.
$probe = @'
<script id="slidecheck">
(function(){
  function run(){
    // 비활성 슬라이드의 [data-anim] 은 등장 전 상태(translateY(18px))로 누워 있다.
    // 그대로 재면 모든 슬라이드가 일정하게 넘친 것처럼 보인다 — 먼저 중화한다.
    var st = document.createElement('style');
    st.textContent = '[data-anim]{opacity:1!important;transform:none!important;animation:none!important}';
    document.head.appendChild(st);
    var deck = document.getElementById('deck');
    var keep = deck ? deck.style.transform : '';
    if (deck) deck.style.transform = 'none';
    var out = [];
    var wraps = [];
    // 덤프 인코딩과 무관하게 JSON 이 깨지지 않도록 라벨을 ASCII 로만 실어 보낸다.
    function asc(x){ return String(x).replace(/[^ -~]/g, function(c){
      return '\\u' + ('000' + c.charCodeAt(0).toString(16)).slice(-4); }); }
    // 폭이 고정된 라벨 칸들 — 글자가 길면 소리 없이 두 줄이 된다.
    var LBL = '.deflist .row .k, .deflist .row .c, .card .svc .k, .step h3, .role .lab, .panel .pk';
    var slides = document.querySelectorAll('.slide');
    for (var i = 0; i < slides.length; i++) {
      var s = slides[i];
      var pv = s.style.visibility, po = s.style.opacity;
      s.style.visibility = 'visible'; s.style.opacity = '1';
      var cs = getComputedStyle(s);
      var padB = parseFloat(cs.paddingBottom) || 0;
      var H = s.getBoundingClientRect().height || 720;
      var top = s.getBoundingClientRect().top;
      var bottom = 0;
      var all = s.querySelectorAll('*');
      for (var j = 0; j < all.length; j++) {
        var r = all[j].getBoundingClientRect();
        if (r.height > 0) { var b = r.bottom - top; if (b > bottom) bottom = b; }
      }
      var lbl = s.querySelectorAll(LBL);
      for (var w = 0; w < lbl.length; w++) {
        var el = lbl[w], ecs = getComputedStyle(el);
        var lh = parseFloat(ecs.lineHeight);
        if (!lh || isNaN(lh)) lh = parseFloat(ecs.fontSize) * 1.35;
        if (el.offsetHeight > lh * 1.6) {
          wraps.push({ n: i + 1, lines: Math.round(el.offsetHeight / lh),
                       w: Math.round(el.offsetWidth),
                       t: asc(el.textContent.replace(/[ ]+/g, ' ').trim().slice(0, 26)) });
        }
      }
      s.style.visibility = pv; s.style.opacity = po;
      out.push({
        n: i + 1,
        cover: s.className.indexOf('cover') >= 0 ? 1 : 0,
        bottom: Math.round(bottom),
        limit: Math.round(H - padB),
        slack: Math.round(H - padB - bottom)
      });
    }
    if (deck) deck.style.transform = keep;
    var d = document.createElement('div');
    d.id = 'SLIDECHECK';
    d.textContent = JSON.stringify(out);
    document.body.appendChild(d);
    var d2 = document.createElement('div');
    d2.id = 'SLIDEWRAP';
    d2.textContent = JSON.stringify(wraps);
    document.body.appendChild(d2);
  }
  // 웹폰트가 오면 줄바꿈이 바뀐다. 폰트가 준비된 뒤에 재야 한다.
  if (document.fonts && document.fonts.ready) { document.fonts.ready.then(run); } else { window.addEventListener('load', run); }
})();
</script>
'@

# 임시 폴더. $env:TEMP 는 Windows 에만 있다 — mac/Linux 의 pwsh 에서는 비어 있어
# Join-Path 가 터진다. .NET 의 GetTempPath() 는 세 플랫폼 모두에서 답을 준다.
$tmpDir = [IO.Path]::GetTempPath()

$tmp = Join-Path $tmpDir ('slidecheck_' + [IO.Path]::GetFileNameWithoutExtension($Html) + '.html')
($src -replace '(?i)</body>', ($probe + "`n</body>")) | Set-Content $tmp -Encoding UTF8

# Windows·macOS·Linux 의 설치 위치를 순서대로 훑는다.
# 없는 플랫폼의 경로는 Test-Path 에서 그냥 걸러지므로 한 목록으로 둬도 된다.
$browser = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser',
  '/usr/bin/microsoft-edge'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

# 그래도 못 찾으면 PATH 에 걸린 이름으로 한 번 더 본다(리눅스 배포판마다 경로가 다르다).
if (-not $browser) {
  $browser = @('google-chrome','chromium','chromium-browser','msedge','chrome') |
             ForEach-Object { (Get-Command $_ -ErrorAction SilentlyContinue).Source } |
             Where-Object { $_ } | Select-Object -First 1
}
if (-not $browser) { throw 'Chrome 또는 Edge를 찾지 못했다. CHROME 경로를 직접 확인하라.' }

# 이미 떠 있는 브라우저에 위임되지 않도록 별도 프로필을 쓴다(printcheck.ps1과 같은 이유).
$profileDir = Join-Path $tmpDir ('slidecheck_profile_' + [IO.Path]::GetRandomFileName())
$dump = Join-Path $tmpDir ('slidecheck_dom_' + [IO.Path]::GetRandomFileName() + '.html')

$args = @(
  '--headless','--disable-gpu','--run-all-compositor-stages-before-draw',
  '--virtual-time-budget=12000','--window-size=1280,720','--dump-dom',
  ('--user-data-dir="' + $profileDir + '"'),
  ('"' + $tmp + '"')
)
& $browser @args 2>$null | Set-Content $dump -Encoding UTF8
if (Test-Path $profileDir) { Remove-Item $profileDir -Recurse -Force -ErrorAction SilentlyContinue }

$dom = Get-Content $dump -Raw -Encoding UTF8
$m = [regex]::Match($dom, '<div id="SLIDECHECK">(.*?)</div>', 'Singleline')
if (-not $m.Success) { throw '측정 결과를 찾지 못했다(페이지가 로드되지 않았거나 스크립트가 막혔다).' }

$mw = [regex]::Match($dom, '<div id="SLIDEWRAP">(.*?)</div>', 'Singleline')
$wraps = @()
if ($mw.Success -and $mw.Groups[1].Value.Trim() -ne '[]') {
  foreach ($x in (ConvertFrom-Json -InputObject ($mw.Groups[1].Value -replace '&quot;','"'))) { $wraps += $x }
}

$rows = $m.Groups[1].Value |
        ForEach-Object { $_ -replace '&quot;','"' } |
        ConvertFrom-Json

"파일  : $Html"
"슬라이드: $($rows.Count)장   (캔버스 1280x720, 여유 기준 {0}px)" -f $MinSlack
''
$bad = @(); $tight = @()
foreach ($r in $rows) {
  $flag = ''
  # 본문 슬라이드는 대개 flex:1 로 캔버스를 꽉 채우므로 여유 0 이 정상이다.
  # 음수만 진짜 넘침이다(중첩 상자가 자기 칸을 넘어선 경우까지 여기서 잡힌다).
  if ($r.slack -lt 0) { $flag = '  <-- 넘침'; $bad += $r.n }
  elseif ($MinSlack -gt 0 -and $r.slack -lt $MinSlack -and $r.cover -eq 0) { $flag = '  <-- 여유 부족'; $tight += $r.n }
  $kind = if ($r.cover -eq 1) { 'cover ' } else { '      ' }
  "  s{0,-3} {1} 바닥 {2,4}px / 한계 {3,4}px   여유 {4,5}px{5}" -f $r.n, $kind, $r.bottom, $r.limit, $r.slack, $flag
}
''
if ($wraps.Count) {
  '라벨 줄바꿈 — 폭이 고정된 칸이다. 칸을 넓히지 말고 글자를 줄인다:'
  foreach ($w in $wraps) { '  s' + ([string]$w.n).PadRight(3) + ' ' + [string]$w.lines + '줄 / 폭 ' + [string]$w.w + 'px   ' + [regex]::Replace($w.t, '\\u([0-9a-fA-F]{4})', { param($m) [string][char][convert]::ToInt32($m.Groups[1].Value, 16) }) }
  ''
}
if ($bad.Count -eq 0 -and $tight.Count -eq 0 -and $wraps.Count -eq 0) {
  '판정: 통과 — 모든 슬라이드가 캔버스 안에 들어오고, 접힌 라벨도 없다.'
} else {
  if ($bad.Count)   { "판정: 넘침 — 슬라이드 $(($bad | Sort-Object -Unique) -join ', '). 항목을 줄이거나 슬라이드를 나눈다(폰트를 줄이지 않는다)." }
  if ($tight.Count) { "판정: 여유 부족 — 슬라이드 $(($tight | Sort-Object -Unique) -join ', '). 폰트 로딩·줄바꿈 차이로 넘칠 수 있다." }
  if ($wraps.Count) { "판정: 라벨 줄바꿈 — 슬라이드 $((($wraps | ForEach-Object { $_.n }) | Sort-Object -Unique) -join ', '). 라벨 글자를 줄이고 설명은 옆 칸으로 옮긴다." }
}
