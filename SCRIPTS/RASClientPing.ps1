$ImportResult = Import-Module AlexkUtils  -PassThru
if ($null -eq $ImportResult) {
    Write-Host "Module 'AlexkUtils' does not loaded!" -ForegroundColor red
    exit 1
}
else {
    $ImportResult = $null
}

#requires -version 3

#########################################################################
function Get-Workdir {
    if ($PSScriptRoot -eq "") {
        if ($PWD -ne "") {
            $MyScriptRoot = $PWD
        }        
        else {
            Write-Host "Where i am? What is my work dir?"
        }
    }
    else {
        $MyScriptRoot = $PSScriptRoot
    }
    return $MyScriptRoot
}
Function Get-StringToArray ($string) {
    $Array = @()
    $StringArray = $string -split "`n"
    foreach ($row in $StringArray) {
        if ($row -ne "") {
            $Array1 = @($Row -split ";")
            
            $FailFrom = $Array1[0].split("=")[1]
            if ($FailFrom -eq "") { $FailFrom = "Now" }

            $RepData = $Array1[1].split("=")[1].replace("}", "")
            $PSO = @([PSCustomObject]@{
                    FailFrom = $FailFrom
                    RepData  = $RepData
                })            
            $Array = $Array + $PSO
        }
    }
    return $Array
}
# Error trap
trap {
    Get-ErrorReporting $_
    exit 1
}
#########################################################################

Clear-Host

$MyScriptRoot = Get-Workdir

Get-VarsFromFile    "$MyScriptRoot\Vars.ps1"
Initialize-Logging   $MyScriptRoot "Latest"

[array]$ConArray = @()
$Date = Get-Date



#Get-RemoteAccessConnectionStatisticsSummary
#Get-RemoteAccessConnectionStatistics |select * | Out-GridView
$RASCons = Get-RemoteAccessConnectionStatistics | Select-Object Username, clientIpv4address, ClientExternalAddress | Sort-Object Username
$PrevRasCons = Import-Csv $Global:LogPath -Encoding UTF8
$Data = $null

foreach ($Con in $RASCons) {
    #Write-host ("Test " + $Con.Username[0])
    $pingRes = Test-Connection $Con.clientIpv4address -Count $Global:PingCount -Quiet
    if (!$pingRes) {
        $LastRes = $PrevRasCons | Where-Object { $_.clientIpv4address -eq $Con.clientIpv4address }
        if ($LastRes.ping -eq $false) {
            if ($LastRes.FailFrom -ne "") {
                $FailFrom = $LastRes.FailFrom
            }
            Else { $FailFrom = $LastRes.Date }
        }
        Else { $FailFrom = $date }
    }
    Else { $FailFrom = "" }

    $Data = [pscustomobject]@{
        Date                  = $Date;
        clientIpv4address     = $Con.clientIpv4address;
        ClientExternalAddress = $Con.ClientExternalAddress;
        Ping                  = $pingRes;
        FailFrom              = $FailFrom;
        Username              = $Con.Username[0];
        Repdata               = ($Con.Username[0].Substring(3, 3) + "... (" + ($Con.clientIpv4address -split ".")[3] + ")")        
    }
    $ConArray += $Data
}

$ConArray | Format-Table -AutoSize
$ConArray | Export-Csv -Path $Global:LogPath -Encoding UTF8

[array]$LastLog = @()
$LastLog = $ConArray | Where-Object { ($_.ping -eq $False) -and ($_.username -ne "AB\VPN") -and ($_.ClientExternalAddress -eq $ExternalIP)} | Format-Table -Property Date, FailFrom, Ping, Repdata  -AutoSize | Out-String
Write-Host ""
Write-Host "LastLog:"
$LastLog | Where-Object { ($_.ping -eq $False) -and ($_.username -ne "AB\VPN") -and ($_.ClientExternalAddress -eq $ExternalIP)   } | Format-Table -AutoSize 


if ($LastLog -ne "") {
    $LastLog1 = $ConArray | Where-Object { ($_.ping -eq $False) -and ($_.username -ne "AB\VPN") -and ($_.ClientExternalAddress -eq $ExternalIP)} | Select-Object Date, FailFrom, RepData   
    $PSO = @([PSCustomObject]@{
            FailFrom = $LastLog1[0].Date
            RepData  = ""
        })
    $LastLogArray = $PSO + (Get-StringToArray ($LastLog1 | Select-Object FailFrom, RepData)) 
    [string]$HTMLData = Get-HTMLTable $LastLogArray 
    [array]$ColNames = $LastLogArray[0].PSObject.Properties | Select-Object name

    $Body = Get-ContentFromHTMLTemplate  -HTMLData $HTMLData -ColNames $Colnames -HTMLTemplateFile "$MyScriptRoot\template.html" 
    $params = @{
        SmtpServer          = $Global:SmtpServer
        Subject             = $Global:Subject
        Body                = $Body
        HtmlBody            = $true
        From                = $Global:From
        To                  = $Global:To
        SSL                 = $true
    }
    if ($global:UseMailAuth) {
        $params.Add("User", (Get-VarFromAESFile $Global:GlobalKey1 $Global:MailUser))
        $params.Add("Pass", (Get-VarFromAESFile $Global:GlobalKey1 $Global:MailPass))
    }

    Send-Email @params
}  