param (
    [Parameter(Mandatory = $true)]
    [ArgumentCompleter({ MyArgumentCompleter @args })]
    $SourceDirectory
)

$outputPath = ".\out\settings.ows"
New-Item $outputPath -Force

$sharedContent = Get-Content .\settings.ows
$modesFile = Join-Path $SourceDirectory "modes.txt"
$output = $sharedContent

if (Test-Path $modesFile) {
    $modesContent = Get-Content $modesFile

    if ($sharedContent[0] -eq "settings" -and $sharedContent[1] -eq "{") {
        $output = $output[0..1] + ($modesContent | ForEach-Object { "`t$_" }) + "" + $output[2..($output.Length - 1)]
    }
    else {
        throw;
    }
}

$mapSpecificSettingsFile = Join-Path $SourceDirectory "settings.ows"

if (Test-Path $mapSpecificSettingsFile) {
    $mapSpecificSettingsContent = Get-Content $mapSpecificSettingsFile
    $output += $mapSpecificSettingsContent
}

Set-Content $outputPath $output

function MyArgumentCompleter {
    param ( $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters )

    $possibleValues = Get-ChildItem . -Directory | Select-Object Name

    $possibleValues | Where-Object {
        $_ -like "$wordToComplete*"
    }
}