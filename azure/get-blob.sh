

echo "Authenticate with Azure"
az login --use-device-code

echo "Configuring az cli settings..."

(cat << _EOF_
[cloud]
name = AzureCloud

[core]
output = table
collect_telemetry = no
cache_ttl = 10
disable_confirm_prompt=yes

[logging]
enable_log_file = yes

[extension]
use_dynamic_install=yes_without_prompt
run_after_dynamic_install=yes
_EOF_
) > /home/qumulo/.azure/config 

echo "Adding the Qumulo az extension"
az extension add --name qumulo

echo "Setting the default subscription to azure-qumulo-product"
az account set --subscription azure-qumulo-product

echo "Sleeping while azure updates their systems"
sleep 30

echo "Downloading the spec-harness"
az storage blob download --account-name tmeresources --container-name spec-harness --name spec-harness.tgz --file spec-harness.tgz --auth-mode login

echo "Extracting..."
tar xvf spec-harness.tgz

exit


# 


# az logout && az login --use-device-code
