#!/bin/bash 

export AZURE_STORAGE_KEY=YOURKEYHERE

az storage blob list --container-name backups --account-name tmeresources --output json | jq -r '. | sort_by(.properties.lastModified) | .[] | {Name: .name, LastModified: .properties.lastModified}' | jq -s . | jq -r '(["Name","LastModified"], ["----","------------"], (.[] | [.Name, .LastModified])) | @tsv' | column -t
