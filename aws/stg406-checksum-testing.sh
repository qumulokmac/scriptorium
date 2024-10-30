
export ROOTVOL=$(aws ec2 describe-volumes | jq -r '.Volumes[0].VolumeId');
echo "ROOTVOL has been set to $ROOTVOL"

aws ec2 create-snapshot --volume-id $ROOTVOL --description parentsnap

export PARENTSNAP=$(aws ec2 describe-snapshots --owner self | jq -r '.Snapshots[0].SnapshotId');
echo "PARENTSNAP has been set to $PARENTSNAP"

while (true)
do
   STATUS=$(aws ec2 describe-snapshots --owner self | jq -r '.Snapshots[0].State')
   sleep 15
   echo "Is it done? $STATUS"
   read  answer
   if [ "$answer" != "${answer#[Yy]}" ]
   then
      break
   else
      continue
   fi
done

export CLIENTTOKEN=$(uuidgen)
aws ebs start-snapshot --volume-size 8 --parent-snapshot $PARENTSNAP --timeout 60 --client-token $CLIENTTOKEN --description=incrementalsnap

export INCRSNAP=$(aws ec2 describe-snapshots --owner self --filters 'Name=description,Values=incrementalsnap' | jq -r '.Snapshots[0].SnapshotId');
echo "INCRSNAP has been set to $INCRSNAP"

dd if=/dev/urandom of=/tmp/first.block bs=524288 count=1

export CHECKSUM01=$(openssl dgst -binary -sha256 /tmp/first.block | base64)
echo "The SHA256 CHECKSUM01 is $CHECKSUM01"

aws ebs put-snapshot-block --snapshot-id $INCRSNAP --block-index 1000 --data-length 524288 --block-data /tmp/first.block --checksum $CHECKSUM01 --checksum-algorithm SHA256

dd if=/dev/urandom of=/tmp/second.block bs=524288 count=1

export CHECKSUM02=$(openssl dgst -binary -sha256 /tmp/second.block | base64)
echo "The SHA256 CHECKSUM02 is $CHECKSUM02"

aws ebs put-snapshot-block --snapshot-id $INCRSNAP --block-index 2000 --data-length 524288 --block-data /tmp/second.block --checksum $CHECKSUM02 --checksum-algorithm SHA256


####
# Below is where I believe the problem is...
####

BLOCKONE=$(sha256sum /tmp/first.block |cut -d' ' -f1)
BLOCKTWO=$(sha256sum /tmp/second.block |cut -d' ' -f1)
CHECKSUMOFSUMS=$(echo -n $BLOCKONE$BLOCKTWO | openssl dgst -binary -sha256 | base64)

echo "The checksum of all checksums is $CHECKSUMOFSUMS"


aws ebs complete-snapshot --snapshot-id $INCRSNAP --changed-blocks-count 2 --checksum $CHECKSUMOFSUMS --checksum-algorithm SHA256 --checksum-aggregation-method LINEAR