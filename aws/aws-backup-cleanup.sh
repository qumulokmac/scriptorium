function deletebackups {
region=us-west-2
attempts=0
deleted=-1
while [ $attempts -le 60 -a $deleted -ne 0 ]; do
((attempts++))
sleep 5
for i in $(aws backup list-recovery-points-by-backup-vault --backup-vault-name ${1} --region us-west-2 --query RecoveryPoints[*].Rec
overyPointArn --output text); do
aws backup delete-recovery-point --backup-vault-name ${1} --recovery-point-arn $i --region us-west-2
done
aws backup delete-backup-vault --backup-vault-name ${1} --region us-west-2
deleted=$?
done
}
deletebackups AWS-Backup-Reinvent2021-Workshop-SidBackupStack-WIRG0NBJ7HLG-silver-vault
deletebackups SID-SidBackupStack-gold-vault
