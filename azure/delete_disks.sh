
Next time check the output of disk list and pipe it to jq - just need the disks, not the headers and dashes ... 

# az  disk list --resource-group hpc-ai-copilot-summit 

for disk in `az  disk list --resource-group hpc-ai-copilot-summit`
do 
  echo "Deleting  $disk "
  az disk delete --resource-group hpc-ai-copilot-summit -n $disk --yes --no-wait

done


