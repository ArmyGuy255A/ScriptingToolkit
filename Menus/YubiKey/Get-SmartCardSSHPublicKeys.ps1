[CmdletBinding()]
param (
    [Parameter()]
    [Switch]
    $AsObject
)

$pkiProviders = @(
    "C:\Program Files\HID Global\ActivClient\acpkcs211.dll"
    "C:\Program Files\Yubico\Yubico PIV Tool\bin\libykcs11.dll"
)

foreach ($pkiProvider in $pkiProviders) {
    if (Test-Path $pkiProvider) {
        $results = ssh-keygen -D $pkiProvider -e
        
        if (!$results) {continue}

        $refinedResults = 1..$results.Count | foreach-object {
            [PSCustomObject]@{
                Name = ("Key {0}" -f $_)
                Value = $results[$_ - 1]
            }
        }

        if ($AsObject) {
            return $refinedResults
        } else {
            $ptResults = $refinedResults | Select-Object -ExpandProperty Value 
            return $ptResults -join "`n`n"

        }
    }
}

Write-Warning "No PKI Providers were installed on the system. Try installing the Yubico Piv Tool or ActivClient and rerun this script."
