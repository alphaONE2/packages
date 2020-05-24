$exitCode = 0

$root = Join-Path $PWD 'files'
Get-ChildItem $root -Recurse -Filter '*.lua' |
  ForEach-Object {
    Invoke-Expression -ErrorVariable err "&tools/luajit -b `"$_`" -" *>$null
    if ($LASTEXITCODE -ne 0) {
      $err = "$err".Replace($root, '.')
      Write-Host -ForegroundColor Red $err
      $script:exitCode = 1
    }
  }

exit $exitCode
