[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$artifactDirectory = Join-Path $PSScriptRoot 'artifacts'
[xml]$buildProperties = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Directory.Build.props') -Raw
$version = $buildProperties.Project.PropertyGroup.Version
$package = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Thunderstore/package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Invoke-DotNet {
    param([string[]]$Arguments)

    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Assert-PackageInputs {
    if ($version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
        throw 'Version must use the Thunderstore Major.Minor.Patch format.'
    }
    if ($package.name -cnotmatch '^[a-zA-Z0-9_]{1,128}$' -or $package.team -cnotmatch '^[a-zA-Z0-9_]+$') {
        throw 'Invalid Thunderstore package or team name.'
    }
    if ([string]::IsNullOrWhiteSpace($package.description) -or $package.description.Length -gt 250) {
        throw 'Thunderstore description must contain 1 to 250 characters.'
    }
    if ($package.community -ne 'resonite' -or @($package.categories).Count -eq 0) {
        throw 'Specify the Resonite community and upload categories in Thunderstore/package.json.'
    }
    foreach ($dependency in $package.dependencies) {
        if ($dependency -cnotmatch '^[a-zA-Z0-9_]+-[a-zA-Z0-9_]+-[0-9]+\.[0-9]+\.[0-9]+$') {
            throw "Invalid dependency string: $dependency"
        }
    }
    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    foreach ($file in @('README.md', 'Thunderstore/README.md', 'CHANGELOG.md')) {
        $text = [IO.File]::ReadAllText((Join-Path $PSScriptRoot $file), $utf8)
        if ([string]::IsNullOrWhiteSpace($text)) { throw "Empty package document: $file" }
    }
    $changelog = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'CHANGELOG.md'), $utf8)
    if ($changelog -notmatch ('(?m)^## ' + [regex]::Escape($version) + '\r?$')) {
        throw "Add a ## $version entry to CHANGELOG.md before packaging."
    }
    # PNG signature, IHDR chunk, and big-endian 256x256 dimensions. This also
    # works without System.Drawing on non-Windows PowerShell installations.
    $icon = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'icon.png'))
    if ($icon.Length -lt 24 -or
        [BitConverter]::ToString($icon, 0, 8) -ne '89-50-4E-47-0D-0A-1A-0A' -or
        [BitConverter]::ToString($icon, 12, 12) -ne '49-48-44-52-00-00-01-00-00-00-01-00') {
        throw 'icon.png must be a 256x256 PNG.'
    }
}

function New-ModArchive {
    param(
        [string]$ArchiveName,
        [System.Collections.IDictionary]$Manifest,
        [System.Collections.IDictionary]$Files
    )

    foreach ($file in $Files.Values) {
        if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing package file: $file" }
    }
    $archivePath = Join-Path $artifactDirectory $ArchiveName
    # Preserve the previous archive if writing the replacement fails.
    $temporaryPath = $archivePath + '.tmp'
    $stream = [IO.File]::Open($temporaryPath, [IO.FileMode]::Create)
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $writer = New-Object IO.StreamWriter($zip.CreateEntry('manifest.json').Open(), (New-Object Text.UTF8Encoding($false)))
        try { $writer.Write(($Manifest | ConvertTo-Json -Depth 4)) } finally { $writer.Dispose() }
        foreach ($entry in $Files.Keys) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $Files[$entry], $entry) | Out-Null
        }
    } finally {
        $zip.Dispose()
        $stream.Dispose()
    }
    Move-Item -LiteralPath $temporaryPath -Destination $archivePath -Force
    Get-Item -LiteralPath $archivePath | Select-Object Name, Length
}


function Assert-ModArchive {
    param(
        [string]$ArchivePath,
        [string]$PluginEntry,
        [bool]$HasManifest = $false,
        [bool]$IsGale = $false
    )
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $names = @($archive.Entries | ForEach-Object { $_.FullName })
        if ($names -cnotcontains $PluginEntry) { throw "Missing DLL: $PluginEntry" }
        $unexpectedDlls = @($names | Where-Object { $_ -like '*.dll' -and $_ -cne $PluginEntry })
        if ($unexpectedDlls.Count -ne 0) { throw "Unexpected bundled DLLs: $unexpectedDlls" }
        if (@($names | Where-Object { $_ -match '\\|(^|/)\.\.(/|$)' }).Count -ne 0) {
            throw 'ZIP entries must use safe forward-slash paths.'
        }
        if ($HasManifest) {
            foreach ($required in @('manifest.json', 'README.md', 'CHANGELOG.md', 'LICENSE', 'icon.png')) {
                if ($names -cnotcontains $required) { throw "Missing package entry: $required" }
            }
            $reader = New-Object IO.StreamReader($archive.GetEntry('manifest.json').Open())
            try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
            if ($manifest.name -cne $package.name -or $manifest.version_number -ne $version -or
                $manifest.website_url -cne $package.website_url -or $manifest.description -cne $package.description -or
                ($manifest.dependencies -join '|') -cne ($package.dependencies -join '|')) {
                throw 'Archive manifest does not match the package inputs.'
            }
            if ($IsGale -and $manifest.author -cne $buildProperties.Project.PropertyGroup.Authors) {
                throw 'Gale author metadata is missing or inconsistent.'
            }
        }
    } finally { $archive.Dispose() }
}

# Resolve global.json consistently, including when invoked from another directory.
Push-Location -LiteralPath $PSScriptRoot
try {
    Assert-PackageInputs
    $referencePath = & dotnet msbuild Bepis/SettingsSaveNow.Bepis.csproj -getProperty:ResonitePublicizedSharedReferencePath
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the engine reference path.' }
    $engineAssembly = Join-Path ($referencePath.Trim()) 'FrooxEngine.dll'
    Invoke-DotNet -Arguments @(
        'run', '--project', 'Tests/SettingsSaveNow.Tests.csproj',
        '--configuration', $Configuration, '--', $engineAssembly
    )
    New-Item -ItemType Directory -Path $artifactDirectory -Force | Out-Null
    foreach ($loader in @('Bepis', 'RML')) {
        # Prevent SDK publish archives from retaining previously copied dependencies.
        $publishRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "$loader/bin/publish"))
        $expectedPrefix = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (!$publishRoot.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Publish directory escaped the project root.'
        }
        if (Test-Path -LiteralPath $publishRoot) { Remove-Item -LiteralPath $publishRoot -Recurse -Force }
        Invoke-DotNet -Arguments @(
            'publish', "$loader/SettingsSaveNow.$loader.csproj", '--configuration', $Configuration,
            '-p:ResoniteInstallOnBuild=false', '-p:ResoniteGenerateReleaseArchive=true'
        )

        $archiveName = "SettingsSaveNow.$loader-$version-$Configuration.zip"
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot "$loader/bin/publish/$archiveName") -Destination $artifactDirectory -Force
        Get-Item -LiteralPath (Join-Path $artifactDirectory $archiveName) | Select-Object Name, Length

        if ($loader -eq 'Bepis') {
            # Thunderstore and Gale share package metadata. Version is generated
            # from Directory.Build.props; team/community/categories are upload settings.
            $manifest = [ordered]@{
                name = $package.name
                version_number = $version
                website_url = $package.website_url
                description = $package.description
                dependencies = @($package.dependencies)
            }
            $pluginDirectory = Join-Path $PSScriptRoot 'Bepis/bin/publish/mod/client/BepInEx/plugins/SettingsSaveNow'
            $dllPath = Join-Path $pluginDirectory 'SettingsSaveNow.dll'
            if ([Reflection.AssemblyName]::GetAssemblyName($dllPath).Version.ToString(3) -ne $version) {
                throw 'Published Bepis DLL version does not match Directory.Build.props.'
            }
            $files = [ordered]@{
                'LICENSE' = Join-Path $PSScriptRoot 'LICENSE'
                'icon.png' = Join-Path $PSScriptRoot 'icon.png'
                'README.md' = Join-Path $PSScriptRoot 'Thunderstore/README.md'
                'CHANGELOG.md' = Join-Path $PSScriptRoot 'CHANGELOG.md'
                'plugins/SettingsSaveNow/SettingsSaveNow.dll' = $dllPath
                'plugins/SettingsSaveNow/SettingsSaveNow.pdb' = Join-Path $pluginDirectory 'SettingsSaveNow.pdb'
            }
            New-ModArchive -ArchiveName "SettingsSaveNow.Thunderstore-$version-$Configuration.zip" -Manifest $manifest -Files $files

            # Flat local-import layout also exposes author metadata in Gale.
            $galeManifest = [ordered]@{}
            foreach ($key in $manifest.Keys) { $galeManifest[$key] = $manifest[$key] }
            $galeManifest['author'] = [string]$buildProperties.Project.PropertyGroup.Authors
            $galeFiles = [ordered]@{}
            foreach ($entry in $files.Keys) { $galeFiles[[IO.Path]::GetFileName($entry)] = $files[$entry] }
            New-ModArchive -ArchiveName "SettingsSaveNow.Gale-$version-$Configuration.zip" -Manifest $galeManifest -Files $galeFiles
        }
    }
    Assert-ModArchive -ArchivePath (Join-Path $artifactDirectory "SettingsSaveNow.Bepis-$version-$Configuration.zip") -PluginEntry 'BepInEx/plugins/SettingsSaveNow/SettingsSaveNow.dll'
    Assert-ModArchive -ArchivePath (Join-Path $artifactDirectory "SettingsSaveNow.RML-$version-$Configuration.zip") -PluginEntry 'rml_mods/SettingsSaveNow.dll'
    Assert-ModArchive -ArchivePath (Join-Path $artifactDirectory "SettingsSaveNow.Thunderstore-$version-$Configuration.zip") -PluginEntry 'plugins/SettingsSaveNow/SettingsSaveNow.dll' -HasManifest $true
    Assert-ModArchive -ArchivePath (Join-Path $artifactDirectory "SettingsSaveNow.Gale-$version-$Configuration.zip") -PluginEntry 'SettingsSaveNow.dll' -HasManifest $true -IsGale $true
    Write-Host 'PASS: all four distribution archives'
    Write-Host "Thunderstore upload: team=$($package.team), community=$($package.community), categories=$($package.categories -join ', ')"
} finally {
    Pop-Location
}
