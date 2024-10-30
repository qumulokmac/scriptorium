#!/bin/bash


PRODUCTSUB=2f0fe240-4ebb-45eb-8307-9f54ae213157
STAGINGSUB=7418a6db-97af-4ae5-8633-c2549a0fdd3f
SASTUB=03a3547d-beb4-45f7-96ea-e6559202f2d2


az feature register -n AvailabilityZonePeering --namespace Microsoft.Resources --subscription $STAGINGSUB

exit

az feature show -n AvailabilityZonePeering --namespace Microsoft.Resources

# az provider register -n Microsoft.Resources
# az feature show -n AvailabilityZonePeering --namespace Microsoft.Resources
exit



Command
    az feature register : Register a preview feature.

Arguments
    --name -n   [Required] : The feature name.
    --namespace [Required] : The resource namespace, aka 'provider'.

Global Arguments
    --debug                : Increase logging verbosity to show all debug logs.
    --help -h              : Show this help message and exit.
    --only-show-errors     : Only show errors, suppressing warnings.
    --output -o            : Output format.  Allowed values: json, jsonc, none, table, tsv, yaml,
                             yamlc.  Default: table.
    --query                : JMESPath query string. See http://jmespath.org/ for more information
                             and examples.
    --subscription         : Name or ID of subscription. You can configure the default subscription
                             using `az account set -s NAME_OR_ID`.
    --verbose              : Increase logging verbosity. Use --debug for full debug logs.

Examples
    register the "Shared Image Gallery" feature
        az feature register --namespace Microsoft.Compute --name GalleryPreview

To search AI knowledge base for examples, use: az find "az feature register"

[kmcdonald:~/tidbits/azure]$
