$exitCode = 0

$dir =  "$(Get-Location)"
Get-ChildItem -Recurse -Filter '*.lua' |
  ForEach-Object {
    Invoke-Expression -ErrorVariable err "&.tools/luajit -b `"$_`" -" *>$null
    if ($LASTEXITCODE -ne 0) {
      $err = "$err".Replace($dir, '.')
      #Write-Host -ForegroundColor Red $err
      $script:exitCode = 1
    }
  }

exit $exitCode
