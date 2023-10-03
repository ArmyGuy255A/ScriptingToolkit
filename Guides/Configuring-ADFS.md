# Configuring ADFS

A Guide by CW4 Dieppa, Phillip A.
I CORPS G6, Enterprise Services

## Overview

This document will walk you through the steps needed to deploy and configure an ADFS Server for your environment. This configuration guide supports two different scenarios. Both scenarios work for internal and external ADFS deployments. Scenario #1 is designed for a single ADFS Server deployment. This is useful if you do not want to perform a domain trust with your partner organization. Scenario #2 is designed for a more robust configuration that supports a DMZ configuration. There are major benefits of using a Web Application Proxy. We prefer that you use Scenario #2 if possible.

ADFS IP: 192.168.0.1

WAP IP: 192.168.100.1

Service Account: `gMSA-ADFS`

**Scenario #1:**

| Role | FQDN Name | CName | IP Address |
| --- | --- | --- | --- |
| ADFS Server | adfs.contoso.com | federation.contoso.com | 192.168.0.1 |

**Scenario #2:**

| Role | FQDN Name | CName | IP Address |
| --- | --- | --- | --- |
| ADFS Server | adfs.contoso.com | federation.external.contoso.com | 192.168.0.1 |
| WAP Server | wap.external.contoso.com | proxy.external.contoso.com | 192.168.1.100 |

**DNS Records:**

| Name | Type | Address/Host |
| --- | --- | --- |
| federation | CNAME | adfs.contoso.com |

## Certificate Prerequisites
The ADFS servers will need a valid certificate from a trusted CA. This certificate must have the following DNS Names in the request in order to support both internal and external scenarios.

[Scenario #1](#adfs-certificate-san-requirements-scenario-1)

[Scenario #2](#adfs-certificate-san-requirements-scenario-2)

### **ADFS Certificate SAN Requirements (Scenario #1):**

Friendly Name: ADFS Certificate

Common Name: CN=federation.contoso.com

Subject Alternate Names (DNS Names)

1. federation.contoso.com
2. certauth.federation.contoso.com
3. enterpriseregistration.contoso.com

### **ADFS Certificate SAN Requirements (Scenario #2):**

Friendly Name: ADFS Certificate

Common Name: CN=federation.contoso.com

Subject Alternate Names (DNS Names)

1. federation.contoso.com
2. certauth.federation.contoso.com
3. enterpriseregistration.contoso.com
4. proxy.external.contoso.com

# Prerequisites

## ADFS Prerequisites
1. Deploy a new VM for ADFS with Windows Server 2019 or higher
2. Name the ADFS Server `adfs` and join it to `contoso.com`
3. Install the ADFS Certificate

## WAP Prerequisites
1. (Scenario #2 Only) Deploy a new VM for WAP with Windows Server 2019 or higher
2. (Scenario #2 Only) Name the WAP server `wap` and join it to `external.contoso.com`
3. Install the WAP/ADFS Certificate

## AD Prerequisites

1. Ensure Active Directory is deployed and configured with a KDS Root Key
  - Note: Run these Commands on the Domain Controller for the Domain where the ADFS is installed

2. Test the KDS Root Key. You need this in order to create a Group Managed Service Account

```powershell
$keyId = $(Get-KdsRootKey).KeyId
Test-KdsRootKey -KeyId $keyId
```

3. If the KDS Root Key is `False` or produces an error, you will need to create a new one.
  - `WARNING`: The Command below will create a Kds root key, however, it is only valid on the Domain Controller that it was executed on. It will take approximately 12 hours to fully replicate to the other domain controllers in the forest.

[Reference](https://learn.microsoft.com/en-us/windows-server/security/group-managed-service-accounts/create-the-key-distribution-services-kds-root-key)

```powershell
Add-KdsRootKey -EffectiveImmediately
```
4. Create a new Group Managed Service Account and delegate permissions to the ADFS Server

```powershell
New-ADServiceAccount -Name gMSA-ADFS -DNSHostName gMSA-ADFS.contoso.com -PrincipalsAllowedToRetrieveManagedPassword "adfs$" -KerberosEncryptionType AES256
```

5. Create a CName record in DNS for the ADFS Server. This is required for name resolution and expansion scenarios where you may decide to add an additional ADFS in the future, or support Scenario #2.

```powershell
Add-DnsServerResourceRecordCName -Name federation -HostNameAlias adfs.contoso.com -ZoneName contoso.com
```

6. (Scenario #2 Only) Create a CName record for the WAP and ADFS Server in `external.contoso.com`.

```powershell
Add-DnsServerResourceRecordCName -Name proxy -HostNameAlias wap.external.contoso.com -ZoneName external.contoso.com
Add-DnsServerResourceRecordCName -Name federation -HostNameAlias proxy.external.contoso.com -ZoneName external.contoso.com
```

## Prepare the ADFS Prerequisites

1.  Deploy a new VM with Windows Server 2019 or higher
2.  Join the VM to the Domain
3.  Install the following roles:

```powershell
Install-WindowsFeature -Name ADFS-Federation, RSAT-AD-PowerShell -IncludeManagementTools
```

4. Create a new ADFS Farm.

```powershell
#Install the AD Service Account
Install-ADServiceAccount -Identity gMSA-ADFS

#List certificate thumbprints
Get-ChildItem -Path Cert:\LocalMachine\My\

#Install using a gMSA
Install-ADFSFarm -CertificateThumbprint "Enter your ADFS Certificate thumbprint here" -FederationServiceName "federation.contoso.com" -FederationServiceDisplayName "CONTOSO Corps" -GroupServiceAccountIdentifier "gMSA-ADFS$" -OverwriteConfiguration

#Install using an AD Account
Install-ADFSFarm -CertificateThumbprint "Enter your certificate thumbprint here" -FederationServiceName "federation.contoso.com" -FederationServiceDisplayName "CONTOSO Corps" -ServiceAccountCredential (Get-Credential) -OverwriteConfiguration

#Restart the computer
Restart-Computer
```

Replace "Enter your certificate thumbprint here" with the thumbprint of your ADFS certificate. You will be prompted to enter the credentials for the service account (i.e., `gMSA-ADFS@contoso.com`).

## Configure the ADFS Farm

1. Run the provided script `Initialize-ADFSADClaims.ps1` on your server to map the Active Directory attributes to the ADFS claims. This configures your ADFS Server to collect certain claims from AD in order to forward to the relying party.

Here's a text-version of the script in case it is not provided

```powershell
#Create the country claim description
$countryDescription = Get-AdfsClaimDescription -ShortName c
if ($null -eq $countryDescription) {
    Add-AdfsClaimDescription -Name "ISO 3166 (Country Code)" -ClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/country" -ShortName "c"
}

#Add in all necessary claims to the AD claims provider. This ensures that all of the important attributes for your ADFS are mapped to the correct claim types
$ruleTemplate = @"
@RuleTemplate = "LdapClaims"
"@

$ruleName = @"
@RuleName = "AD Attributes"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
"@

$rule = @"
 => issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn", "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"), query = ";userPrincipalName,sAMAccountName,givenName,sn,mail,displayName;{0}", param = c.Value);
"@

$rule = $rule.Replace("`n", "")
$transformRule = $ruleTemplate + "`n" + $ruleName + "`n" + $rule

$adClaimsProvider = Get-AdfsClaimsProviderTrust -Name "Active Directory"

if ($adClaimsProvider.AcceptanceTransformRules.Contains($ruleTemplate)) {
    # Split and replace the rule

    $rules = $adClaimsProvider.AcceptanceTransformRules.Split("`r")
    $ruleIndex = $rules.IndexOf("`n{0}" -f $ruleTemplate)
    $rules[$ruleIndex + 3] = $rule
    $rules = [string]::Join("`n", $rules)
    Set-AdfsClaimsProviderTrust -TargetName $adClaimsProvider.Name -AcceptanceTransformRules $rules

} else {
    #Just add it to the end.
    Set-AdfsClaimsProviderTrust -TargetName $adClaimsProvider.Name -AcceptanceTransformRules ($adClaimsProvider.AcceptanceTransformRules + $transformRule).Trim()
}
```

## Web Application Proxy Installation (Scenario #2)

1. Deploy a new VM for WAP with Windows Server 2019 or higher.

2. Name the WAP server `wap` and join it to `external.contoso.com`.

3. Install the Web Application Proxy role:

```powershell
Install-WindowsFeature Web-Application-Proxy -IncludeManagementTools
```

## Configuring the Web Application Proxy (Scenario #2)

1. After the WAP role is installed, open the Remote Access Management Console.

2. In the "Configuration" section, click on "Web Application Proxy".

3. Click on "Run the Web Application Proxy Configuration Wizard". Follow the wizard and when asked, enter the federation service name (e.g., `federation.contoso.com`) and the credentials for the ADFS service account.

## ADFS Testing

1. Open a web browser and navigate to `https://federation.contoso.com/adfs/ls/IdpInitiatedSignon.aspx`. 

2. If ADFS is configured correctly, you should see a sign-in page.

## Configuring ADFS to ADFS Connection

1. **Setup Trust Relationship**: Setup a trust relationship between the two ADFS servers. This is done by adding a new relying party trust on each ADFS server for the other. The steps below will guide you through the process.

2. **Open ADFS Management Console**: Open the ADFS Management console on your first ADFS server.

3. **Add Relying Party Trust**: Go to "Trust Relationships" -> "Relying Party Trusts" -> "Add Relying Party Trust". This will open a wizard. ADFS is `Claims aware`, so choose this option and click 'Start'.

4. **Import Data**: Choose "Import data about the relying party published online or on a local network"

5. **Configure Certificate**: In the "Federation Metadata Address" step, add the URL of the remote ADFS server. This is usually in the format `https://[ADFS Server FQDN]/FederationMetadata/2007-06/FederationMetadata.xml`.
   
6. **Complete Configuration**: Select 'Next' all the way through until the configuration is complete. There is no need to configure anything else in the wizard.

7.  **Add the Passthrough Claim**: Select the new relying party trust you created in the previous step, and `Edit Claim Issuance Policy`. In the "Edit Claim Rules" window, add a new rule. Choose "Send Claims Using a Custom Rule" as the template. Name the rule "Send All Claims" and use the following for the custom rule:

```plaintext
c:[]
 => issue(claim = c);
```


## Troubleshooting

If you encounter any issues during the installation or configuration of the ADFS or WAP servers, you can check the event logs on the respective servers for any error messages or warnings. The ADFS event logs are located under "Applications and Services Logs" -> "AD FS" -> "Admin".

You can also use the "Test-ADFSFarm" and "Test-WebApplicationProxyConfiguration" PowerShell cmdlets to test the ADFS farm and WAP configuration, respectively.


## Claim Rule Information

In ADFS, claims rules are used to determine how incoming claims are handled. They can be used to pass through incoming claims, transform incoming claims into a different type, or generate new claims. Claims rules are processed in the order they are listed.

Claims rules have the following general format:

```plaintext
c:[Type == "incoming claim type", Issuer == "incoming claim issuer"]
 => issue(Type = "outgoing claim type", Issuer = "AD FS", OriginalIssuer = c.OriginalIssuer, Value = c.Value, ValueType = c.ValueType);
```

Here are some examples of common claims rules:

1. **Pass Through Rule**: This rule will simply pass through an incoming claim without modifying it.

```plaintext
c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
 => issue(claim = c);
```

This rule states that if an incoming claim has the type "email address", it will be issued as is.

2. **Transform Rule**: This rule will transform an incoming claim of one type to an outgoing claim of another type.

```plaintext
c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
 => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn", Issuer = c.Issuer, OriginalIssuer = c.OriginalIssuer, Value = c.Value, ValueType = c.ValueType);
```

This rule states that if an incoming claim has the type "email address", it will be issued as a "UPN" claim.

3. **Send Group Membership as a Claim**: This rule will issue a claim for each group that the user is a member of.

```plaintext
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
 => issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/claims/Group"), query = ";tokenGroups;{0}", param = c.Value);
```

This rule states that for each group the user is a member of, a "group" claim will be issued.

Remember, in all these rules, `c` represents the incoming claim, and `issue()` is used to issue an outgoing claim. The `Type`, `Issuer`, `OriginalIssuer`, `Value`, and `ValueType` properties of the outgoing claim can be set to any value or can be set to the corresponding property of the incoming claim.
