$schemaSet = New-Object -TypeName 'System.Xml.Schema.XmlSchemaSet'
$schemaSet.CompilationSettings.EnableUpaCheck = $false
$stream = $null
try {
  $stream = (Get-Item './manifest.xsd').OpenRead()
  [void]$schemaSet.Add([Xml.Schema.XmlSchema]::Read($stream, $null))
} finally {
  if ($null -ne $stream) {
    $stream.Dispose()
  }
  $stream = $null
}

$exitCode = 0

function Test-ManifestValid {
  param($name, $directory)

  Write-Host -NoNewline ("Validating manifest for package" +
    " `"$directory/$name`"...")
  $manifestPath = if (Join-Path $_.FullName '.native' |
                      Test-Path -PathType Container) {
    Join-Path $_.FullName 'manifest.tpl.xml'
  } else  {
    Join-Path $_.FullName 'manifest.xml'
  }

  if (-not (Test-Path -PathType Leaf $manifestPath)) {
    $filename = Split-Path $manifestPath -Leaf
    Write-Host -ForegroundColor Red `
      "`n`"$filename`" file is missing in package `"$name`"."
    $script:exitCode = 1
  } else {
    try{
      $manifest = New-Object -TypeName 'Xml'
      $manifest.Load($manifestPath)
      $manifest.Schemas = $schemaSet
      $manifest.Validate($null)
      if ($manifest.package.name -ne $name) {
        Write-Host -ForegroundColor Red `
          ("`n`Manifest name `"$($manifest.package.name)`"" +
          " does not match directory name `"$name`".")
        $script:exitCode = 1
      } else {
        $ok = switch ($directory) {
          'addons' {
            $manifest.package.type -eq 'addon'
          }
          'libraries' {
            $manifest.package.type -eq 'library' -or `
            $manifest.package.type -eq 'service'
          }
        }
        if ($ok -eq $false) {
          Write-Host -ForegroundColor Red `
            ("`n`Package `"$($name)`" has type" +
            " `"$($manifest.package.type)`"" +
            " but is in the `"$directory`" directory.")
          $script:exitCode = 1
        } else {
          Write-Host -ForegroundColor Green ' OK'
        }
      }
    } catch [System.Management.Automation.MethodInvocationException] {
      Write-Host ''
      Write-Host -ForegroundColor Red $_.Exception.InnerException.Message
      $script:exitCode = 1
    } catch {
      Write-Host ''
      Write-Host -ForegroundColor Red $_.Exception.Message
      $script:exitCode = 1
    }
  }
}

Get-ChildItem 'addons' |
  ForEach-Object {
    Test-ManifestValid $_.Name 'addons'
  }

Get-ChildItem 'libraries' |
  ForEach-Object {
    Test-ManifestValid $_.Name 'libraries'
  }

exit $exitCode
