### Password Generator ###
### Ray Smalley        ###
### Created 2018       ###
### Updated 10.28.23   ###


# Disable progress bar for faster downloads
$global:ProgressPreference = 'SilentlyContinue'

# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download function
function Download {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$URL,
	    [Parameter(Mandatory)][string]$Name,
	    [Parameter()][string]$Filename = $(if ($URL -match "\....$") {(Split-Path $URL -Leaf)}),
        [Parameter()][string]$OutputPath = $env:TEMP,
        [Parameter()][switch]$Force,
        [Parameter()][switch]$Quiet
	)
    if (!$Filename) {
        Write-Warning "Filename parameter needed. Download failed."
        Write-Host
        Break
    }
    $Output = $OutputPath + "\$Filename"
    $OutputName = $Name -replace ' ',''
    $FriendlyName = $Name -replace ' ','' -csplit '(?=[A-Z])' -ne '' -join ' '
    $Error.Clear()
    if ($URL -match "php") {$URL = (Invoke-WebRequest $URL).Content | Select-String -Pattern "href=`"(.*/$Filename)`"" | ForEach-Object { $_.Matches.Groups[1].Value }}
    if (!(Test-Path $Output) -or ($Force -eq $true)) {
        if (!$Quiet) {Write-Host "Downloading $FriendlyName..."`n}
        (New-Object System.Net.WebClient).DownloadFile($URL, $Output)
        if ($Error.count -gt 0) {Write-Host "Retrying..."`n; $Error.Clear(); (New-Object System.Net.WebClient).DownloadFile($URL, $Output)}
        if ($Error.count -gt 0) {Write-Warning "$Name download failed";Write-Host}
    } else {
        if (!$Quiet) {Write-Host "$FriendlyName already downloaded. Skipping..."`n}
    }
    New-Variable -Name $OutputName"Output" -Value $Output -Scope Global -Force
}

Download -Name WordList -URL https://github.com/RaySmalley/Packages/raw/main/WordList.txt -Quiet -Force
$WordList = Get-Content $WordListOutput

# Get random word function
function GetRandomWord {
    do {
        $Word = Get-Random $WordList
    } while ($Word.Length -le 4 -or $Word.Length -ge 8)
    return $Word
}

# Random String Password
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

# 3 Word Password
function pgw {
    $FirstWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $SecondWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $ThirdWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    Set-Clipboard $FirstWord-$SecondWord-$ThirdWord
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $FirstWord-$SecondWord-$ThirdWord" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host $FirstWord -ForegroundColor Red -NoNewline
    Write-Host - -ForegroundColor White -NoNewline
    Write-Host $SecondWord -ForegroundColor Yellow -NoNewline
    Write-Host - -ForegroundColor White -NoNewline
    Write-Host $ThirdWord`n -ForegroundColor Green
}

# Easy Password
function pge {
    $FirstWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $SecondWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $Symbol = @('@','!','#','$','%','^','&','*','-','_','=','+',';',':','<','>','.','?','/','~') | Get-Random
    $Number = Get-Random -Minimum 1 -Maximum 10
    $Jumble = @($Number, $Symbol) | Get-Random -Count 2
    $First = $FirstWord
    $Second = $Jumble[0]
    $Third = $SecondWord
    $Fourth = $Jumble[1]
    Set-Clipboard $First$Second$Third$Fourth
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $FirstWord$Symbol$SecondWord$Number" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host $First -ForegroundColor Red -NoNewline
    Write-Host $Second -NoNewline -ForegroundColor White
    Write-Host $Third -ForegroundColor Yellow -NoNewline
    Write-Host $Fourth`n -ForegroundColor Green
}

# Monty Python
Download -Name MontyPythonQuotes -URL https://github.com/RaySmalley/Packages/raw/main/MontyPythonQuotes.txt -Quiet -Force
$MPQList = Get-Content $MontyPythonQuotesOutput

function pgmp {
    $Quote = $MPQList | Get-Random
    Set-Clipboard $Quote
    Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $Quote" -Path $env:TEMP\PassGen.log
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host $Quote`n -ForegroundColor Yellow
}