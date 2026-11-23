# Mixeur Jovial : petit serveur local, sans installation (PowerShell, inclus dans Windows).
# Sert le dossier de l'outil sur http://localhost:8765/ (accessible uniquement depuis cet ordinateur),
# puis ouvre le navigateur. Fermer cette fenêtre arrête l'outil.

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path)).TrimEnd('\') + '\'
$mime = @{
  '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'; '.mjs' = 'text/javascript; charset=utf-8'
  '.wasm' = 'application/wasm'; '.json' = 'application/json; charset=utf-8'; '.css' = 'text/css; charset=utf-8'
  '.md' = 'text/plain; charset=utf-8'; '.txt' = 'text/plain; charset=utf-8'; '.svg' = 'image/svg+xml'
  '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.ico' = 'image/x-icon'
}

$listener = $null
foreach ($port in 8765..8775) {
  try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
    break
  } catch { $listener = $null }
}
if (-not $listener) { Write-Host "Impossible de démarrer le serveur local (ports 8765 à 8775 occupés)."; Read-Host "Entrée pour fermer"; exit 1 }

$url = "http://localhost:$port/"
Write-Host ""
Write-Host "  Mixeur Jovial est ouvert dans votre navigateur : $url"
Write-Host "  Laissez cette fenêtre ouverte pendant que vous utilisez l'outil. Fermez-la pour l'arrêter."
Write-Host ""
Start-Process $url

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($path.EndsWith('/')) { $path += 'index.html' }
    $file = [IO.Path]::GetFullPath((Join-Path $root ($path.TrimStart('/') -replace '/', '\')))
    if ($file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $file -PathType Leaf)) {
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $res.ContentType = $(if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' })
      $res.Headers.Add('Cache-Control', 'no-cache')
      $bytes = [IO.File]::ReadAllBytes($file)
      $res.ContentLength64 = $bytes.Length
      if ($ctx.Request.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
    } else {
      $res.StatusCode = 404
    }
  } catch {
    $res.StatusCode = 500
  } finally {
    $res.Close()
  }
}
