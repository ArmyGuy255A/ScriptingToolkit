50636 -> to DC
25 -> to EXCH
389 -> to DC

DC: 192.168.0.1
EXCH: 192.168.0.5
EDGE: 172.16.0.5 (Not on the domain)
EXTERNAL EMAIL SERVER : 10.0.10.5
EXTERNAL EMAIL DOMAIN : contoso.com
INTERNAL EMAIL DOMAIN : fabrikam.com
DMZ EMAIL DOMAIN : fabrikam.external.com

[Exch 2019 Edge Transport](https://learn.microsoft.com/en-us/exchange/plan-and-deploy/prerequisites?view=exchserver-2019)

# Prepare

WARNING: This setup assumes the edge server is not joined to a domain and sits in a DMZ

1. Install VC++ Redistributable 2012
2. Create `edge` DNS record in DMZ DNS
3. Create `mail` MX record in the Internal Domain
4. Create an entry in the `edge` server's host file for the internal domain.
```powershell
"192.168.0.1 fabrikam.com" >> C:\Windows\System32\drivers\etc\hosts
"192.168.0.5 mail.fabrikam.com" >> C:\Windows\System32\drivers\etc\hosts
``` 
5. Ensure `edge` can reach DNS server and EXCH server using the ports listed above.
6. Add a DNS suffix to the edge server and install ADLDS

```powershell
ncpa.cpl
Install-WindowsFeature ADLDS

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "NV Domain" -Value "fabrikam.external.com"

# Additionally

Restart-Computer
```

4. Attach Exchange ISO & Install Edge Transport
    - Note: Ensure to check the box for Install required windows features.

5. Installation will take about 10 minutes

# Configure Edge Transport

1. Open Exchange Shell and Test the Service Health
```powershell
Test-ServiceHealth
```

2. Create an Exchange Certificate CSR and submit it to the CA
```powershell
$Data = New-ExchangeCertificate -GenerateRequest -SubjectName "c=US, o=I CORPS, cn=mail.fabrikam.com" -DomainName mail.fabrikam.com, autodiscover.fabrikam.com, edge.fabrikam.com -PrivateKeyExportable $true -Server edge

Set-Content -Path "C:\Scripts\edge.csr" -Value $Data
```
3. Submit the CSR to the CA and install the certificate

```powershell
$Cert = Import-ExchangeCertificate -FileName "C:\Scripts\edge.cer" -Server edge
Enable-ExchangeCertificate -Thumbprint $Cert.Thumbprint -Services "SMTP"
Get-ExchangeCertificate | Select-Object subject, services, thumbprint

```

4. Ensure the CA Certificate of the issuing CA is in the `edge` server's Trusted Root Certification Authorities store. 

# Configure Edge Subscription

1. Create an Edge Subscription (On the Edge Server)
   - It creates a secure copy of active directory information to the AD LDS instance on the edge server

```powershell
New-EdgeSubscription -FileName "C:\Scripts\EdgeSubscription.xml"
```

2. Copy the XML file to the EXCH server and import it
   - Note: Ensure the SUBNET of the EDGE server is added to the AD Sites and Services for the Site selected in the command below

```powershell
New-EdgeSubscription -FileData ([byte[]]$(Get-Content "C:\Scripts\EdgeSubscription.xml" -Encoding Byte -ReadCount 0)) -Site "Default-First-Site-Name"

Write-Host "Waiting for the Subscription to be created" -ForegroundColor Yellow
Start-Sleep -seconds 60

# Start the Edge Synchronization
# This copies any rules (send/receive connectors) from the Exchange Server to the Edge Transport server
Start-EdgeSynchronization

# Confirm the Synchronization works
Test-EdgeSynchronization

```

This should create an EdgeSync subscription on the Exchange server. Do not continue until the Start-EdgeSyncronization command completes. 

This may take approximately 15 minutes to start working based on the configuration of Active Directory Sites and Services

Keep trying 

# Configure Edge Transport

1. On the Exchange server, open the Exchange Management Shell and run the following commands to configure the Send and Receive Connectors
  - Note: If you're not blindly sending email using DNS, you should remove the default send connector on the Edge subscription. This guide assumes that this needs to be performed.
  - You should have: 
      - Send Connector from `exch` to `edge`
      - Send Connector from `edge` to `external email server`
      - Receive Connector from `edge` to `exch` for `mail.fabrikam.com`

```powershell
# View the Receive Connectors
Get-ReceiveConnector | fl *fqdn*

# Set the FQDN of the default receive connector to receive mail from the external network for the internal domain
Set-ReceiveConnector -Identity "Default internal receive connector EDGE" -Fqdn "mail.fabrikam.com"

$defaultEdgeSendConnector = Get-SendConnector -Identity "Default external send connector EDGE"
$defaultEdgeSendConnector | Remove-SendConnector

# Create a Send Connector for the Exchange server to forward mail to the Edge Transport
New-SendConnector -Name "To DMZ" -Usage Custom -AddressSpaces "SMTP:*;1" -IsScopedConnector $false -SmartHosts "172.17.0.5" -SmartHostAuthMechanism "None" -UseExternalDNSServersEnabled $true -SourceTransportServers "exch"

# Now, Create a new Send Connector for the Edge Transport to forward mail for a specific domain to a smart host on the distant end.

New-SendConnector -Name "EdgeSync - To EXTERNAL SMART HOST" -Usage Custom -AddressSpaces "SMTP:contoso.com;1" -IsScopedConnector $false -SmartHosts "10.0.10.5" -SmartHostAuthMechanism "None" -UseExternalDNSServersEnabled $false -SourceTransportServers "edge"

```
2. Test the Receive Connector on the Edge Server from a PowerShell Session
   - Note: You can perform this on the Edge Server to also troubleshoot ports and protocols
```powershell
# Test the Receive Connector from a new PowerShell session
Send-MailMessage -To "phillip.dieppa@fabrikam.com" -From "donald.trump@contoso.com" -Subject "Big Water" -Body "There is water, and then there is big water" -SmtpServer "edge.fabrikam.external.com"
```

## Helpful Troubleshooting Tips

It's helpful to know how mail flows through this scenario. In this particular setup, the mailflow transaction happens as follows:

1. Client sends an email to `donald.trump@contoso.com`
2. The message hits `exch.fabrikam.com`
3. The message is forwarded from `exch.fabrikam.com` to `edge.fabrikam.external.com`
4. The message is forwarded from `edge.fabrikam.external.com` to `mail.contoso.com`

Troubleshoot Step 2

On the Exchange Server, view the Message Queue. You should not see any mail queued here. If you do, check to make sure that the queue is looking for the Smart Host for the `edge` server. It should not be trying to send mail to the internet.

```powershell
Get-Queue
```

Troubleshoot Step 2

Ensure that mail is not queued up on the exchange server. If it is, there's a good chance that something is wrong with your send connectors. There's also a good chance that your send connectors may not have replicated to the Edge Transport server. Remember that the Edge Transport server stores its configuration in an ADLDS instance and changes will replicate periodically. You can force this to happen by running these commands on the `exch` server. These command should return back 0 messages in the queue, with `Success` and/or `Normal` status messages. If there were any updates that needed to be sent, you would see something other than `0` in the Added, Deleted, Updated, and Scanned fields in the output of `Start-EdgeSynchronization`

```powershell
Get-Queue
Start-EdgeSynchronization
Test-EdgeSynchronization
```

Troubleshoot Step 3

Ensure that mail is not queued up on the `edge` server. If it is, double-check that your send connectors have replicated to the transport server. If they're not there, double check that the previous step was successful and changes replicated. Note, it could take up to 5 minutes for new Send Connectors to become available for synchronization

```powershell
Get-Queue
Get-SendConnectors
Get-ReceiveConnectors
```
