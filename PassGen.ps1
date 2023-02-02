### Password Generator ###
### Ray Smalley        ###
### 2018               ###

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
    Set-Clipboard $PW
    Write-Host "Password added to clipboard: " -ForegroundColor Cyan -NoNewline
    Write-Host "$PW"`n -ForegroundColor Red
}