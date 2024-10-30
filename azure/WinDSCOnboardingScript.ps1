try {
    # Add the service principal application ID and secret here
    $ServicePrincipalId="72735501-7dc8-458c-b994-956d8ceb571f";
    $ServicePrincipalClientSecret="<ENTER SECRET HERE>";

    $env:SUBSCRIPTION_ID = "2f0fe240-4ebb-45eb-8307-9f54ae213157";
    $env:RESOURCE_GROUP = "mrcooper";
    $env:TENANT_ID = "3fa909c1-1b1f-4ebb-8953-cdc139fb2112";
    $env:LOCATION = "eastus";
    $env:AUTH_TYPE = "principal";
    $env:CORRELATION_ID = "3e9e794f-6c37-4ad2-9dc4-3fd6dc4e2c2d";
    $env:CLOUD = "AzureCloud";
    

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072;

    # Download the installation package
    Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/azcmagent-windows" -TimeoutSec 30 -OutFile "$env:TEMP\install_windows_azcmagent.ps1";

    # Install the hybrid agent
    & "$env:TEMP\install_windows_azcmagent.ps1";
    if ($LASTEXITCODE -ne 0) { exit 1; }

    # Run connect command
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect --service-principal-id "$ServicePrincipalId" --service-principal-secret "$ServicePrincipalClientSecret" --resource-group "$env:RESOURCE_GROUP" --tenant-id "$env:TENANT_ID" --location "$env:LOCATION" --subscription-id "$env:SUBSCRIPTION_ID" --cloud "$env:CLOUD" --correlation-id "$env:CORRELATION_ID";
}
catch {
    $logBody = @{subscriptionId="$env:SUBSCRIPTION_ID";resourceGroup="$env:RESOURCE_GROUP";tenantId="$env:TENANT_ID";location="$env:LOCATION";correlationId="$env:CORRELATION_ID";authType="$env:AUTH_TYPE";operation="onboarding";messageType=$_.FullyQualifiedErrorId;message="$_";};
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) | out-null;
    Write-Host  -ForegroundColor red $_.Exception;
}
