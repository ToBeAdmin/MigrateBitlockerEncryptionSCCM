<#
.SYNOPSIS
  Script report for Bitlocker Encryption on device. Used by SCCM Configuration Item.
.DESCRIPTION
  List Get-BitLockerVolume. If current Bitlocker Encryption not match with new Bitlocker encryption, SCCM tags the machine as non-compliant
  Auto-remediation Enabled.
  Auto-Remediation = Decryption the old Bitlocker Encryption
.PARAMETER
    No parameters 
.INPUTS
  No input
.OUTPUTS
  Log file stored in C:\Windows\Logs\SCCMBaseline_AuditMigrationBitlocker.log
.NOTES
  Version:        1.0
  Author:         Jeremy BEITONE - ToBeAdmin.com
  Creation Date:  05/01/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
  Computer not have a Bitlocker encryption XtsAes256 = Script return false for SCCM (Non Compliante)
  Example : Computer have a Bitlocker encryption XtsAes128 = Script return false for SCCM (Non-Compliante)
  New Bitlocker Encryption : XtsAes256
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Logs"
$sLogName = "SCCMBaseline_AuditMigrationBitlocker.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#Bitlocker Encryption
$NewBitlockerEncryption = "XtsAes256"

#-----------------------------------------------------------[Functions]-------------------------------------------------------------
# Function Write-Logs : Create logs files and content
function Write-Logs(){
    Param (
		    [Parameter(Mandatory=$false)][switch]$Initialize,
            [Parameter(Mandatory=$false)][string]$LogsPath = $sLogFile,
		    [Parameter(Mandatory=$false)]$Message
    )

    [string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
    [string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()

    # First Step = Create Logs File if not exist
    if( (Test-Path -Path $LogsPath) -eq $false) { New-Item -Path $LogsPath -ItemType File -Force | Out-Null } 

    # Initialize Logs Content
    if($Initialize){
        $Line += "******************************************************************************* `r`n"
        $Line += "Initialization .... `r`n"
        $Line += "Script Version :  $sScriptVersion `r`n"
        $Line += "Date : $LogDate - $LogTime `r`n"
        $Line += "Computer : $env:COMPUTERNAME `r"

        # Add Line in File logs
        $Line | Out-File -FilePath $LogsPath -Encoding utf8 -Append -Force -NoClobber -Width 5000
    }
    # Main Logs Content
    if($Message){
        # Format Logs : Date - Hours : Message
        $Line = "$LogDate - $LogTime : $Message"
        # Add Line in File logs
        $Line | Out-File -FilePath $LogsPath -Encoding utf8 -Append -Force -NoClobber -Width 5000
    }
}
# Function SCCM-ComplianceState : Return script result for SCCM compliance state
Function SCCM-ComplianceState(){
    Param ( [Parameter(Mandatory=$true)][bool]$State )

    # IF OK (Compliante) return True
    if($State -eq $true) {Write-Logs -Message "SCCM Compliance Status : Computer compliante"; Write-Logs -Message "SCCM Compliance State will return True"; Write-Logs -Message "Script ended"; return $true}

    # IF NOK (Non Compliante) return False
    if($State -eq $false) {Write-Logs -Message "SCCM Compliance Status : Computer non compliante"; Write-Logs -Message "SCCM Compliance State will return False"; Write-Logs -Message "Script ended"; return $false}
}

#-----------------------------------------------------------[Execution Main Script]-----------------------------------------------------------

Write-Logs -Initialize # Initialize logs file
Write-Logs -Message "Get-BitlockerVolume function will start..." # Create entry in logs file

# Get Bitlocker Volume in the computer
$GetBitlockerVolume = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

Write-Logs -Message "Detect if computer get a C:\ with Bitlocker Encryption..." # Create entry in logs file

# If C:\ encryption existe
if($GetBitlockerVolume){
    # Get property of GetBitlockerVolume
    $EncryptionMethod = $GetBitlockerVolume.EncryptionMethod
    $ComputerName = $GetBitlockerVolume.ComputerName
    
    # Create entry in logs file
    Write-Logs -Message "Bitlocker Encryption found for C:\ ..." 
    Write-Logs -Message "Bitlocker Encryption method is $EncryptionMethod."

    # If Encryption Method is XtsAes256
    # Computer is Compliante
    if($EncryptionMethod -eq "$NewBitlockerEncryption"){
        $ComplianceState = $true
        Write-Logs -Message "Compliance status is $ComplianceState." # Create entry in logs file
        Write-Logs -Message "Restart a new Bitlocker encryption not mandatory." # Create entry in logs file
    }

    # ElseIf Encryption Method is another of $NewBitlockerEncryption (Example : XtsAes128)
    # Computer is Not Compliante
    elseif($EncryptionMethod -ne "$NewBitlockerEncryption"){
        $ComplianceState = $false
        Write-Logs -Message "Compliance status is $ComplianceState." # Create entry in logs file
        Write-Logs -Message "Restart a new Bitlocker encryption is mandatory." # Create entry in logs file
        Write-Logs -Message "Bitlocker Encryption method mandatory by ToBeAdmin corporation is $NewBitlockerEncryption." # Create entry in logs file
    }
}
# Else C:\ encryption not exist
else {
    Write-Logs -Message "Bitlocker Encryption not found for C:\ ..." # Create entry in logs file
    $ComplianceState = $true
    Write-Logs -Message "Compliance status is $ComplianceState." # Create entry in logs file
}

# Create entry in logs file
Write-Logs -Message "Detection of Bitlocker Volume ended"
Write-Logs -Message "Resolving result for SCCM compliance status will start..."

# Return results for SCCM Compliance State
if( $ComplianceState -eq $false ) { SCCM-ComplianceState -State $false } # Computer is not compliante : Old Bitlocker Encryption found
else { SCCM-ComplianceState -State $true } # Computer is compliante : Nothing Old bitlocker Encryption found or already on Aes256 encryption