#!/bin/bash 

# RESOURCE_ID='/subscriptions/2f0fe240-4ebb-45eb-8307-9f54ae213157/resourceGroups/hasbro/providers/Qumulo.Storage/fileSystems/ftest'
# TYPE="qumulo.storage/filesystems"

# RESOURCE_GROUP='hasbro' # /subscriptions/2f0fe240-4ebb-45eb-8307-9f54ae213157/resourceGroups/hasbro
# SUBSCRIPTION="2f0fe240-4ebb-45eb-8307-9f54ae213157"
# MANAGED_RESOURCE_GROUP="QM_hasbro_ftest_eastus"

az graph query -q ' resourcechanges | |extend targetResourceId = tostring(properties.targetResourceId), changeType = tostring(properties.changeType), createTime = todatetime(properties.changeAttributes.timestamp) | where createTime > ago(7d) and changeType == "Create" or changeType == "Update" or changeType == "Delete" | project  targetResourceId, changeType, createTime | join ( resources | extend targetResourceId=id) on targetResourceId | where tags ["Environment"] =~ "kmcdonald" | order by createTime desc | project createTime, id, resourceGroup, type  '

