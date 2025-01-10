#!/bin/bash -xe
cd /root
region="${region}"
s3_region="${bucket_region}"
stkname="${deployment_unique_name}"
existing_stkname="${existing_deployment_unique_name}"
cluster_secrets_arn="${cluster_secrets_arn}"
cluster_sg_id="${cluster_sg_id}"
cluster_name="${cluster_name}"
cluster_persistent_bucket_uris="${cluster_persistent_bucket_uris}"
cluster_persistent_storage_type="${cluster_persistent_storage_type}"
cluster_persistent_bucket_names="${cluster_persistent_bucket_names}"
cluster_persistent_capacity_limit="${cluster_persistent_storage_capacity_limit}"
ena_express="${ena_express}"
replace_cluster="${replacement_cluster}"
qqh="./qq --host ${node1_ip}"
node_ips="${primary_ips}"
instance_ids="${instance_ids}"
float_ips="${floating_ips}"
max_float_ips="${max_floating_ips}"
def_password="${temporary_password}"
s3bkt="${bucket_name}"
upgrade_s3pfx="${upgrade_s3_prefix}"
functions_s3pfx="${functions_s3_prefix}"
install_s3pfx="${install_s3_prefix}"
serverIP=$(hostname -I | xargs)
token=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
this_ec2=$(curl -H "X-aws-ec2-metadata-token: $token" -v http://169.254.169.254/latest/meta-data/instance-id)
mod_FIPs="NO"
bkt_pfx="$s3bkt/$functions_s3pfx"
req_ver="${version}"
num_azs="${number_azs}"
f_tput="${flash_tput}"
f_iops="${flash_iops}"
tun_refill_IOPS="${tun_refill_IOPS}"
tun_refill_Bps="${tun_refill_Bps}"
tun_read_Thold="${tun_read_Thold}"
tun_read_Prom1="${tun_read_Prom1}"
tun_prefetch_Streams="${tun_prefetch_Streams}"
tun_EBS_BW="${tun_EBS_BW}"
tun_EC2_BW="${tun_EC2_BW}" 
tun_disk_count="${tun_disk_count}"
fault_domain_ids="${fault_domain_ids}"

if [[ ! -e "functions-cn-v10.sh" ]]; then
  aws s3 cp --region $s3_region s3://$bkt_pfx"functions-cn-v10.sh" ./functions-cn-v10.sh
fi
source functions-cn-v10.sh

if [ $(chkurl "https://api.missionq.qumulo.com/"; echo $?) -eq 1 ]; then
  ssmput "last-run-status" "$region" "$stkname" "BOOTED. MQ up for metrics."
else
  ssmput "last-run-status" "$region" "$stkname" "BOOTED. MQ NOT reachable. Aborting deployment."
  exit
fi

if [ $(chkurl "google.com"; echo $?) -eq 1 ]; then
  ssmput "last-run-status" "$region" "$stkname" "BOOTED. Internet up."
else
  ssmput "last-run-status" "$region" "$stkname" "BOOTED. Internet NOT reachable. VPC endpoints are required."
fi

#No longer needed but left for future Nexus integration
#if [ $(chkurl "trends.qumulo.com"; echo $?) -eq 1 ]; then
#  ssmput "last-run-status" "$region" "$stkname" "Trends UP for software."
#  no_inet="false"
#else
#  ssmput "last-run-status" "$region" "$stkname" "Trends DOWN for software."
#  no_inet="true"
#fi

traceroute -T -p 443 s3.$region.amazonaws.com > ./s3check.txt
m=0
last_line="no"
while IFS= read -r line; do 
    (( m = m + 1 ))
    if [ $m -gt 1 ]; then
        if [[ "$line" =~ ^.*"* * *".* ]]; then
            echo "Checking for S3 gateway - valid internal hop"
        elif [ "$last_line" == "yes" ]; then
            echo "Checking for S3 gateway - NO S3 GATEWAY"
            ssmput "last-run-status" "$region" "$stkname" "Missing S3 gateway!  Add an S3 gateway to your VPC and restart the provisioner."
            exit
        else
            last_line="yes"
        fi
    fi    
done < ./s3check.txt
echo "S3 gateway validated"
ssmput "last-run-status" "$region" "$stkname" "S3 gateway validated"

ssmput "last-run-status" "$region" "$stkname" "Installing jq, aws cliv2, python3.8 and reading secrets"

if yum list installed "jq" >/dev/null 2>&1; then
  echo "jq exists"
else
  yum install -y jq
fi

if yum list installed "wget" >/dev/null 2>&1; then
  echo "wget exists"
else
  yum install -y wget
fi    

if yum list installed "awscli" >/dev/null 2>&1; then
  aws s3 cp --region $s3_region s3://$s3bkt/$upgrade_s3pfx"awscliv2.zip" ./awscliv2.zip      
  #curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  yum remove -y awscli
  unzip -q awscliv2.zip
  ./aws/install
  ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/sbin/aws   
  ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/bin/aws                        
else
  echo "aws cli v2 exists"
fi

if yum list installed "python38.x86_64" >/dev/null 2>&1; then
  echo "python 3.8 exists"
else
  amazon-linux-extras install python3.8
  rm -f /usr/bin/python3
  ln -s python3.8 /usr/bin/python3  
fi

admin_password=$(getsecret "password" "$cluster_secrets_arn" "$region" "false")

IFS=', ' read -r -a newIDs <<< "$instance_ids"

ssmput "last-run-status" "$region" "$stkname" "Checking quorum state and boot status"
ssmput "last-run-status" "$region" "$stkname" "Waiting for node 1 to run Qumulo Core. Package location: s3://$s3bkt/$install_s3pfx/$req_ver/"

out_quorum=0
in_quorum=0
IFS=', ' read -r -a nodeIPs <<< "$node_ips"
IFS=', ' read -r -a faultIDs <<< "$fault_domain_ids"
for m in "${!nodeIPs[@]}"; do
  if [ $m -eq 1 ]; then
    ssmput "last-run-status" "$region" "$stkname" "Qumulo Core running on node 1. Waiting for other nodes to run Qumulo Core."
  fi
  until [ $(chkurl "https://${nodeIPs[m]}:8000/v1/node/state" "NO"; echo $?) -eq 1 ]; do
    sleep 5
    echo "Waiting for ${nodeIPs[m]} to boot"
  done
  if [ $m -eq 0 ]; then
    getqq "${nodeIPs[m]}" "qq"
  fi

  quorum=$(./qq --host ${nodeIPs[m]} node_state_get)
  if [[ "$quorum" != *"ACTIVE"* ]]; then
    (( out_quorum = out_quorum + 1 ))
  else
    (( in_quorum = in_quorum + 1 ))
  fi
done

ssmput "last-run-status" "$region" "$stkname" "Qumulo Core running on all nodes."

revision=$($qqh version | grep "revision_id")
cur_ver=${revision//[!0-9.]/}

ssmput "installed-version" "$region" "$stkname" "$cur_ver"

org_ver=$(ssmget "creation-version" "$region" "$stkname")

add_nodes="false"
add_buckets="false"
increase_limit="false"
single_node_cluster="false"

if [ "$org_ver" == "null" ]; then
  ssmput "creation-version" "$region" "$stkname" "$cur_ver"
  org_ver=$cur_ver
fi

#Check for version greater than 7.2.2 to enable Multi-AZ, 3 node clusters, and new API in 7.2.3 onward
chk=$(vercomp $cur_ver "7.2.2"; echo $?)
if [ $chk -eq 2 ]; then
  echo "MAZ and 3 Node clusters supported"
else
  echo "MAZ and 3 Node clusters not supported"
  ssmput "last-run-status" "$region" "$stkname" "Qumulo Core version >= 7.2.3 is required.  If this is a new deployment destroy it and redeploy with >= 7.2.3.  If this is an existing deployment contact Qumulo."
  exit 1
fi

IFS=', ' read -r -a newFloatIPs <<< "$float_ips"
num_float_ips=${#newFloatIPs[@]}

IFS=', ' read -r -a bucketNames <<< "$cluster_persistent_bucket_names"
IFS=', ' read -r -a bucketURIs <<< "$cluster_persistent_bucket_uris"

if [ $out_quorum -eq ${#nodeIPs[@]} ] && [ $in_quorum -eq 0 ]; then
  ssmput "last-run-status" "$region" "$stkname" "All nodes out of quorum, NEW CLUSTER"

  new_cluster="true"

  if [ ${#nodeIPs[@]} -eq 1 ]; then
    single_node_cluster="true" 
    replace_cluster="false"
    ssmput "last-run-status" "$region" "$stkname" "SINGLE NODE CLUSTER detected"
  fi

  IFS=', ' read -r -a upgradeIPs <<< "$node_ips"
  IFS=', ' read -r -a upgradeIDs <<< "$instance_ids"

elif [ $in_quorum -gt 2 ]; then
  ssmput "last-run-status" "$region" "$stkname" "3 or more nodes in quorum, checking for node and/or bucket additions"
  new_cluster="false"

  IFS=', ' read -r -a newIPs <<< "$node_ips"
  IFS=', ' read -r -a oldIPs <<< $(ssmget "node-ips" "$region" "$stkname")
  for m in "${!newIPs[@]}"; do
    if [[ ! "${oldIPs[@]}" =~ "${newIPs[m]}" ]]; then
      upgradeIPs+=(${newIPs[m]})
    fi
  done

  IFS=', ' read -r -a oldIDs <<< $(ssmget "instance-ids" "$region" "$stkname")
  for m in "${!newIDs[@]}"; do
    if [[ ! "${oldIDs[@]}" =~ "${newIDs[m]}" ]]; then
      upgradeIDs+=(${newIDs[m]})
    fi
  done

  if [[ ! -z "$float_ips" ]]; then
    IFS=', ' read -r -a newFIPs <<< "$float_ips"
    IFS=', ' read -r -a oldFIPs <<< $(ssmget "float-ips" "$region" "$stkname")
    if [ ${#oldFIPs[@]} -eq ${#newFIPs[@]} ]; then
      for m in "${!newFIPs[@]}"; do
        if [[ ! "${oldFIPs[@]}" =~ "${newFIPs[m]}" ]]; then
          mod_FIPs="YES"
          break
        fi
      done
    else
      mod_FIPs="YES"
    fi
  fi

  if [ ${#upgradeIPs[@]} -gt 0 ]; then
    revision=$(./qq --host ${upgradeIPs[0]} version | grep "revision_id")
    add_ver=${revision//[!0-9.]/}
    add_nodes="true"
    if [ "$cur_ver" != "$add_ver" ]; then
      ssmput "last-run-status" "$region" "$stkname" "Cluster is running ver=$cur_ver.  Can't add nodes running ver=$add_ver.  Update CloudFormation or Terraform with previous node count to remove these nodes. Exiting."
      exit 1
    fi
  fi

  IFS=', ' read -r -a oldBucketNames <<< $(ssmget "bucket-names" "$region" "$stkname")
  IFS=', ' read -r -a oldBucketURIs <<< $(ssmget "bucket-uris" "$region" "$stkname")

  for m in "${!bucketNames[@]}"; do
    if [[ ! "${oldBucketNames[@]}" =~ "${bucketNames[m]}" ]]; then
      newBucketNames+=(${bucketNames[m]})
    fi
  done  

  for m in "${!bucketURIs[@]}"; do
    if [[ ! "${oldBucketURIs[@]}" =~ "${bucketURIs[m]}" ]]; then
      newBucketURIs+=(${bucketURIs[m]})
    fi
  done  

  if [ ${#newBucketNames[@]} -gt 0 ] && [ ${#newBucketURIs[@]} -gt 0 ]; then
    add_buckets="true"
  fi

  old_limit=$(ssmget "soft-capacity-limit" "$region" "$stkname")

  if [ $cluster_persistent_capacity_limit -gt $old_limit ] && [ "$add_buckets" == "false" ]; then
    increase_limit="true"
  fi

elif [ $in_quorum -eq 1 ]; then
  ssmput "last-run-status" "$region" "$stkname" "Single node cluster.  Adding nodes is not supported. Replacing the cluster is not supported."
  new_cluster="false"
  replace_cluster="false"  
  single_node_cluster="true"

fi

if [ "$new_cluster" == "true" ] && [ "$replace_cluster" == "false" ]; then

  for m in "${!bucketNames[@]}"; do
    contents=$(aws s3api list-objects-v2 --region $region --bucket ${bucketNames[m]} --max-items 1)
    if [[ "$contents" == *"Contents"* ]]; then
      echo "  **BUCKET NOT EMPTY, Exiting.  Empty bucket(s) and restart provisioner."
      ssmput "last-run-status" "$region" "$stkname" "Bucket ${bucketNames[m]} NOT EMPTY. Exiting. Empty all buckets and restart provisioner."
      exit 1
    else    
      echo "  **BUCKET ${bucketNames[m]} EMPTY"
    fi
  done

  case $cluster_persistent_storage_type in
    "hot_s3_std")
    pstore_class="TIERED_ACTIVE_PSTORE"
    product_type="ACTIVE_WITH_STANDARD_STORAGE"
    access_tier="HOT"
    s3_type="Standard"
    cnq_type="Hot"
    ;;
    "hot_s3_int")
    pstore_class="TIERED_ACTIVE_PSTORE"
    product_type="ACTIVE_WITH_INTELLIGENT_STORAGE"
    access_tier="INTELLIGENT"    
    s3_type="Intelligent Tiering" 
    cnq_type="Hot"   
    ;;
    "cold_s3_ia")
    pstore_class="TIERED_COLD_PSTORE"    
    product_type="ARCHIVE_WITH_IA_STORAGE"
    access_tier="COOL"      
    s3_type="Infrequent Access"
    cnq_type="Cold"    
    ;;
    "cold_s3_gir")
    pstore_class="TIERED_COLD_PSTORE"    
    product_type="ARCHIVE_WITH_GIR_STORAGE"
    access_tier="COLD"      
    s3_type="Glacier Instant Retrieval"
    cnq_type="Cold"    
    ;;
  esac

  mod_bucket_URIs=()
  for m in "${!bucketURIs[@]}"; do
    mod_bucket_URIs+=("https://${bucketURIs[m]}/")
  done
  
  node_ips_fault_ids=()
  for m in "${!nodeIPs[@]}"; do
    node_ips_fault_ids+=("${nodeIPs[m]},${faultIDs[m]}")
  done

  getqq "${node1_ip}" "qq"

  ssmput "last-run-status" "$region" "$stkname" "Forming first quorum and configuring cluster"

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_DEBUG\", \"reset\": false}"
  echo "Quorom Formation Parameters"
  echo "eula_accepted: true"
  echo "cluster_name: $cluster_name"
  echo "node_ips_fault_ids: [${node_ips_fault_ids[@]}]"
  echo "fault_domain_ids: [$fault_domain_ids]"  
  echo "admin_password: $def_password"
  echo "host_instance_id: $def_password"
  echo "object_storage_uris: [${mod_bucket_URIs[@]}]"
  echo "usable_capacity_clamp: $cluster_persistent_capacity_limit"
  echo "pstore_class: $pstore_class"
  echo "product_type: $product_type"  

################################################################################################################
# KMAC: 20241122 Hacks below are to add "test_tunables_enabled" for the GNS R/W DEMO VIDEO for RI
#
# Note:  I also had to comment out the tunable multi_stream_prefetcher_stream_limit_per_file from being applied 
#        For the single node cluster
#
################################################################################################################

  echo "KMAC: MODIFICATION START" 
  set -x 

  if [ "$single_node_cluster" == "true" ]; then

    echo "KMAC: SINGLE NODE CLUSTER" 

    ip_list="$node_ips"
    ip_list=${ip_list//,/\" \"}
    ip_list=${ip_list/#/\"}
    ip_list=${ip_list/%/\"}  

    bucket_list=${mod_bucket_URIs[@]}
    bucket_list=${bucket_list//,/\", \"}
    bucket_list=${bucket_list/#/\"}
    bucket_list=${bucket_list/%/\"}

    json_payload=$(cat <<EOF
{
  "test_cluster_creation_options": {"flags": ["test_tunables_enabled"]},
  "eula_accepted": true,
  "cluster_name": "$cluster_name",
  "node_ips": [$ip_list],
  "admin_password": "$def_password",
  "host_instance_id": "$def_password",
  "object_storage_uris": [$bucket_list],
  "usable_capacity_clamp": "$cluster_persistent_capacity_limit",
  "pstore_class": "$pstore_class",
  "access_tier": "$access_tier"
}
EOF
)

echo "DEBUG: JSON PAYLOAD before the create call: "
echo "$json_payload"
echo ""

$qqh raw --content-type application/json POST /v1/debug/cluster/create <<<"$json_payload"


  else
#    $qqh --debug create_object_backed_cluster --cluster-name $cluster_name \
#      --admin-password $def_password --accept-eula \
#      --host-instance-id $def_password --product-type $product_type \
#      --object-storage-uris ${mod_bucket_URIs[@]} \
#      --node-ips-and-fault-domains ${node_ips_fault_ids[@]} \
#      --usable-capacity-clamp $cluster_persistent_capacity_limit

    echo "KMAC: MULTI NODE CLUSTER" 

    ###
    # KMac: Transform mod_bucket_URIs into a properly formatted JSON array
    # 1/ Using printf to format each element as a JSON string.
    # 2/ Adding commas and trimming the trailing comma.
    ###
    if [ ${#mod_bucket_URIs[@]} -eq 0 ]; then
      mod_bucket_URIs_json="[]"
    else
      mod_bucket_URIs_json=$(printf '"%s", ' "${mod_bucket_URIs[@]}")
      mod_bucket_URIs_json="[${mod_bucket_URIs_json%, }]"
    fi

    ###
    # KMac: Transform node_ips_fault_ids into a properly formatted JSON array of objects
    ###
    if [ ${#node_ips_fault_ids[@]} -eq 0 ]; then
      node_ips_fault_ids_json="[]"
    else
      node_ips_fault_ids_json="["
      for entry in "${node_ips_fault_ids[@]}"; do
        ip=$(echo "$entry" | cut -d',' -f1)
        fault_domain=$(echo "$entry" | cut -d',' -f2)
        if [ "$fault_domain" == "none" ]; then
          fault_domain=null
        else
          fault_domain="\"$fault_domain\""
        fi
        node_ips_fault_ids_json+="{\"node_ip\": \"$ip\", \"fault_domain_id\": $fault_domain}, "
      done
      node_ips_fault_ids_json="${node_ips_fault_ids_json%, }]"
    fi

json_payload=$(cat <<EOF
{
  "test_cluster_creation_options": {"flags": ["test_tunables_enabled"]},
  "eula_accepted": true,
  "cluster_name": "$cluster_name",
  "admin_password": "$def_password",
  "host_instance_id": "$def_password",
  "object_storage_uris": $mod_bucket_URIs_json,
  "usable_capacity_clamp": "$cluster_persistent_capacity_limit",
  "product_type": "$product_type",
  "node_ips_and_fault_domains": $node_ips_fault_ids_json,
  "pstore_class": "$pstore_class",
  "access_tier": "$access_tier"
}
EOF
)
    set +x 
    echo "DEBUG: JSON PAYLOAD before the create call: "
    echo "$json_payload"
    echo ""
    set -x 

    $qqh --debug raw --content-type application/json POST /v1/debug/cluster/create <<<"$json_payload"

  fi

################################################################################################################
# KMAC: Done Hacking 
################################################################################################################


  until $qqh node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Waiting for Quorum"
  done
  echo "First Quorum formed"
  
  cluster_id=$($qqh node_state_get | grep "cluster_id" | tr -d '",')
  uuid=${cluster_id//"cluster_id: "/}

  ssmput "uuid" "$region" "$stkname" "$uuid"
  ssmput "node-ips" "$region" "$stkname" "$node_ips"
  ssmput "fault-domain-ids" "$region" "$stkname" "$fault_domain_ids"
  ssmput "creation-number-AZs" "$region" "$stkname" "$num_azs"
  ssmput "cluster-type" "$region" "$stkname" "CNQ=$cnq_type, S3=$s3_type"
  ssmput "soft-capacity-limit" "$region" "$stkname" "$cluster_persistent_capacity_limit"
  ssmput "bucket-uris" "$region" "$stkname" "$cluster_persistent_bucket_uris"
  ssmput "bucket-names" "$region" "$stkname" "$cluster_persistent_bucket_names"    
  ssmput "last-run-status" "$region" "$stkname" "Setting cluster tunables if necessary"

  $qqh login -u admin -p $def_password

  calc_tun_refill_Bps=0

  if [ "$tun_refill_IOPS" != "0" ]; then
    $qqh raw PUT /v1/tunables/credit_accountant_io_refill_iops <<<"{\"configured_value\": \"$tun_refill_IOPS\"}"
  fi
  if [ "$tun_refill_Bps" != "0" ] && [ "$tun_disk_count" != "0" ]; then
    calc_tun_refill_Bps=$(( $tun_refill_Bps * 1000 * 1000 / 4096 ))
    $qqh raw PUT /v1/tunables/credit_accountant_th_refill_blocks_per_second <<<"{\"configured_value\": \"$calc_tun_refill_Bps\"}" 
  fi
  if [ "$tun_read_Prom1" == "yes" ]; then
    $qqh raw PUT /v1/tunables/tiered_promotion_system_promotes_data_on_first_read <<<"{\"configured_value\": \"true\"}"
  fi 
  if [ "$tun_read_Thold" != "0" ]; then
    $qqh raw PUT /v1/tunables/commit_policy_bypass_read_tier_threshold_blocks <<<"{\"configured_value\": \"$tun_read_Thold\"}" 
  fi
#  if [ "$tun_prefetch_Streams" != "0" ]; then
#    $qqh raw PUT /v1/tunables/multi_stream_prefetcher_stream_limit_per_file <<<"{\"configured_value\": \"$tun_prefetch_Streams\"}" 
#  fi
  if [ "$tun_EBS_BW" != "0" ]; then
    $qqh raw PUT /v1/tunables/vm_disk_throughput_model_megabytes_per_second <<<"{\"configured_value\": \"$tun_EBS_BW\"}"
  fi
  if [ "$tun_EC2_BW" != "0" ]; then
    $qqh raw PUT /v1/tunables/vm_network_saturation_model_threshold_megabytes_per_second <<<"{\"configured_value\": \"$tun_EC2_BW\"}"
  fi
  
  $qqh raw POST /v1/debug/quorum/abandon-series </dev/null

  until $qqh node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Bouncing quorum to apply tunables"
  done
  echo "Second quorum formed with tunables"

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_INFO\", \"reset\": false}"

  ssmput "tunables" "$region" "$stkname" "refill_IOPS=$tun_refill_IOPS, refill_Bps=$calc_tun_refill_Bps, read_Prom1=$tun_read_Prom1, read_Thold=$tun_read_Thold, prefetch_Streams=$tun_prefetch_Streams, EBS_BW=$tun_EBS_BW, EC2_BW=$tun_EC2_BW"

  $qqh audit_set_cloudwatch_config --enable --log-group-name /qumulo/$stkname-audit-log --region $region
  if [[ ! -z "$float_ips" ]]; then
    $qqh network_mod_network --network-id 1 --floating-ip-ranges $float_ips
    ssmput "float-ips" "$region" "$stkname" "$float_ips"
    ssmput "number-float-ips" "$region" "$stkname" "$num_float_ips"
    ssmput "max-float-ips" "$region" "$stkname" "$max_float_ips"    
  fi
  $qqh change_password -o $def_password -p $admin_password

  #For future
	#echo "	--Creating config-backup folder for all backups"
	#aws s3api put-object --region "$region" --bucket "${bucketNames[0]}" --key "config-backup/" --content-length 0 >/dev/null 2>&1
  #ssmput "last-run-status" "$region" "$stkname" "Created backup folder: s3://${bucketNames[0]}/config-backup"

elif [ "$new_cluster" == "true" ] && [ "$replace_cluster" == "true" ]; then
  #ip_list="$node_ips"
  #primary_list=${ip_list//,/ }

  node_ips_fault_ids=()
  for m in "${!nodeIPs[@]}"; do
    node_ips_fault_ids+=("${nodeIPs[m]},${faultIDs[m]}")
  done  
  
  IFS=', ' read -r -a existingIPs <<< $(ssmget "node-ips" "$region" "$existing_stkname")
  IFS=', ' read -r -a existingIDs <<< $(ssmget "instance-ids" "$region" "$existing_stkname")

  getqq "${existingIPs[0]}" "qq"

  #Check to make sure the number of floating IPs in the previous cluster can be supported by the new cluster's instance type if SAZ
  if [[ "$num_azs" -eq "1" ]]; then
    existing_float_ips=$(ssmget "float-ips" "$region" "$existing_stkname")
    existing_num_float_ips=$(ssmget "number-float-ips" "$region" "$existing_stkname")

    if [[ "$existing_num_float_ips" -gt "$max_float_ips" ]]; then
      echo "Error, the EC2 instance type chosen for the replacement cluster can't support the number of floating IPs in the existing cluster.  Destroy this deployment and redeploy."
      ssmput "last-run-status" "$region" "$stkname" "Error, the EC2 instance type chosen for the replacement cluster can't support the number of floating IPs in the existing cluster.  Destroy this deployment and redeploy."
      exit 1
    fi
  fi

  ssmput "last-run-status" "$region" "$stkname" "Detected CLUSTER REPLACE.  Adding new security group to existing nodes and detecting node IDs."

  existingSGIDs=$(aws ec2 describe-instances --region $region --instance-ids ${existingIDs[0]} --query "Reservations[].Instances[].SecurityGroups[].GroupId[]" --output text)
  existingSGIDs+=" $cluster_sg_id"

  #Get Qumulo node_ids from existing cluster
  #-----------------------------------------
  for m in "${!existingIPs[@]}"; do
    qnodeState=$(./qq --host ${existingIPs[m]} node_state_get)
    qnodeID=$(echo "$qnodeState" | grep "node_id")
    qid=${qnodeID//[!0-9.]/}
    existingNodeIDs+=("$qid ")
    echo "node_id=$qid"

    aws ec2 modify-instance-attribute --region $region --instance-id ${existingIDs[m]} --groups $existingSGIDs
  done   

  ssmput "last-run-status" "$region" "$stkname" "Detected CLUSTER REPLACE.  Adding new nodes to quorum and removing existing nodes from quorum."

  #now call for replace
  ./qq --host ${existingIPs[0]} login -u admin -p $admin_password
  if [[ "$num_azs" -gt "1" ]]; then
    ./qq --host ${existingIPs[0]} network_mod_network --network-id 1 --floating-ip-ranges ""
  fi
  ./qq --host ${existingIPs[0]} raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_DEBUG\", \"reset\": false}"
  ./qq --host ${existingIPs[0]} modify_object_backed_cluster_membership --node-ips-and-fault-domains ${node_ips_fault_ids[@]} --batch

  ssmput "last-run-status" "$region" "$stkname" "Detected CLUSTER REPLACE.  Waiting for new quorum."

  until $qqh node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Waiting for Quorum"
  done
  echo "New Quorum formed"
  
  sleep 1

  ssmput "last-run-status" "$region" "$stkname" "Detected CLUSTER REPLACE.  New quorum formed, validating node replacement."
  
  allNodesList=()
  inNodesList=()
  outNodesList=()

  until [ ${#allNodesList[@]} -eq ${#nodeIPs[@]} ] && [ ${#inNodesList[@]} -eq ${#nodeIPs[@]} ] && [ ${#outNodesList[@]} -eq 0 ]; do
    newQuorum=$($qqh raw GET /v1/debug/quorum/details )

    allNodesRaw=$(echo $newQuorum | grep -Po '"all_nodes":.*?\]')
    inNodesRaw=$(echo $newQuorum | grep -Po '"in_nodes":.*?\]')
    outNodesRaw=$(echo $newQuorum | grep -Po '"out_nodes":.*?\]')

    allNodes=${allNodesRaw/\"all_nodes\": [/}
    allNodes=$(echo $allNodes | tr -d "]")

    inNodes=${inNodesRaw/\"in_nodes\": [/}
    inNodes=$(echo $inNodes | tr -d "]")

    outNodes=${outNodesRaw/\"out_nodes\": [/}
    outNodes=$(echo $outNodes | tr -d "]")

    IFS=', ' read -r -a allNodesList <<< "$allNodes"
    IFS=', ' read -r -a inNodesList <<< "$inNodes"
    IFS=', ' read -r -a outNodesList <<< "$outNodes"

    sleep 10
  done

  for m in "${!allNodesList[@]}"; do
    if [[ "${existingNodeIDs[@]}" =~ "${allNodesList[m]}" ]]; then
      echo "  **Old Node: ${allNodesList[m]} not removed from quorum.  Slack Support."
      exit 1
    fi
  done

  ssmput "last-run-status" "$region" "$stkname" "Detected CLUSTER REPLACE: New quorum formed with ${#nodeIPs[@]} new nodes as requested."

  existing_cluster_type=$(ssmget "cluster-type" "$region" "$existing_stkname")

  cluster_id=$($qqh node_state_get | grep "cluster_id" | tr -d '",')
  uuid=${cluster_id//"cluster_id: "/}

  ssmput "uuid" "$region" "$stkname" "$uuid"
  ssmput "node-ips" "$region" "$stkname" "$node_ips"
  ssmput "fault-domain-ids" "$region" "$stkname" "$fault_domain_ids"
  ssmput "creation-number-AZs" "$region" "$stkname" "$num_azs"
  ssmput "cluster-type" "$region" "$stkname" "$existing_cluster_type"
  ssmput "soft-capacity-limit" "$region" "$stkname" "$cluster_persistent_capacity_limit"
  ssmput "bucket-uris" "$region" "$stkname" "$cluster_persistent_bucket_uris"
  ssmput "bucket-names" "$region" "$stkname" "$cluster_persistent_bucket_names"
  if [[ "$num_azs" -eq "1" ]]; then
    ssmput "float-ips" "$region" "$stkname" "$existing_float_ips"
    ssmput "number-float-ips" "$region" "$stkname" "$existing_num_float_ips"
    ssmput "max-float-ips" "$region" "$stkname" "$max_float_ips"  
  else
    ssmput "float-ips" "$region" "$stkname" "null"
    ssmput "number-float-ips" "$region" "$stkname" "null"
    ssmput "max-float-ips" "$region" "$stkname" "$max_float_ips"  
  fi
  ssmput "last-run-status" "$region" "$stkname" "Setting cluster tunables if necessary"

  calc_tun_refill_Bps=0

  if [ "$tun_refill_IOPS" != "0" ]; then
    $qqh raw PUT /v1/tunables/credit_accountant_io_refill_iops <<<"{\"configured_value\": \"$tun_refill_IOPS\"}"
  fi
  if [ "$tun_refill_Bps" != "0" ] && [ "$tun_disk_count" != "0" ]; then
    calc_tun_refill_Bps=$(( $tun_refill_Bps * 1000 * 1000 / 4096 ))
    $qqh raw PUT /v1/tunables/credit_accountant_th_refill_blocks_per_second <<<"{\"configured_value\": \"$calc_tun_refill_Bps\"}" 
  fi
  if [ "$tun_read_Prom1" == "yes" ]; then
    $qqh raw PUT /v1/tunables/tiered_promotion_system_promotes_data_on_first_read <<<"{\"configured_value\": \"true\"}"
  fi   
  if [ "$tun_read_Thold" != "0" ]; then
    $qqh raw PUT /v1/tunables/commit_policy_bypass_read_tier_threshold_blocks <<<"{\"configured_value\": \"$tun_read_Thold\"}" 
  fi
#  if [ "$tun_prefetch_Streams" != "0" ]; then
#    $qqh raw PUT /v1/tunables/multi_stream_prefetcher_stream_limit_per_file <<<"{\"configured_value\": \"$tun_prefetch_Streams\"}" 
#  fi
  if [ "$tun_EBS_BW" != "0" ]; then
    $qqh raw PUT /v1/tunables/vm_disk_throughput_model_megabytes_per_second <<<"{\"configured_value\": \"$tun_EBS_BW\"}"
  fi
  if [ "$tun_EC2_BW" != "0" ]; then
    $qqh raw PUT /v1/tunables/vm_network_saturation_model_threshold_megabytes_per_second <<<"{\"configured_value\": \"$tun_EC2_BW\"}"
  fi

  $qqh raw POST /v1/debug/quorum/abandon-series </dev/null

  until $qqh node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Bouncing quorum to apply tunables"
  done
  echo "Second quorum formed with tunables"

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_INFO\", \"reset\": false}"

  ssmput "tunables" "$region" "$stkname" "refill_IOPS=$tun_refill_IOPS, refill_Bps=$calc_tun_refill_Bps, read_Prom1=$tun_read_Prom1, read_Thold=$tun_read_Thold, prefetch_Streams=$tun_prefetch_Streams, EBS_BW=$tun_EBS_BW, EC2_BW=$tun_EC2_BW"

elif [ "$add_nodes" == "true" ] && [ "$replace_cluster" != "true" ]; then
  ssmput "last-run-status" "$region" "$stkname" "Quorum already exists, adding nodes to cluster"

  $qqh login -u admin -p $admin_password

  if [[ ! -z "$float_ips" ]]; then
    delim=""
    halfFloatIPs=""
    for m in "${!newFIPs[@]}"; do
      if [ $m -lt 40 ]; then
        halfFloatIPs="$halfFloatIPs$delim${newFIPs[m]}"
        delim=", "
      fi
    done
    $qqh network_mod_network --network-id 1 --floating-ip-ranges $halfFloatIPs
  fi

  node_ips_fault_ids=()
  for m in "${!nodeIPs[@]}"; do
    node_ips_fault_ids+=("${nodeIPs[m]},${faultIDs[m]}")
  done

  #$qqh add_nodes --node-ips ${upgradeIPs[@]} --batch
  $qqh modify_object_backed_cluster_membership --node-ips-and-fault-domains ${node_ips_fault_ids[@]} --batch

  until ./qq --host ${upgradeIPs[0]} node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Waiting for Quorum"
  done
  echo "Quorum formed"
  ssmput "node-ips" "$region" "$stkname" "$node_ips"
  ssmput "fault-domain-ids" "$region" "$stkname" "$fault_domain_ids"  

  if [[ ! -z "$float_ips" ]]; then
    $qqh network_mod_network --network-id 1 --floating-ip-ranges $float_ips
    ssmput "float-ips" "$region" "$stkname" "$float_ips"
    ssmput "number-float-ips" "$region" "$stkname" "$num_float_ips"  
    ssmput "max-float-ips" "$region" "$stkname" "$max_float_ips"            
  fi

elif [ "$mod_FIPs" == "YES" ]; then
  ssmput "last-run-status" "$region" "$stkname" "Quorum already exists, no nodes to add, modifying floating IPs"
  $qqh login -u admin -p $admin_password
  $qqh network_mod_network --network-id 1 --floating-ip-ranges $float_ips
  ssmput "float-ips" "$region" "$stkname" "$float_ips"
  ssmput "number-float-ips" "$region" "$stkname" "$num_float_ips"  
  ssmput "max-float-ips" "$region" "$stkname" "$max_float_ips"    
fi

if [ "$new_cluster" != "true" ] && [ "$add_nodes" != "true" ] && [ "$single_node_cluster" != "true" ]; then
  ssmput "node-ips" "$region" "$stkname" "$node_ips"
  ssmput "fault-domain-ids" "$region" "$stkname" "$fault_domain_ids"    
fi

if [ "$single_node_cluster" == "true" ]; then
  ssmput "instance-ids" "$region" "$stkname" "${newIDs[0]}"
else
  ssmput "instance-ids" "$region" "$stkname" "$instance_ids"
fi  

ssmput "last-run-status" "$region" "$stkname" "Updating cluster tags"

for m in "${!newIDs[@]}"; do
  (( n = m + 1 ))
  qnodeState=$(./qq --host ${nodeIPs[m]} node_state_get)
  qnodeID=$(echo "$qnodeState" | grep "node_id")
  qid=${qnodeID//[!0-9]/}

  aws ec2 create-tags --region $region --resources ${newIDs[m]} --tags "Key=Name,Value=$stkname-node-$n-$qid"  
done

#ENA Express - only supported on certain instance types and sizes and can create issues with instance type/size changes if not done with cluster replace
if [ "$new_cluster" == "true" ] || [ "$replace_cluster" == "true" ] || [ "$add_nodes" == "true" ]; then
  if [ "$ena_express" == "yes" ]; then
    ssmput "last-run-status" "$region" "$stkname" "Enabling ENA Express"
    for m in "${!newIDs[@]}"; do
      ec2Eni=$(aws ec2 describe-instances --region $region --instance-ids ${newIDs[m]} --query "Reservations[].Instances[].NetworkInterfaces[].NetworkInterfaceId" --output text)
      aws ec2 modify-network-interface-attribute --network-interface-id $ec2Eni  --ena-srd-specification "EnaSrdEnabled=true"
    done
  else
    echo "$ec2Type doesn't support ENA Express"
  fi
fi

if [ "$add_buckets" == "true" ]; then
  for m in "${!newBucketNames[@]}"; do
    contents=$(aws s3api list-objects-v2 --region $region --bucket ${newBucketNames[m]} --max-items 1)
    if [[ "$contents" == *"Contents"* ]]; then
      echo "  **BUCKET NOT EMPTY, Exiting.  Empty bucket(s) and restart provisioner."
      ssmput "last-run-status" "$region" "$stkname" "Bucket ${newBucketNames[m]} NOT EMPTY. Exiting. Empty the new buckets you wish to add and restart provisioner."
      exit 1
    else    
      echo "  **BUCKET ${newBucketNames[m]} EMPTY"
    fi
  done

  ssmput "last-run-status" "$region" "$stkname" "Adding buckets for persistent storage & increasing soft capacity limit"

  mod_bucket_URIs=()
  for m in "${!newBucketURIs[@]}"; do
    mod_bucket_URIs+=("https://${newBucketURIs[m]}/")
  done
  
  getqq "${node1_ip}" "qq"
  $qqh login -u admin -p $admin_password

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_DEBUG\", \"reset\": false}"
  echo "Bucket Add Parameters"
  echo "object_storage_uris: [${newBucketURIs[@]}]"
  echo "usable_capacity_clamp: $cluster_persistent_capacity_limit"

  $qqh add_object_storage_uris --uris ${mod_bucket_URIs[@]}
  $qqh raw --content-type application/json PUT /v1/capacity/clamp <<< "{\"capacity_clamp\": \"$cluster_persistent_capacity_limit\"}"

  until $qqh node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Waiting for Quorum"
  done
  echo "Buckets added, soft capacity limit increased and Quorum formed"

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_INFO\", \"reset\": false}"

  ssmput "soft-capacity-limit" "$region" "$stkname" "$cluster_persistent_capacity_limit"
  ssmput "bucket-uris" "$region" "$stkname" "$cluster_persistent_bucket_uris"
  ssmput "bucket-names" "$region" "$stkname" "$cluster_persistent_bucket_names"    
fi

if [ "$increase_limit" == "true" ]; then
  ssmput "last-run-status" "$region" "$stkname" "Increasing soft capacity limit"

  getqq "${node1_ip}" "qq"
  $qqh login -u admin -p $admin_password

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_DEBUG\", \"reset\": false}"
  echo "usable_capacity_clamp: $cluster_persistent_capacity_limit"

  $qqh raw --content-type application/json PUT /v1/capacity/clamp <<< "{\"capacity_clamp\": \"$cluster_persistent_capacity_limit\"}"

  until $qqh node_state_get | grep -q "ACTIVE"; do
    sleep 5
    echo "Waiting for Quorum"
  done
  echo "Soft capacity limit increased and Quorum formed"

  $qqh raw PUT /v1/conf/log/module/%2F <<<"{\"level\": \"QM_LOG_INFO\", \"reset\": false}"

  ssmput "soft-capacity-limit" "$region" "$stkname" "$cluster_persistent_capacity_limit"
fi

#For future use
#ssmput "last-run-status" "$region" "$stkname" "Backing up node configurations"
#backup "newIDs" "$region" "${bucketURIs[0]}" "config-backup"

ssmput "last-run-status" "$region" "$stkname" "Tagging EBS volumes & updating EBS IOPS/Tput if applicable"
tagvols "newIDs" "$region" "$stkname" "$f_iops" "$f_tput"

ssmput "last-run-status" "$region" "$stkname" "Shutting down provisioning instance"
