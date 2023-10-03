# Configuring ADFS Authentication with SharePoint 2019

A Guide by CW4 Dieppa, Phillip A.
I CORPS G6, Enterprise Services

## Overview

## Integrating ADFS Authentication with SharePoint 2019

### Prerequisites

1. ADFS Server setup and configured.
2. SharePoint 2019 Server with a root site collection already created.
3. User Profile Service (Service Application) installed on SharePoint Central Administration
4. SharePoint SSL Certificate Installed (With an alias ... ex. `portal.contoso.com`)
5. SharePoint configured for SSL
6. ADFS Certificate Authority installed in "Trusted Root Certification Authority" store on the local machine.
7. ADFS Server and ADFS Server Signing certificate.
8. Web Browser available

### **SharePoint Certificate SAN Requirements**

Friendly Name: SharePoint Certificate

Common Name: CN=portal.contoso.com

Subject Alternate Names (DNS Names)

1. portal.contoso.com

### Configure ADFS to Send Claims to SharePoint

1. In AD FS Management, create a new Relying Party Trust
2. Select Claims Aware
3. Select Enter data about the relying party manually
4. Display Name: `SharePoint`
5. Select next on the Configure Certificate screen
6. Enable Support for the WS-Federation Passive protocol
   1. Enter: `https://portal.contoso.com/_trust/default.aspx`
    - Note: SharePoint will listen on `_trust/default.aspx`, this is a special suffix for SharePoint auth.
7. Relying Party Trust Identifier
   1. Add `urn:auth:adfs`
8. Select next
9. Select Close

**Edit the SharePoint Claims Issuance Policy**

1. Select `SharePoint` and `Edit Claim Issuance Policy`
2. Add the `Pass-through Rule` using the `Send Claims Using a Custom Rule` template

```plaintext
c:[]
 => issue(claim = c);
```


### Configure SharePoint for ADFS Authentication

1. Export the ADFS Token Signing Certificate and place it into an easy-to-access directory such as `c:\scripts` or `c:\certs`
   - You can download this certificate from the AD FS Management Console in the Certificates section.

```powershell
# Show the thumbprint of the certificate so you know which one to export.
Get-AdfsCertificate -CertificateType "Token-Signing"
```

2. Copy this certificate over to the SharePoint server. The SP Server needs this certificate in order to decrypt credentials that are passed over via ADFS.

3. Update the `settings` portion of the script. Please note the realm, as we'll need to set this up on the ADFS server using the same name, and case. Capital letters matter here!

```powershell

function Exit-IfNotAdmin {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
        exit
    }
}

function Import-SharePointPSSnapin {
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}

# Initialize variables
# NOTE: The SignCertFilePath is the token signing certificate for the ADFS Server.
$settings = @{
    "SignCertFilePath" = "c:\certs\contoso-adfs-sign.cer";
    "AdfsCACertFilePath" = "c:\certs\contoso-adfs-ca.cer"
    "Realm"            = "urn:auth:adfs";
    "SignInUrl"        = "https://federation.contoso.com/adfs/ls";
    "TrustedName"      = "ADFS-Auth";
    "TrustedDesc"      = "ADFS Auth Service";
}

# Load functions
Exit-IfNotAdmin
Import-SharePointPSSnapin

# Load signing certificate
$caCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($settings.AdfsCACertFilePath)
$signCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($settings.SignCertFilePath)

New-SPTrustedRootAuthority -Name "ADFS Token Signing Authority" -Certificate $signCert
New-SPTrustedRootAuthority -Name "ADFS Token Signing Root Authority" -Certificate $caCert

# Define claims
$mappings = @(
    @{IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"; IncomingClaimTypeDisplayName = "Account Name"; SameAsIncoming = $true}
    @{IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"; IncomingClaimTypeDisplayName = "Last Name"; SameAsIncoming = $true}
    @{IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenName"; IncomingClaimTypeDisplayName = "First Name"; SameAsIncoming = $true}
    @{IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailAddress"; IncomingClaimTypeDisplayName = "Email Address"; SameAsIncoming = $true}
    @{IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/displayName"; IncomingClaimTypeDisplayName = "Display Name"; SameAsIncoming = $true}
    @{IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/country"; IncomingClaimTypeDisplayName = "Country"; SameAsIncoming = $true}
)

# Create Claim mappings
$claimsMappings = $mappings | ForEach-Object {
    New-SPClaimTypeMapping @_
}

# Create new trusted identity token issuer
$ti = New-SPTrustedIdentityTokenIssuer -Name $settings.TrustedName -Description $settings.TrustedDesc -Realm $settings.Realm -ImportTrustCertificate $signCert -ClaimsMappings $claimsMappings -SignInUrl $settings.SignInUrl -IdentifierClaim $claimsMappings[0].InputClaimType

$ti.UseWReplyParameter = $true
$ti.Update()
```

1. Replace the `settings` variable with settings appropriate for your environment. You should only need to change the `SignCertFilepath` and the `SignInUrl` with new values for your environment. Everything else can stay the same.

2. **Configure User Profile Service**: If you're using the User Profile Service, you'll need to map the claims to user profile properties. This can be done in Central Administration -> Manage Service Applications -> User Profile Service Application -> Manage User Properties.

3. **Configure the Web Application to Use the Trusted Identity Provider**: In Central Administration, go to Manage Web Applications -> select your web application -> Authentication Providers -> Default -> Claims Authentication Types

4. Select the [X] ADFS Trusted Identity Provider checkbox as well as the provider you created. This would be [X] `STS-Auth` if you did not replace it in the `settings` variable.


5. Restart iis and attempt to login

```powershell
iisreset.exe /noforce
```

### Troubleshooting

If you encounter any issues during the integration of ADFS with SharePoint, you can check the ULS logs on the SharePoint server for any error messages or warnings. The ULS logs are typically located in the `C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\LOGS` directory.

You can also check the ADFS server's event logs. The ADFS event logs are located under "Applications and Services Logs" -> "AD FS" -> "Admin".

Remember to check the certificate status in both ADFS and SharePoint. The ADFS Token Signing Certificate must be trusted by SharePoint, and the SharePoint SSL certificate must be trusted by the ADFS server.

If you're having issues with the User Profile Service, make sure that the claims are correctly mapped to user profile properties. We set the account claim to the UPN/Account Name field for the user profile service. You can change this if you would like, but be advised to troubleshoot accordingly.

Please note that this is a basic configuration and you may need to adjust it based on your specific requirements. Always refer to the official Microsoft documentation for the most detailed and up-to-date information.

**The root of the certificate chain is not a trusted root authority**

The SharePoint server doesn't trust the CA certificate issued to the ADFS. You need to manually install the ADFS CA Certificate into the trusted store on the SP Server.

```powershell
$caCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("c:\scripts\ca-path.cer")
New-SPTrustedRootAuthority -Name "ADFS Token SigningRoot Authority" -Certificate $caCert
```
