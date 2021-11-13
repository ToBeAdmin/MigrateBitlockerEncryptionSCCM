<#
.SYNOPSIS
  Remediation Script for Bitlocker Encryption on device. Used by SCCM Configuration Item.
.DESCRIPTION
  List Get-BitLockerVolume. If current Bitlocker Encryption not match with new Bitlocker encryption, SCCM tags the machine as non-compliant
  Auto-remediation Enabled.
  Auto-Remediation = Decryption the old Bitlocker Encryption
.PARAMETER
    No parameters
.INPUTS
  No input
.OUTPUTS
  Log file stored in C:\Windows\Logs\SCCMBaseline_RemediationMigrationBitlocker.log
.NOTES
  Version:        1.0
  Author:         Jeremy BEITONE - ToBeAdmin.com
  Creation Date:  05/01/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
  Computer not have a Bitlocker encryption XtsAes256 = This remediation script is started and remove old bitlocker encryption
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Logs"
$sLogName = "SCCMBaseline_RemediationMigrationBitlocker.log"
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

#-----------------------------------------------------------[Execution Main Script]-----------------------------------------------------------

Write-Logs -Initialize # Initialize logs file
Write-Logs -Message "Get-BitlockerVolume function will start..." # Create entry in logs file

# Get Bitlocker Volume in the computer
$GetBitlockerVolume = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

Write-Logs -Message "Detect if computer get a C:\ with Bitlocker Encryption..." # Create entry in logs file

# If C:\ encryption exist
if($GetBitlockerVolume){

    # Get property of GetBitlockerVolume
    $EncryptionMethod = $GetBitlockerVolume.EncryptionMethod
    $ComputerName = $GetBitlockerVolume.ComputerName
    
    # Create entry in logs file
    Write-Logs -Message "Bitlocker Encryption found for C:\ ..." 
    Write-Logs -Message "Bitlocker Encryption method is $EncryptionMethod."

    # If Encryption Method not XtsAes256 (Example : XtsAes128)
    # Computer is Not Compliante
    if($EncryptionMethod -ne "$newBitlockerEncryption"){
        
        Write-Logs -Message "Bitlocker Decryption will start ..." # Create entry in logs file
        
        # Try Disable old Bitlocker Encryption
        try {
            # Disable Old Bitlocker Encryption
            Disable-BitLocker -MountPoint "C:" -ErrorAction Stop 
            
            # Create entry in logs file
            Write-Logs -Message "Bitlocker Encryption method mandatory by ToBeAdmin Corporation is $newBitlockerEncryption." # Create entry in logs file
            Write-Logs -Message "Bitlocker Decryption $EncryptionMethod has been started..."
            Write-Logs -Message "Remediation of Bitlocker Volume ended."
            Write-Logs -Message "Bitlocker Decryption is in progress... "
            Write-Logs -Message "Bitlocker policy will be applied by SCCM when decryption will be finished."
        }
        # Error when disable old Bitlocker Encryption
        catch {
            # Create entry in logs file
            $ErrorMsg = $Error[0]
            Write-Logs -Message "Bitlocker Decryption $EncryptionMethod ERROR ..." 
            Write-Logs -Message "$ErrorMsg"
        }
    }
    # No action needed
    else { 
        Write-Logs -Message "No action needed. Computer is compliante."
    }
}