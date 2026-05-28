<#
.SYNOPSIS
    Configura Windows Server como Domain Controller, GPOs e Scheduled Tasks
.DESCRIPTION
    - Instala AD Domain Services e promove a Domain Controller
    - Cria GPO para abrir Notepad no login
    - Cria Scheduled Task para reboot diario as 03:00
    - (Bonus) Cria OU de teste + usuario
    - (Bonus) GPO para restringir acesso ao C:\
#>

$domainName = "lab.local"
$netbiosName = "LAB"
$safeModePass = ConvertTo-SecureString "Admin@2026" -AsPlainText -Force

Write-Host "=== Instalando AD Domain Services ===" -ForegroundColor Green
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "=== Promovendo a Domain Controller ===" -ForegroundColor Green
Import-Module ADDSDeployment
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $safeModePass `
    -Force:$true

# O script continua APOS o reboot (segunda execucao)
# Para isso, criar um agendamento na primeira execucao

Write-Host "=== Servidor vai reiniciar para finalizar promocao ===" -ForegroundColor Yellow
Restart-Computer -Force
