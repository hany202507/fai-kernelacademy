<#
  html-report 인쇄 검증기.
  보고서 HTML을 Chrome(없으면 Edge) 헤드리스로 A4 PDF에 인쇄한 뒤,
  페이지 수와 '페이지별 채움률'(맨 아래 글자가 인쇄 영역의 몇 %까지 내려왔는지)을 보고한다.

  사용:  powershell -ExecutionPolicy Bypass -File printcheck.ps1 "C:\경로\보고서.html"

  최종 PDF를 보고서 옆에 남기려면 -Pdf로 경로를 준다(브라우저 인쇄를 거치지 않으므로
  머리글·바닥글에 날짜·제목·file:// 주소가 찍히지 않는다):
         powershell -ExecutionPolicy Bypass -File printcheck.ps1 "C:\경로\보고서.html" -Pdf "C:\경로\보고서.pdf"

  읽는 법
    - 55% 미만  → 아래쪽 공백이 과하다. 그 장의 분량을 늘리거나(문단·항목 추가),
                  앞 장에서 --pfs를 낮춰 페이지를 당겨 채운다.
    - 표지(1p)와 문서 마지막 페이지는 낮아도 정상이다.
    - 100%에 근접하면 다음 페이지로 한 줄이 흘러넘칠 위험이 있으니 --pfs를 0.2pt 낮춘다.
#>
param(
  [Parameter(Mandatory=$true)][string]$Html,
  [string]$Pdf
)

$ErrorActionPreference = 'Stop'
$Html = (Resolve-Path $Html).Path
# 기본 출력은 임시 폴더 — 프로젝트 폴더에 PDF를 남기지 않는다.
# 임시 폴더. $env:TEMP 는 Windows 에만 있다 — mac/Linux 의 pwsh 에서는 비어 있어
# Join-Path 가 터진다. .NET 의 GetTempPath() 는 세 플랫폼 모두에서 답을 준다.
$tmpDir = [IO.Path]::GetTempPath()
if (-not $Pdf) { $Pdf = Join-Path $tmpDir ([IO.Path]::GetFileNameWithoutExtension($Html) + '.printcheck.pdf') }

# Windows·macOS·Linux 의 설치 위치를 순서대로 훑는다.
# 없는 플랫폼의 경로는 Test-Path 에서 그냥 걸러지므로 한 목록으로 둬도 된다.
# (예전에 있던 "$env:ProgramFiles (x86)\..." 항목은 변수 뒤에 문자열이 붙은 형태라
#  실제로는 존재하지 않는 경로였다. 아래 ${env:ProgramFiles(x86)} 가 그 자리를 덮는다.)
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
if (-not $browser) { throw 'Chrome 또는 Edge를 찾지 못했다. 브라우저 경로를 직접 확인하라.' }

if (Test-Path $Pdf) { Remove-Item $Pdf -Force }
$started = Get-Date
# --user-data-dir이 없으면 이미 떠 있는 Chrome에 위임되어 인쇄가 조용히 건너뛰어진다
# (그러면 예전 PDF를 그대로 읽어 낡은 결과를 보고하게 된다).
# 경로에 공백이 있으면 인자가 쪼개져 'Multiple targets' 오류가 나므로 큰따옴표로 감싼다.
$profile = Join-Path $tmpDir ('printcheck_profile_' + [IO.Path]::GetRandomFileName())
Start-Process -FilePath $browser -Wait -NoNewWindow -ArgumentList `
  '--headless','--disable-gpu','--no-pdf-header-footer',
  '--run-all-compositor-stages-before-draw','--virtual-time-budget=10000',
  ('--user-data-dir="' + $profile + '"'),
  ('--print-to-pdf="' + $Pdf + '"'), ('"' + $Html + '"')
if (Test-Path $profile) { Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue }
if (-not (Test-Path $Pdf)) { throw 'PDF 생성에 실패했다.' }
if ((Get-Item $Pdf).LastWriteTime -lt $started) { throw 'PDF가 갱신되지 않았다(낡은 결과를 읽을 뻔했다).' }

# --- @page 여백에서 인쇄 영역 높이 계산 (A4 세로 297mm = 1122.52 CSS px) ---
$src = Get-Content $Html -Raw -Encoding UTF8
$mt = 15.0; $mb = 15.0
$m = [regex]::Match($src, '@page[^{]*\{[^}]*?margin:\s*([\d.]+)mm\s+([\d.]+)mm(?:\s+([\d.]+)mm)?')
if ($m.Success) {
  $mt = [double]$m.Groups[1].Value
  $mb = if ($m.Groups[3].Success) { [double]$m.Groups[3].Value } else { $mt }
}
$H = 1122.52 - ($mt + $mb) / 25.4 * 96

# --- 배치 결함 판정용 기준 글자 크기(pt -> px) ---
# 인쇄 스케일이 고정 pt이므로 크기만으로 요소 종류를 구분할 수 있다.
function PtPx([string]$pattern) {
  $mm = [regex]::Match($src, $pattern)
  if ($mm.Success) { [math]::Round([double]$mm.Groups[1].Value / 72 * 96, 2) } else { -1 }
}
$szH3  = PtPx '--ph3:\s*([\d.]+)pt'
$szH4  = PtPx '\n\s*h4\{font-size:([\d.]+)pt'
$szCap = PtPx '\.doc p\.cap\{font-size:([\d.]+)pt'

# --- PDF 콘텐츠 스트림에서 페이지별 텍스트 y좌표 추출 ---
$enc   = [Text.Encoding]::GetEncoding(28591)
$bytes = [IO.File]::ReadAllBytes($Pdf)
$txt   = $enc.GetString($bytes)

$rows = @(); $idx = 0; $page = 0
while (($s = $txt.IndexOf('stream', $idx)) -ge 0) {
  $st = $s + 6
  if ($txt[$st] -eq "`r") { $st++ }
  if ($txt[$st] -eq "`n") { $st++ }
  $e = $txt.IndexOf('endstream', $st); if ($e -lt 0) { break }
  $len = $e - $st; $dec = $null
  if ($len -gt 4) {
    try {
      $ms = New-Object IO.MemoryStream(, $bytes[($st + 2)..($st + $len - 1)])
      $ds = New-Object IO.Compression.DeflateStream($ms, [IO.Compression.CompressionMode]::Decompress)
      $dec = (New-Object IO.StreamReader($ds, $enc)).ReadToEnd()
    } catch { }
  }
  if ($dec -and $dec.Contains(' Tm')) {
    $page++
    # 본문 좌표는 페이지마다 H씩 누적된다. 그 밴드를 벗어난 값(@page 마진 박스의
    # 페이지 번호 등)은 본문이 아니므로 버린다.
    $lo = ($page - 1) * $H
    $runs = [regex]::Matches($dec, '/F\d+ ([\d.]+) Tf\s*1 0 0 -1 [\d.]+ ([\d.]+) Tm') |
            ForEach-Object {
              [pscustomobject]@{ Size = [math]::Round([double]$_.Groups[1].Value, 2)
                                 Y    = [double]$_.Groups[2].Value } } |
            Where-Object { $_.Y -ge $lo -and $_.Y -le $lo + $H }
    if ($runs.Count -gt 0) {
      $sorted = $runs | Sort-Object Y
      $top    = $sorted[0]
      $bottom = $sorted[-1]
      $rows += [pscustomobject]@{
        Page   = $page
        Fill   = ($bottom.Y - $lo) / $H * 100
        Orphan = ($bottom.Size -eq $szH3 -or $bottom.Size -eq $szH4)   # 맨 아래가 소제목
        CapCut = ($top.Size -eq $szCap)                                # 맨 위가 표·그림 주석
      }
    }
  }
  $idx = $e + 9
}

"파일 : $Pdf"
"페이지: $($rows.Count)장   (인쇄 영역 높이 {0:N0}px, 여백 {1}/{2}mm)" -f $H, $mt, $mb
''
$warn = @(); $defect = @()
foreach ($r in $rows) {
  $flag = @()
  if ($r.Page -ne 1 -and $r.Page -ne $rows.Count) {
    if ($r.Fill -lt 55) { $flag += '공백 과다'; $warn += $r.Page }
    elseif ($r.Fill -gt 99) { $flag += '넘침 위험'; $warn += $r.Page }
  }
  if ($r.Orphan) { $flag += '소제목 고아(맨 아래가 소제목)'; $defect += $r.Page }
  if ($r.CapCut) { $flag += '주석 분리(맨 위가 표·그림 주석)'; $defect += $r.Page }
  $mark = if ($flag.Count) { '  <-- ' + ($flag -join ' / ') } else { '' }
  "  p{0,-3} {1,5:N0}%  {2}{3}" -f $r.Page, $r.Fill, ('#' * [math]::Round($r.Fill / 4)), $mark
}
''
if ($warn.Count -eq 0 -and $defect.Count -eq 0) {
  '판정: 통과 — 조정할 페이지 없음.'
} else {
  if ($defect.Count) {
    "판정: 배치 결함 — 페이지 $(($defect | Sort-Object -Unique) -join ', '). 소제목·주석이 딸린 블록과 갈라졌다."
    "      템플릿의 break-after/break-before 규칙이 살아 있는지 먼저 확인하고, 그래도 남으면 그 블록을 줄인다."
  }
  if ($warn.Count) {
    "판정: 여백 조정 필요 — 페이지 $(($warn | Sort-Object -Unique) -join ', ')."
    "      --pgap → --pfs → --ph3 순으로 손보거나 해당 장의 분량을 조정한다."
  }
}
