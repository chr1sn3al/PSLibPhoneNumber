# Base path to the 'lib' directory within your module directory
$libBasePath = Join-Path $PSScriptRoot "lib"

# Find all versioned subdirectories for 'libphonenumber-csharp'
$libPhoneNumberDirs = Get-ChildItem -Path $libBasePath -Directory | Where-Object { $_.FullName -like '*libphonenumber-csharp*' }

if ($libPhoneNumberDirs.Count -eq 0) {
    Write-Error "libphonenumber-csharp library not found in $libBasePath."
    return
}

# Extract and sort the versioned directories to find the latest one
$latestVersionDir = $libPhoneNumberDirs | Sort-Object Name -Descending | Select-Object -First 1

# Assuming the DLL is named 'phoneNumbers.dll' and directly within the versioned directory (adjust if the structure is different)
$latestDllPath = Join-Path $latestVersionDir.FullName "\lib\netstandard2.0\phoneNumbers.dll"

if (-Not (Test-Path $latestDllPath)) {
    Write-Error "phoneNumbers.dll not found in expected location: $latestDllPath."
    return
}

write-host $latestDllPath
Add-Type -Path $latestDllPath

function Get-LibPhoneNumber {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PhoneNumber,

        [Parameter(Mandatory = $false)]
        [string]$RegionCode = "US"
    )

    try {
        $phoneUtil = [PhoneNumbers.PhoneNumberUtil]::GetInstance()
        $numberProto = $phoneUtil.Parse($PhoneNumber, $RegionCode)
        $isValid = $phoneUtil.IsValidNumber($numberProto)
        $isPossible = $phoneUtil.IsPossibleNumber($numberProto)
        $internationalFormat = $phoneUtil.Format($numberProto, [PhoneNumbers.PhoneNumberFormat]::INTERNATIONAL)
        $nationalFormat = $phoneUtil.Format($numberProto, [PhoneNumbers.PhoneNumberFormat]::NATIONAL)
        $e164Format = $phoneUtil.Format($numberProto, [PhoneNumbers.PhoneNumberFormat]::E164)
        $rfc3966Format = $phoneUtil.Format($numberProto, [PhoneNumbers.PhoneNumberFormat]::RFC3966)
        $numberType = $phoneUtil.GetNumberType($numberProto).ToString()
        $regionCodeForNumber = $phoneUtil.GetRegionCodeForNumber($numberProto)
        $countryCodeForRegion = $phoneUtil.GetCountryCodeForRegion($RegionCode)
        $nationalSignificantNumber = $phoneUtil.GetNationalSignificantNumber($numberProto)
        
        # Geocoding and carrier information require additional libraries/utilities from libphonenumber
        # and might not be directly accessible via libphonenumber-csharp without implementing these features yourself
        # Example placeholders for geocoding and carrier info (commented out as they require additional implementation)
        # $location = Get-PhoneNumberLocation -PhoneNumber $numberProto -PhoneNumberUtil $phoneUtil
        # $carrier = Get-PhoneNumberCarrier -PhoneNumber $numberProto -PhoneNumberUtil $phoneUtil

        $resultObject = New-Object PSObject -Property @{
            IsValid = $isValid
            IsPossible = $isPossible
            Type = $numberType
            InternationalFormat = $internationalFormat
            NationalFormat = $nationalFormat
            E164Format = $e164Format
            RFC3966Format = $rfc3966Format
            RegionCode = $regionCodeForNumber
            CountryCode = $countryCodeForRegion
            NationalSignificantNumber = $nationalSignificantNumber
            # Location and carrier would be added here if implemented
        }

        return $resultObject
    }
    catch {
        Write-Error "An error occurred while processing the phone number: $_"
    }
}

Export-ModuleMember -Function Get-LibPhoneNumber


