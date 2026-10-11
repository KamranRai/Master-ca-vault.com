# CA-Vault static site generator.
# Usage:  powershell -ExecutionPolicy Bypass -File build.ps1
# Reads src/ (pages, partials, data, assets) and writes the deployable site to dist/.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads scripts as ANSI).

param([string]$Base = '', [string]$OutDir = 'dist', [string]$Site = 'https://www.ca-vault.com')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $root 'src'
$out  = Join-Path $root $OutDir
$site = $Site.TrimEnd('/')
$utf8 = New-Object System.Text.UTF8Encoding $false
$today = (Get-Date).ToString('yyyy-MM-dd')

function ReadText($p) { [IO.File]::ReadAllText($p, $utf8) }
function WriteText($p, $t) {
  $d = Split-Path -Parent $p
  if (!(Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
  [IO.File]::WriteAllText($p, $t, $utf8)
}
function Esc($s) { [System.Net.WebUtility]::HtmlEncode([string]$s) }
function Plain($s) {
  $t = [regex]::Replace([string]$s, '<[^>]+>', '')
  ([System.Net.WebUtility]::HtmlDecode($t) -replace '\s+', ' ').Trim()
}
function Json($o) { ConvertTo-Json -InputObject $o -Depth 12 -Compress }

# ---------- data ----------
$partials = @{}
Get-ChildItem (Join-Path $src 'partials') -Filter *.html | ForEach-Object { $partials[$_.BaseName] = ReadText $_.FullName }
$quotes   = ConvertFrom-Json (ReadText (Join-Path $src 'data\testimonials.json'))
$features = ConvertFrom-Json (ReadText (Join-Path $src 'data\features.json'))
$roles    = ConvertFrom-Json (ReadText (Join-Path $src 'data\solutions.json'))
$shots    = ConvertFrom-Json (ReadText (Join-Path $src 'data\screenshots.json'))

$featureBySlug = @{}; foreach ($f in $features) { $featureBySlug[$f.slug] = $f }

# ---------- components ----------
function Render-Shot($id, $caption, $eager) {
  $s = $shots.$id
  if (-not $s) { throw "Unknown screenshot '$id'" }
  $load = 'loading="lazy" decoding="async"'; if ($eager) { $load = 'fetchpriority="high" decoding="async"' }
  $cap = ''; if ($caption) { $cap = "<figcaption>$caption</figcaption>" }
  return @"
<figure class="frame" data-reveal>
  <div class="frame__bar" aria-hidden="true"><i></i><i></i><i></i><span>$($s.label)</span></div>
  <img src="/assets/img/product/$($s.file)" width="$($s.w)" height="$($s.h)" alt="$(Esc $s.alt)" $load>
  $cap
</figure>
"@
}

function Render-Placeholder($kind, $title, $note) {
  return @"
<aside class="ph" data-placeholder="$(Esc $kind)">
  <p class="ph__tag">Placeholder &middot; $kind</p>
  <p class="ph__title">$title</p>
  <p class="ph__note"><strong>Asset needed:</strong> $note</p>
</aside>
"@
}

function Render-Quote($id) {
  $q = $quotes.$id
  if (-not $q) { throw "Unknown testimonial '$id'" }
  $metric = ''; if ($q.metric) { $metric = "<p class=`"quote__metric`"><strong>$($q.metric)</strong><span>$($q.metricLabel)</span></p>" }
  $av = "<span class=`"avatar`" aria-hidden=`"true`">$($q.initials)</span>"
  if ($q.photo) { $av = "<span class=`"avatar avatar--photo`"><img src=`"/assets/img/people/$($q.photo)`" width=`"96`" height=`"96`" alt=`"$($q.name)`" loading=`"lazy`"></span>" }
  return @"
<figure class="quote" data-reveal>
  $metric
  <blockquote><p>&ldquo;$($q.text)&rdquo;</p></blockquote>
  <figcaption>
    $av
    <span><strong>$($q.name)</strong><br>$($q.role), $($q.company)</span>
  </figcaption>
  <p class="quote__src">Customer feedback shared while the product was named ContractComplete. <a href="/customers/">Read customer stories</a></p>
</figure>
"@
}

function Render-Cta($h, $p, $b) {
  if (-not $h) { $h = 'Ready to simplify construction project administration?' }
  if (-not $p) { $p = 'Tell us a little about your team and we will show you how CA-Vault fits the way you tender, administer and certify work.' }
  if (-not $b) { $b = 'Book a Free Demo' }
  $trust = $partials['trustrow'].Replace('{{> logos}}', $partials['logos'].Replace('class="logos"', 'class="logos logos--strip"'))
  return @"
$trust
<section class="cta-band" aria-labelledby="cta-h">
  <div class="wrap cta-band__in">
    <div>
      <p class="eyebrow eyebrow--amber"><span>Next step</span> On the record</p>
      <h2 id="cta-h">$h</h2>
      <p class="lead">$p</p>
      <div class="btn-row">
        <a class="btn btn--primary btn--lg" href="/book-demo/" data-event="demo_cta_click" data-loc="cta-band">$b</a>
        <a class="btn btn--line-light" href="/product-tour/" data-event="product_tour_start" data-loc="cta-band">Watch Product Tour</a>
      </div>
    </div>
    <div class="stamp" aria-hidden="true" data-reveal><span>One project</span><b>ONE RECORD</b><span>CA-Vault</span></div>
  </div>
</section>
"@
}

function Render-Faq($items) {
  $h = '<div class="faq-list">'
  foreach ($i in $items) { $h += "<details class=`"faq`"><summary>$($i.q)</summary><div class=`"faq__a`"><p>$($i.a)</p></div></details>" }
  return $h + '</div>'
}

function Render-Flow($label, $items, $mod) {
  $h = "<div class=`"flow flow--$mod`"><p class=`"flow__label`">$label</p><ol>"
  foreach ($i in $items) { $h += "<li>$i</li>" }
  return $h + '</ol></div>'
}

function Render-FeatureLedger($slugs) {
  $h = '<ul class="ledger">'
  foreach ($s in $slugs) {
    $f = $featureBySlug[$s]
    if (-not $f) { throw "Unknown feature '$s'" }
    $h += "<li class=`"ledger__row`"><span class=`"ledger__no`">$($f.num)</span><h3 class=`"ledger__t`"><a href=`"/platform/$($f.slug)/`">$($f.label)</a></h3><p class=`"ledger__d`">$($f.short)</p><a class=`"link-arrow`" href=`"/platform/$($f.slug)/`" aria-label=`"Explore $(Esc $f.label)`">Explore</a></li>"
  }
  return $h + '</ul>'
}

# ---------- templates ----------
function Render-Feature($f) {
  if ($f.shot) { $visual = Render-Shot $f.shot $f.shotCaption $true }
  else { $visual = Render-Placeholder 'Product screenshot' "Insert current CA-Vault product UI: $($f.label)" $f.shotNeeded }
  $caps = '<ul class="ledger ledger--plain">'; $n = 1
  foreach ($c in $f.caps) { $caps += "<li class=`"ledger__row`"><span class=`"ledger__no`">$($f.num).$n</span><h3 class=`"ledger__t`">$($c.t)</h3><p class=`"ledger__d`">$($c.d)</p></li>"; $n++ }
  $caps += '</ul>'
  $steps = '<ol class="chain">'
  foreach ($s in $f.steps) { $steps += "<li><h3>$($s.t)</h3><p>$($s.d)</p></li>" }
  $steps += '</ol>'
  if ($f.quote) { $proof = Render-Quote $f.quote }
  else { $proof = Render-Placeholder 'Customer proof' "Customer story for $($f.label) coming soon" "A verified customer quote or case study that speaks specifically to $($f.label.ToLower()). Do not reuse an unrelated testimonial here." }
  $body = @"
<section class="page-hero">
  <div class="wrap page-hero__in">
    <div class="page-hero__copy">
      {{crumbs}}
      <p class="eyebrow"><span>$($f.num)</span> Platform</p>
      <h1>$($f.h1)</h1>
      <p class="lead">$($f.lead)</p>
      <div class="btn-row">
        <a class="btn btn--primary btn--lg" href="/book-demo/" data-event="demo_cta_click" data-loc="feature-hero">$($f.cta)</a>
        <a class="btn btn--ghost" href="/how-it-works/">See How It Works</a>
      </div>
    </div>
    <div class="page-hero__visual">$visual</div>
  </div>
</section>

<section class="section section--white">
  <div class="wrap split">
    <div data-reveal>
      <p class="eyebrow"><span>$($f.num).0</span> The short answer</p>
      <h2>$($f.answerTitle)</h2>
      <p class="answer">$($f.answer)</p>
      <h3 class="h-sm">The problem</h3>
      <p>$($f.problem)</p>
    </div>
    <div class="flows" data-reveal>
      $(Render-Flow 'The old workflow' $f.oldFlow 'old')
      $(Render-Flow 'The CA-Vault workflow' $f.newFlow 'new')
    </div>
  </div>
</section>

<section class="section section--grid">
  <div class="wrap">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($f.num).1</span> Key capabilities</p>
      <h2>$($f.capsTitle)</h2>
    </header>
    $caps
  </div>
</section>

<section class="section section--white">
  <div class="wrap">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($f.num).2</span> Workflow</p>
      <h2>$($f.stepsTitle)</h2>
    </header>
    $steps
  </div>
</section>

<section class="section">
  <div class="wrap split split--proof">
    <div data-reveal>
      <p class="eyebrow"><span>$($f.num).3</span> Proof</p>
      <h2>Evidence, not adjectives.</h2>
      <p>CA-Vault is the next evolution of ContractComplete, a platform construction teams have used on real contracts since 2013. Where customers have described a result in their own words, we show it next to the feature it relates to.</p>
      <a class="link-arrow" href="/customers/">Read Customer Stories</a>
    </div>
    $proof
  </div>
</section>

<section class="section section--white">
  <div class="wrap">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($f.num).4</span> Connected to</p>
      <h2>What this record links to next</h2>
    </header>
    $(Render-FeatureLedger $f.related)
  </div>
</section>

<section class="section">
  <div class="wrap wrap--narrow">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($f.num).5</span> FAQ</p>
      <h2>$($f.label): common questions</h2>
    </header>
    $(Render-Faq $f.faq)
  </div>
</section>
$(Render-Cta "See $($f.label.ToLower()) on a real project." 'A short walkthrough using your own workflow: tender, contract, changes and payment.' $f.cta)
"@
  return @{ path = "/platform/$($f.slug)/"; title = $f.title; desc = $f.desc; label = $f.label; body = $body; schema = 'feature' }
}

function Render-Role($r) {
  $pains = '<ul class="cards cards--3">'
  foreach ($p in $r.pains) { $pains += "<li class=`"card`" data-reveal><h3>$($p.t)</h3><p>$($p.d)</p></li>" }
  $pains += '</ul>'
  $work = '<ol class="chain">'
  foreach ($s in $r.workflow) { $work += "<li><h3>$($s.t)</h3><p>$($s.d)</p></li>" }
  $work += '</ol>'
  $outs = '<ul class="ticks">'
  foreach ($o in $r.outcomes) { $outs += "<li>$o</li>" }
  $outs += '</ul>'
  if ($r.quote) { $proof = Render-Quote $r.quote }
  else { $proof = Render-Placeholder 'Customer proof' "$($r.label) customer story coming soon" "A verified quote or case study from a customer in this role ($($r.label.ToLower())). Do not substitute a testimonial from a different audience." }
  $body = @"
<section class="page-hero">
  <div class="wrap page-hero__in">
    <div class="page-hero__copy">
      {{crumbs}}
      <p class="eyebrow"><span>$($r.num)</span> Solutions</p>
      <h1>$($r.h1)</h1>
      <p class="lead">$($r.lead)</p>
      <div class="btn-row">
        <a class="btn btn--primary btn--lg" href="/book-demo/" data-event="demo_cta_click" data-loc="solution-hero">$($r.cta)</a>
        <a class="btn btn--ghost" href="/how-it-works/">See How It Works</a>
      </div>
    </div>
    <div class="page-hero__visual">
      <div class="jobcard" data-reveal>
        <p class="jobcard__k">Job to be done</p>
        <p class="jobcard__v">$($r.job)</p>
        <dl>
          <div><dt>Role on the contract</dt><dd>$($r.party)</dd></div>
          <div><dt>Works most in</dt><dd>$($r.worksIn)</dd></div>
        </dl>
      </div>
    </div>
  </div>
</section>

<section class="section section--white">
  <div class="wrap">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($r.num).1</span> Where the time goes</p>
      <h2>$($r.painsTitle)</h2>
    </header>
    $pains
  </div>
</section>

<section class="section section--grid">
  <div class="wrap split">
    <div data-reveal>
      <p class="eyebrow"><span>$($r.num).2</span> Your workflow in CA-Vault</p>
      <h2>$($r.workTitle)</h2>
      $work
    </div>
    <div data-reveal>
      $(Render-Shot $r.shot $r.shotCaption $false)
      <h3 class="h-sm">What changes</h3>
      $outs
    </div>
  </div>
</section>

<section class="section section--white">
  <div class="wrap">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($r.num).3</span> The parts you will use most</p>
      <h2>Features that matter to $($r.plural)</h2>
    </header>
    $(Render-FeatureLedger $r.features)
  </div>
</section>

<section class="section">
  <div class="wrap split split--proof">
    <div data-reveal>
      <p class="eyebrow"><span>$($r.num).4</span> Proof</p>
      <h2>$($r.proofTitle)</h2>
      <p>$($r.proofText)</p>
      <a class="link-arrow" href="/customers/">Read Customer Stories</a>
    </div>
    $proof
  </div>
</section>

<section class="section section--white">
  <div class="wrap wrap--narrow">
    <header class="section__head" data-reveal>
      <p class="eyebrow"><span>$($r.num).5</span> FAQ</p>
      <h2>Questions $($r.plural) ask</h2>
    </header>
    $(Render-Faq $r.faq)
  </div>
</section>
$(Render-Cta $r.ctaTitle 'We will walk through the workflow from your side of the contract.' $r.cta)
"@
  return @{ path = "/solutions/$($r.slug)/"; title = $r.title; desc = $r.desc; label = $r.label; body = $body; schema = 'solution' }
}

# ---------- collect pages ----------
$pages = @()
$pagesDir = Join-Path $src 'pages'
Get-ChildItem $pagesDir -Recurse -Filter *.html | ForEach-Object {
  $raw = ReadText $_.FullName
  $m = [regex]::Match($raw, '(?s)^\s*<!--(.*?)-->')
  if (-not $m.Success) { throw "Missing front matter in $($_.FullName)" }
  $meta = @{}
  foreach ($line in ($m.Groups[1].Value -split "`n")) {
    $i = $line.IndexOf(':')
    if ($i -gt 0) { $meta[$line.Substring(0, $i).Trim()] = $line.Substring($i + 1).Trim() }
  }
  $rel = $_.FullName.Substring($pagesDir.Length).Replace('\', '/')
  if ($rel -match '/index\.html$') { $path = $rel -replace 'index\.html$', '' }
  elseif ($rel -eq '/404.html') { $path = '/404.html' }
  else { $path = ($rel -replace '\.html$', '') + '/' }
  $pages += @{ path = $path; title = $meta.title; desc = $meta.description; label = $meta.label; body = $raw.Substring($m.Length); schema = $meta.schema; noindex = $meta.noindex }
}
foreach ($f in $features) { $pages += Render-Feature $f }
foreach ($r in $roles)    { $pages += Render-Role $r }

$byPath = @{}; foreach ($p in $pages) { $byPath[$p.path] = $p }

# ---------- macros ----------
function Expand($html) {
  $html = [regex]::Replace($html, '\{\{>\s*([\w-]+)\s*\}\}', { param($m) $partials[$m.Groups[1].Value] })
  $html = [regex]::Replace($html, '\{\{quote:([\w-]+)\}\}', { param($m) Render-Quote $m.Groups[1].Value })
  $html = [regex]::Replace($html, '\{\{shot:([\w-]+)(?:\|([^}]*))?\}\}', { param($m) Render-Shot $m.Groups[1].Value $m.Groups[2].Value $false })
  $html = [regex]::Replace($html, '\{\{ph:([^|}]+)\|([^|}]+)\|([^}]+)\}\}', { param($m) Render-Placeholder $m.Groups[1].Value $m.Groups[2].Value $m.Groups[3].Value })
  $html = [regex]::Replace($html, '\{\{features:([\w,-]+)\}\}', { param($m) Render-FeatureLedger ($m.Groups[1].Value -split ',') })
  $html = [regex]::Replace($html, '\{\{cta(?::([^|}]*)\|([^|}]*)\|([^}]*))?\}\}', { param($m) Render-Cta $m.Groups[1].Value $m.Groups[2].Value $m.Groups[3].Value })
  return $html
}

function Crumbs($page) {
  $segs = $page.path.Trim('/') -split '/'
  $items = @(@{ name = 'Home'; url = '/' })
  $acc = '/'
  foreach ($s in $segs) {
    if (-not $s) { continue }
    $acc += "$s/"
    if ($byPath.ContainsKey($acc)) { $items += @{ name = $byPath[$acc].label; url = $acc } }
  }
  return $items
}

# ---------- layout ----------
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item (Join-Path $src 'assets') (Join-Path $out 'assets') -Recurse
Get-ChildItem (Join-Path $src 'static') -File | ForEach-Object { Copy-Item $_.FullName (Join-Path $out $_.Name) }

$org = @{
  '@type' = 'Organization'; '@id' = "$site/#org"; name = 'CA-Vault'; alternateName = 'ContractComplete'
  url = "$site/"; logo = "$site/assets/img/brand/ca-vault-logo.png"; foundingDate = '2013'
  description = 'CA-Vault, formerly ContractComplete, is construction project administration software.'
}

$searchIndex = @()
foreach ($p in $pages) {
  $body = Expand $p.body
  $isHome = ($p.path -eq '/')
  $canon = $site + $p.path
  $crumbs = Crumbs $p

  $crumbHtml = '<nav class="crumbs" aria-label="Breadcrumb"><ol>'
  for ($i = 0; $i -lt $crumbs.Count; $i++) {
    if ($i -eq $crumbs.Count - 1) { $crumbHtml += "<li aria-current=`"page`">$($crumbs[$i].name)</li>" }
    else { $crumbHtml += "<li><a href=`"$($crumbs[$i].url)`">$($crumbs[$i].name)</a></li>" }
  }
  $crumbHtml += '</ol></nav>'
  $body = $body.Replace('{{crumbs}}', $crumbHtml)

  $graph = @($org)
  if ($isHome) {
    $graph += @{ '@type' = 'WebSite'; '@id' = "$site/#site"; url = "$site/"; name = 'CA-Vault'; publisher = @{ '@id' = "$site/#org" } }
  }
  if ($isHome -or $p.schema -eq 'software' -or $p.schema -eq 'feature') {
    $graph += @{ '@type' = 'SoftwareApplication'; name = 'CA-Vault'; applicationCategory = 'BusinessApplication'; applicationSubCategory = 'Construction Project Administration Software'; operatingSystem = 'Web, iOS, Android'; url = $canon; description = (Plain $p.desc); publisher = @{ '@id' = "$site/#org" } }
  }
  if (-not $isHome -and $p.path -ne '/404.html') {
    $list = @(); $pos = 1
    foreach ($c in $crumbs) { $list += @{ '@type' = 'ListItem'; position = $pos; name = (Plain $c.name); item = ($site + $c.url) }; $pos++ }
    $graph += @{ '@type' = 'BreadcrumbList'; itemListElement = $list }
  }
  $faqs = [regex]::Matches($body, '(?s)<details class="faq"><summary>(.*?)</summary><div class="faq__a">(.*?)</div></details>')
  if ($faqs.Count -gt 0) {
    $qa = @()
    foreach ($m in $faqs) { $qa += @{ '@type' = 'Question'; name = (Plain $m.Groups[1].Value); acceptedAnswer = @{ '@type' = 'Answer'; text = (Plain $m.Groups[2].Value) } } }
    $graph += @{ '@type' = 'FAQPage'; mainEntity = $qa }
  }
  if ($p.schema -eq 'article') {
    $graph += @{ '@type' = 'Article'; headline = (Plain $p.title); description = (Plain $p.desc); dateModified = $today; author = @{ '@id' = "$site/#org" }; publisher = @{ '@id' = "$site/#org" }; mainEntityOfPage = $canon }
  }
  $ld = Json @{ '@context' = 'https://schema.org'; '@graph' = $graph }

  $section = '/' + (($p.path.Trim('/') -split '/')[0]) + '/'
  $header = $partials['header'].Replace("data-nav=`"$section`"", "data-nav=`"$section`" aria-current=`"true`"")
  $robots = 'index,follow'; if ($p.noindex) { $robots = 'noindex,follow' }
  $bodyClass = 'page'; if ($isHome) { $bodyClass = 'page page--home' }

  $html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$($p.title)</title>
<meta name="description" content="$(Esc (Plain $p.desc))">
<meta name="robots" content="$robots">
<link rel="canonical" href="$canon">
<meta property="og:type" content="website">
<meta property="og:site_name" content="CA-Vault">
<meta property="og:title" content="$(Esc (Plain $p.title))">
<meta property="og:description" content="$(Esc (Plain $p.desc))">
<meta property="og:url" content="$canon">
<meta property="og:image" content="$site/assets/img/product/dashboard.webp">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$(Esc (Plain $p.title))">
<meta name="twitter:description" content="$(Esc (Plain $p.desc))">
<meta name="theme-color" content="#4B5158">
<link rel="icon" type="image/png" href="/assets/img/brand/ca-vault-icon.png">
<script>document.documentElement.className='js';try{var t=localStorage.getItem('cv-theme');if(t){document.documentElement.setAttribute('data-theme',t)}}catch(e){}</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700&family=Nunito:wght@400;600;700;800;900&display=swap">
<link rel="stylesheet" href="/assets/css/site.css">
<script type="application/ld+json">$ld</script>
</head>
<body class="$bodyClass">
<div class="loader" id="page-loader" role="status" aria-label="Loading CA-Vault">
  <div class="loader__dial"><img src="/assets/img/brand/ca-vault-mark.png" width="134" height="166" alt=""></div>
  <p>Opening the vault&hellip;</p>
</div>
<script>(function(){var r=document.documentElement,done=function(){r.classList.add('is-loaded');setTimeout(function(){var l=document.getElementById('page-loader');if(l){l.hidden=true}},600)};if(document.readyState==='complete'){done()}else{window.addEventListener('load',done);setTimeout(done,6000)}})();</script>
<a class="skip" href="#main">Skip to content</a>
$header
<main id="main">
$body
</main>
$($partials['footer'])
<a class="sticky-cta" href="/book-demo/" data-event="demo_cta_click" data-loc="sticky-mobile">Book a Demo</a>
<script src="/assets/js/site.js" defer></script>
</body>
</html>
"@
  if ($html -match '\{\{[^}]+\}\}') { throw "Unexpanded macro in $($p.path): $($Matches[0])" }
  if (-not $p.noindex -and $p.path -ne '/404.html') {
    $heads = @()
    foreach ($m in [regex]::Matches($body, '(?s)<(h1|h2|h3|summary|dt)[^>]*>(.*?)</\1>')) { $heads += (Plain $m.Groups[2].Value) }
    $sec = 'Page'; if ($crumbs.Count -gt 1) { $sec = Plain $crumbs[1].name }; if ($isHome) { $sec = 'Home' }
    $searchIndex += @{ t = ((Plain $p.title) -replace '\s*\|\s*CA-Vault.*$', ''); d = (Plain $p.desc); u = $p.path; s = $sec; k = ($heads -join ' | ') }
  }
  if ($p.path -eq '/404.html') { $file = Join-Path $out '404.html' }
  else { $file = Join-Path $out (($p.path.TrimStart('/') -replace '/', '\') + 'index.html') }
  WriteText $file $html
}

WriteText (Join-Path $out 'search.json') (Json $searchIndex)

# ---------- sitemap + link check ----------
$sm = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + "`n"
foreach ($p in ($pages | Sort-Object { $_.path })) {
  if ($p.noindex -or $p.path -eq '/404.html') { continue }
  $sm += "  <url><loc>$site$($p.path)</loc><lastmod>$today</lastmod></url>`n"
}
WriteText (Join-Path $out 'sitemap.xml') ($sm + '</urlset>' + "`n")

$broken = @{}
Get-ChildItem $out -Recurse -Filter *.html | ForEach-Object {
  $t = ReadText $_.FullName
  foreach ($m in [regex]::Matches($t, 'href="(/[^"#?]*)')) {
    $h = $m.Groups[1].Value
    if ($h -like '/assets/*') { if (!(Test-Path (Join-Path $out $h.TrimStart('/')))) { $broken[$h] = $_.Name }; continue }
    if (-not $byPath.ContainsKey($h)) { $broken[$h] = $_.FullName.Substring($out.Length) }
  }
}
"Built $($pages.Count) pages -> $out"
if ($broken.Count) { "BROKEN INTERNAL LINKS:"; $broken.GetEnumerator() | ForEach-Object { "  $($_.Key)   (first seen in $($_.Value))" } }
else { 'Internal links OK' }

# ---------- optional sub-path hosting (e.g. GitHub Pages project sites) ----------
# -Base '/repo-name' prefixes every root-absolute URL so the site works under https://user.github.io/repo-name/.
WriteText (Join-Path $out '.nojekyll') ''
if ($Base) {
  $Base = '/' + $Base.Trim('/')
  Get-ChildItem $out -Recurse -Filter *.html | ForEach-Object {
    $t = ReadText $_.FullName
    $t = [regex]::Replace($t, '(href|src|action)="/(?!/)', ('$1="' + $Base + '/'))
    WriteText $_.FullName $t
  }
  "Applied base path $Base"
}
