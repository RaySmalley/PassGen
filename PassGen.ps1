### Password Generator ###
### Ray Smalley        ###
### 2018               ###

# Disable progress bar for faster downloads
$global:ProgressPreference = 'SilentlyContinue'

# Download function
function Download {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$URL,
	    [Parameter(Mandatory)][string]$Name,
	    [Parameter()][string]$Filename = $(if ($URL -match "\....$") {(Split-Path $URL -Leaf)}),
        [Parameter()][string]$OutputPath = $env:TEMP
	)
    if (-Not($Filename)) {
        Write-Warning "Filename parameter needed. Download failed."
        Write-Host
        Break
    }
    $Output = $OutputPath + "\$Filename"
    #$Name = $Name -csplit '(?=[A-Z])' -ne '' -join ' '
    #Write-Host "Downloading $Name..."`n
    $Error.Clear()
    if (!(Test-Path $Output)) {(New-Object System.Net.WebClient).DownloadFile($URL, $Output)}
    if ($Error.count -gt 0) {Write-Host "Retrying..."`n; $Error.Clear(); (New-Object System.Net.WebClient).DownloadFile($URL, $Output)}
    if ($Error.count -gt 0) {Write-Warning "$Name download failed";Write-Host}
    New-Variable -Name $Name"Output" -Value $Output -Scope Global -Force
}

Download -Name WordList -URL https://github.com/RaySmalley/Packages/raw/main/WordList.txt
$WordList = Get-Content $WordListOutput

# Random string
function pg {
    Param(
        [ValidateRange(1,99999)][Int]$Size = 12,
        [ValidatePattern('[ULNS]')][Char[]]$CharSets = "ULNS",
        [Char[]]$Exclude
    )
    $Chars = @(); $TokenSet = @()
    If (!$TokenSets) {$Global:TokenSets = @{
        U = [Char[]]'ABCDEFGHJKLMNPQRSTUVWXYZ'
        L = [Char[]]'abcdefghijkmnopqrstuvwxyz'
        N = [Char[]]'23456789'
        S = [Char[]]'!@#$%^&*()-+=.:;<>?_'
    }}
    $CharSets | ForEach {
        $Tokens = $TokenSets."$_" | ForEach {If ($Exclude -cNotContains $_) {$_}}
        If ($Tokens) {
            $TokensSet += $Tokens
            If ($_ -cle [Char]"Z") {$Chars += $Tokens | Get-Random}             # Character sets defined in upper case are mandatory
        }
    }
    While ($Chars.Count -lt $Size) {$Chars += $TokensSet | Get-Random}
    $PW = ($Chars | Sort-Object {Get-Random}) -Join ""                                # Mix the (mandatory) characters
    if (!$RunOnce) {
        Write-Host "Tip: You can specify length and characters (Example: pg 16 LUNS)" -ForegroundColor Magenta
    }
    $global:RunOnce = $true
    Set-Clipboard $PW
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $PW" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host "$PW"`n -ForegroundColor Red
}

# 3 Words
function pgw {
    $FirstWord = (Get-Culture).TextInfo.ToTitleCase($(Get-Random ($WordList | where {$_.Length -gt 4 -and $_.Length -lt 8})))
    $SecondWord = (Get-Culture).TextInfo.ToTitleCase($(Get-Random ($WordList | where {$_.Length -gt 4 -and $_.Length -lt 8})))
    $ThirdWord = (Get-Culture).TextInfo.ToTitleCase($(Get-Random ($WordList | where {$_.Length -gt 4 -and $_.Length -lt 8})))
    Set-Clipboard $FirstWord-$SecondWord-$ThirdWord
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $FirstWord-$SecondWord-$ThirdWord" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host $FirstWord -ForegroundColor Red -NoNewline
    Write-Host - -ForegroundColor White -NoNewline
    Write-Host $SecondWord -ForegroundColor Yellow -NoNewline
    Write-Host - -ForegroundColor White -NoNewline
    Write-Host $ThirdWord`n -ForegroundColor Green
}

# Easy
function pge {
    $FirstWord = (Get-Culture).TextInfo.ToTitleCase($(Get-Random ($WordList | where {$_.Length -gt 4 -and $_.Length -lt 8})))
    $SecondWord = (Get-Culture).TextInfo.ToTitleCase($(Get-Random ($WordList | where {$_.Length -gt 4 -and $_.Length -lt 8})))
    $Symbol = @('@','!','#','$','%','^','&','*','-','_','=','+',';',':','<','>','.','?','/','~') | Get-Random
    $Number = Get-Random -Minimum 1 -Maximum 10
    Set-Clipboard $FirstWord$Symbol$SecondWord$Number
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $FirstWord$Symbol$SecondWord$Number" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host $FirstWord -ForegroundColor Red -NoNewline
    Write-Host $Symbol -NoNewline -ForegroundColor White
    Write-Host $SecondWord -ForegroundColor Yellow -NoNewline
    Write-Host $Number`n -ForegroundColor Green
}

# Monty Python
Download -Name MontyPythonQuotes -URL https://github.com/RaySmalley/Packages/raw/main/MontyPythonQuotes.txt
$MPQList = Get-Content $MontyPythonQuotesOutput

function pgmp {
    $Quote = $MPQList | Get-Random
    Set-Clipboard $Quote
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $Quote" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host $Quote`n -ForegroundColor Yellow
}