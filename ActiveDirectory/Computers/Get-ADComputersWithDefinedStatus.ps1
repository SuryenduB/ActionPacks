﻿#Requires -Version 5.0
#Requires -Modules ActiveDirectory

<#
    .SYNOPSIS
         Lists computers where disabled or inactive
    
    .DESCRIPTION  

    .NOTES
        This PowerShell script was originally developed for ScriptRunner and has been adapted for a non-ScriptRunner environment.

    .COMPONENT
        Requires Module ActiveDirectory
    	
    .Parameter OUPath
        Specifies the AD path
        [sr-de] Active Directory Pfad

    .Parameter DomainAccount
        Active Directory Credential for remote execution on jumphost without CredSSP
        [sr-de] Active Directory-Benutzerkonto für die Remote-Ausführung ohne CredSSP        

    .Parameter Disabled
        Shows the disabled computers
        [sr-de] Deaktivierte Computer anzeigen
    
    .Parameter InActive
        Shows the inactive computers
        [sr-de] Inaktive Computer anzeigen
    
    .Parameter DomainName
        Name of Active Directory Domain
        [sr-de] Name der Active Directory Domäne
        
    .Parameter SearchScope
        Specifies the scope of an Active Directory search
        [sr-de] Gibt den Suchumfang einer Active Directory-Suche an
    
    .Parameter AuthType
        Specifies the authentication method to use
        [sr-de] Gibt die zu verwendende Authentifizierungsmethode an
#>

param(
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$OUPath,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [switch]$Disabled,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [switch]$InActive,
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [PSCredential]$DomainAccount,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$DomainName,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('Base','OneLevel','SubTree')]
    [string]$SearchScope='SubTree',
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('Basic', 'Negotiate')]
    [string]$AuthType="Negotiate"
)

Import-Module ActiveDirectory

try{
    $resultMessage = @()
    [hashtable]$cmdArgs = @{'ErrorAction' = 'Stop'
                            'AuthType' = $AuthType
                            }
    if($null -ne $DomainAccount){
        $cmdArgs.Add("Credential", $DomainAccount)
    }
    if([System.String]::IsNullOrWhiteSpace($DomainName)){
        $cmdArgs.Add("Current", 'LocalComputer')
    }
    else {
        $cmdArgs.Add("Identity", $DomainName)
    }
    $Domain = Get-ADDomain @cmdArgs

    $cmdArgs = @{'ErrorAction' = 'Stop'
                'AuthType' = $AuthType
                'ComputersOnly' = $null
                'Server' = $Domain.PDCEmulator
                'SearchBase' = $OUPath 
                'SearchScope' = $SearchScope
                }
    if($null -ne $DomainAccount){
        $cmdArgs.Add("Credential", $DomainAccount)
    }
    if($Disabled -eq $true){
        $computers = Search-ADAccount @cmdArgs -AccountDisabled  `
             | Select-Object DistinguishedName, SAMAccountName | Sort-Object -Property SAMAccountName
        if($computers){
            foreach($itm in  $computers){
                $resultMessage = $resultMessage + ("Disabled: " + $itm.DistinguishedName + ';' +$itm.SamAccountName)
            }
            $resultMessage = $resultMessage + ''  
        }
    }
    if($InActive -eq $true){
        $computers = Search-ADAccount @cmdArgs -AccountInactive `
            -SearchBase $OUPath -SearchScope $SearchScope | Select-Object DistinguishedName, SAMAccountName | Sort-Object -Property SAMAccountName
        if($computers){
            foreach($itm in  $computers){
            $resultMessage = $resultMessage + ("Inactive: " + $itm.DistinguishedName + ';' +$itm.SamAccountName)            
            }
        }
    } 
    
    Write-Output $resultMessage
}
catch{
    throw
}
finally{
}