# Rename this file to Settings.ps1
# Rename this file to Settings.ps1
######################### value replacement #####################

Get-VarsFromFile "D:\DATA\PROJECTS\GlobalVars\Mail.ps1"
[string]$Global:From           = ""          # Mail from:
[string]$Global:To             = ""          # Mail to:
[string]$Global:Subject        = ""          # Mail Subject:
[string]$Global:LogPath        = ""         
[string]$Global:ExternalIP     = ""         

######################### no replacement ########################
[int16] $Global:PingCount      = 3
