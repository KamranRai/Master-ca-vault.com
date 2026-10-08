# Minimal local preview server for dist/ (no Node or Python required).
# Usage:  powershell -ExecutionPolicy Bypass -File serve.ps1 [-Port 4321]
param([int]$Port = 4321)
$root = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'dist'
$types = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.json'='application/json'; '.xml'='application/xml'; '.txt'='text/plain; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg'; '.webp'='image/webp'; '.svg'='image/svg+xml'; '.ico'='image/x-icon' }
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
"Serving $root at http://localhost:$Port/"
while ($l.IsListening) {
  $c = $l.GetContext()
  try {
    $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath)
    if ($p.EndsWith('/')) { $p += 'index.html' }
    $f = Join-Path $root ($p.TrimStart('/') -replace '/', '\')
    if ((Test-Path $f -PathType Container)) { $f = Join-Path $f 'index.html' }
    if (!(Test-Path $f -PathType Leaf)) { $c.Response.StatusCode = 404; $f = Join-Path $root '404.html' }
    $bytes = [IO.File]::ReadAllBytes($f)
    $ext = [IO.Path]::GetExtension($f).ToLower()
    if ($types.ContainsKey($ext)) { $c.Response.ContentType = $types[$ext] }
    $c.Response.Headers.Add('Cache-Control', 'no-store')
    $c.Response.ContentLength64 = $bytes.Length
    $c.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch { } finally { $c.Response.Close() }
}
