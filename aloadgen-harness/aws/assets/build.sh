#!/opt/homebrew/bin/bash
################################################################################
#
# ALG Build Script with Error Checking
#
################################################################################

export COPYFILE_DISABLE=true

cd ~/git/scriptorium/aloadgen-harness/aws/assets || { echo "Error: Failed to change to directory /Users/kmcdonald/git/aloadgen"; exit 1; }

DTS=$(date +%Y%m%d%H)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get the current date and time."
    exit 1
fi

mv alg_suite.tgz archive/alg_suite.tgz-$DTS
if [ $? -ne 0 ]; then
    echo "Warning: Failed to archive the prior alg_suite.tgz."
fi

find . -name ".DS_Store" -type f -delete
find . -name "._*" -type f -delete

tar cvfz alg_suite.tgz -C alg_suite_assets .
if [ $? -ne 0 ]; then
    echo "Error: Failed to create tarball alg_suite.tgz."
    exit 1
fi

aws s3 cp alg_suite.tgz s3://bucket-of-bytes/scripts/alg_suite.tgz
if [ $? -ne 0 ]; then
    echo "Error: Failed to upload alg_suite.tgz to S3."
    exit 1
fi

SIG=$(aws s3 presign s3://bucket-of-bytes/scripts/alg_suite.tgz --region us-east-1 --expires-in 604800)
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate a presigned URL."
    exit 1
fi

echo ""
echo "Update the userdata script with \"aws s3 cp alg_ud.sh s3://bucket-of-bytes/scripts/alg_ud.sh\" using the URL for the asset below."
echo ""
echo $SIG
echo ""
