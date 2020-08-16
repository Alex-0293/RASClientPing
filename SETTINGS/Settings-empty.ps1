# Rename this file to Settings.ps1
######################### value replacement #####################

[string]$global:APP_SCRIPT_ADMIN_Login = ""          # AES Login value path.
[string]$global:APP_SCRIPT_ADMIN_Pass  = ""          # AES Password value path.
[string]$Global:SmtpServer             = ""          # SMTP server FQDN.
[string]$Global:From                   = ""          # Mail from:
[string]$Global:To                     = ""          # Mail to:
[string]$Global:Subject                = ""          # Mail Subject:
[string]$Global:LogPath                = ""         
[string]$Global:ExternalIP             = ""         

######################### no replacement ########################
[int16] $Global:PingCount      = 3


[bool] $Global:LocalSettingsSuccessfullyLoaded = $true

# Error trap
trap {
    $Global:LocalSettingsSuccessfullyLoaded = $False
    exit 1
}
