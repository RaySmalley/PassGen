### Password Generator ###
### Ray Smalley        ###
### Created 01.29.18   ###
### Updated 08.01.24   ###


# Disable progress bar for faster downloads
$global:ProgressPreference = 'SilentlyContinue'

# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create an instance of the Random class
$Random = New-Object System.Random

# Define the log file path
$LogFilePath = "$env:TEMP\PassGen.log"

# Log file retention function
function CheckLogSize {
    # Check the size of the log file and overwrite it if it's larger than 1 MB
    if ((Get-Item $LogFilePath -ErrorAction SilentlyContinue).Length -gt 1MB) {
        Clear-Content $LogFilePath
    }
}

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

# Helper function to set clipboard with retry logic
function Set-ClipboardWithRetry {
    param (
        [string]$Content,
        [int]$MaxRetries = 5,
        [int]$DelaySeconds = 1
    )

    $RetryCount = 0
    $Success = $false

    while (-not $Success -and $RetryCount -lt $MaxRetries) {
        try {
            Set-Clipboard $Content
            $Success = $true
        } catch {
            $RetryCount++
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    return $Success
}

# Download the word list
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
        [ValidateScript({
            if ($_ -is [int] -and $_ -gt 0) {
                $true
            } else {
                throw "The parameter Size must be a positive integer."
            }
        })][Int]$Size = 12,
        [ValidatePattern('[ULNS]')][Char[]]$CharSets = "ULNS",
        [Char[]]$Exclude
    )

    # Define character sets
    $TokenSets = @{
        U = [Char[]]'ABCDEFGHJKLMNPQRSTUVWXYZ'
        L = [Char[]]'abcdefghijkmnopqrstuvwxyz'
        N = [Char[]]'23456789'
        S = [Char[]]'!@#$%^&*()-+=.:;<>?_'
    }

    $Chars = New-Object Char[] $Size
    $TokensSet = @()

    $CharSets | ForEach {
        $Tokens = $TokenSets."$_" | ForEach {If ($Exclude -cNotContains $_) {$_}}
        If ($Tokens) {
            $TokensSet += $Tokens
            If ($_ -cle [Char]"Z") {$Chars[0] = $Tokens[$Random.Next(0, $Tokens.Count)]; $i = 1} # Character sets defined in upper case are mandatory
        }
    }

    # Fill the array with random characters from $TokensSet
    for (; $i -lt $Size; $i++) {
        $Chars[$i] = $TokensSet[$Random.Next(0, $TokensSet.Count)]
    }

    # Define a function to shuffle an array
    function Shuffle-Array {
        param([array]$arr)

        $n = $arr.Count
        while ($n -gt 1) {
            $n--
            $i = $Random.Next($n + 1)
            $temp = $arr[$i]
            $arr[$i] = $arr[$n]
            $arr[$n] = $temp
        }

        return ,$arr
    }

    # Use the Shuffle-Array function to shuffle $Chars
    $Chars = Shuffle-Array $Chars

    # Join the shuffled characters to form the password
    $Password = $Chars -Join ""

    # Show top on first run
    if (!$RunOnce) {
        Write-Host "Tip: You can specify length and characters (Example: pg 16 LUNS)" -ForegroundColor Magenta
    }
    $global:RunOnce = $true

    # Copy password to clipboard
    $Success = Set-ClipboardWithRetry -Content $Password
    if (-not $Success) {
        Write-Host "Failed to set clipboard after multiple attempts. Please try again." -ForegroundColor Red
    } else {
        # Log passwords
        CheckLogSize
        Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $Password `n" -Path $LogFilePath
    
        # Output
        Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
        Write-Host "$Password"`n -ForegroundColor Red
    }
}

# 3 Word Password
function pgw {
    $FirstWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $SecondWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $ThirdWord = (Get-Culture).TextInfo.ToTitleCase($(GetRandomWord))
    $Password = "$FirstWord-$SecondWord-$ThirdWord"
    $Success = Set-ClipboardWithRetry -Content $Password
    if (-not $Success) {
        Write-Host "Failed to set clipboard after multiple attempts. Please try again." -ForegroundColor Red
    } else {
        CheckLogSize
        Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $FirstWord-$SecondWord-$ThirdWord" -Path $env:TEMP\PassGen.log
        Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
        Write-Host $FirstWord -ForegroundColor Red -NoNewline
        Write-Host - -ForegroundColor White -NoNewline
        Write-Host $SecondWord -ForegroundColor Yellow -NoNewline
        Write-Host - -ForegroundColor White -NoNewline
        Write-Host $ThirdWord`n -ForegroundColor Green
    }
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
    $Password = $First + $Second + $Third + $Fourth
    $Success = Set-ClipboardWithRetry -Content $Password
    if (-not $Success) {
        Write-Host "Failed to set clipboard after multiple attempts. Please try again." -ForegroundColor Red
    } else {
        CheckLogSize
        Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $FirstWord$Symbol$SecondWord$Number" -Path $env:TEMP\PassGen.log
        Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
        Write-Host $First -ForegroundColor Red -NoNewline
        Write-Host $Second -NoNewline -ForegroundColor White
        Write-Host $Third -ForegroundColor Yellow -NoNewline
        Write-Host $Fourth`n -ForegroundColor Green
    }
}

# Monty Python Quote password
Download -Name MontyPythonQuotes -URL https://github.com/RaySmalley/Packages/raw/main/MontyPythonQuotes.txt -Quiet -Force

function pgmp {
    $Password = Get-Content $MontyPythonQuotesOutput | Get-Random
    $Success = Set-ClipboardWithRetry -Content $Password
    if (-not $Success) {
        Write-Host "Failed to set clipboard after multiple attempts. Please try again." -ForegroundColor Red
    } else {
        CheckLogSize
        Add-Content -Value "$(Get-Date -Format 'MM/dd/yyyy - hh:mm:ss tt'): $Password" -Path $env:TEMP\PassGen.log
        Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
        Write-Host $Password`n -ForegroundColor Yellow
    }
}