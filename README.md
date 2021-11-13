# MigrateBitlockerEncryptionSCCM

Script PowerShell permettant d'automatiser la migration et le changement du type de chiffrement Bitlocker sur un environnement où Bitlocker est déjà déployé. 
Ces scripts sont à importer dans une Configuration Items (SCCM / MEMCM). 

Deux scripts sont utilisés : 
- Get-OldBitlockerEncryption.ps1 -> Le script de détection utilisé par la CI SCCM
- Remove-OldBitlockerEncryption.ps1 -> Le script de remédiation utilisé par la CI SCCM

Modifiez la variable <b>$newBitlockerEncryption</b> pour définir la nouvelle méthode de chiffrement utilisée dans votre environnement. 

Un article détaillant l'implémentation est disponible sur le blog : 
https://tobeadmin.com/baseline-sccm-migration-chiffrement-bitlocker-existant
