<#
.SYNOPSIS
    Import certificate files to the cert store
.DESCRIPTION
    Import a pfx certificate to the specified local certificate store
.PARAMETER PFXCertificatePath
    The cert file to import: defaults to all .pfx files in the current directory
.PARAMETER CertificateStorePath
    The certificate store path
.EXAMPLE
    PS C:> Import-EZPFXCertificate CodeSigning.pfx Cert:\CurrentUser\My
    
    Imports a certificate from a file to the current user's personal cert store
.EXAMPLE
    PS C:> Import-EZPFXCertificate CodeSigning.pfx Cert:\LocalMachine\TrustedPublisher
    
    Imports a certificate from a file to the machine's trusted publisher store.
    Scripts signed by that cert will now be trusted by all users on the machine.
.NOTES
  Source: http://poshcode.org/4420
#>
function Import-EZPFXCertificate
{ 
    [CmdletBinding()]PARAM( 
        # The cert file to import: defaults to all .pfx files in the current directory
        [Parameter(ValueFromPipelineByPropertyName=$true, Position=0)]
            [Alias("PSPath")][String]$PFXCertificatePath = "*.pfx", 
        # The certificate store path
        [Parameter(ValueFromPipelineByPropertyName=$true, Position=1)]
            [Alias("Target","Store")][String]$CertificateStorePath = "Cert:\CurrentUser\My"
    )

    PROCESS
    {
        $objStore = Get-Item $CertificateStorePath -EA 0 -EV StoreError | `
            Where { $_ -is [System.Security.Cryptography.X509Certificates.X509Store] }
        
        if(!$objStore)
        {
            $objStore = Get-Item Cert:\$CertificateStorePath -EA 0 | `
                Where { $_ -is [System.Security.Cryptography.X509Certificates.X509Store] }
        
            if (!$objStore) { throw "Couldn't find X509 Certificate Store: $StoreError" }
        
            $CertificateStorePath = "Cert:\$CertificateStorePath"
        }

        TRY { $objStore.Open("MaxAllowed") }
        
        CATCH { THROW "Couldn't open x509 Certificate Store: $_" }

        foreach ($itmCertFile in (Get-Item $PFXCertificatePath)
        {
            Write-Warning "Attempting to load $($itmCertFile.Name)"
            
            # Will automatically prompt for password, if the cert is properly protected
            $objCert = Get-PfxCertificate -LiteralPath $itmCertFile.FullName
            
            if(!$objCert)
            {
                Write-Warning "Failed to load $($itmCertFile.Name)"
                CONTINUE
            }
            $objStore.Add($objCert)

            Get-Item "${CertificateStorePath}$($objCert.Thumbprint)"
        }

        $objStore.Close()
    }
}