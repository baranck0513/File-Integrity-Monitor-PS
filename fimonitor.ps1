function GetFileHash {
    param ($filepath)
    return Get-FileHash -Path $filepath -Algorithm SHA512
}

function RemoveBaseline {
    if (Test-Path -Path .\baseline.txt) {
        Remove-Item -Path .\baseline.txt
    }
}

function CollectBaseline {
    RemoveBaseline
    $files = Get-ChildItem -Path .\Files
    foreach ($file in $files) {
        $hash = GetFileHash $file.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}

function GetValidatedResponse {
    while ($true) {
        $response = Read-Host -Prompt "Please enter 'A' or 'B'"
        if ($response -eq 'A' -or $response -eq 'B') {
            return $response
        }
        Write-Host "Invalid input. Please enter 'A' or 'B'."
    }
}

Write-Host "What would you like to do?"
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"

$response = GetValidatedResponse

if ($response -eq "A") {
    CollectBaseline

} elseif ($response -eq "B") {
    $fileHashDict = @{}
    $fileHashes = Get-Content -Path .\baseline.txt

    foreach ($line in $fileHashes) {
        $split = $line.Split("|")
        $fileHashDict[$split[0]] = $split[1]
    }

    while ($true) {
        Start-Sleep -Seconds 1
        $files = Get-ChildItem -Path .\Files

        foreach ($file in $files) {
            $hash = GetFileHash $file.FullName

            if ($fileHashDict[$hash.Path] -eq $null) {
                Write-Host "$($hash.Path) is a new file!"
            } elseif ($fileHashDict[$hash.Path] -ne $hash.Hash) {
                Write-Host "$($hash.Path) has been modified!"
            }
        }

        foreach ($filePath in $fileHashDict.Keys) {
            if (-not (Test-Path -Path $filePath)) {
                Write-Host "$filePath has been deleted!"
            }
        }
    }
}
