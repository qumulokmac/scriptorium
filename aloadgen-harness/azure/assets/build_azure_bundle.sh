#!/opt/homebrew/bin/bash
################################################################################
#
# The Azure version of the ALG Build Script with Error Checking
#
################################################################################

export COPYFILE_DISABLE=true

BASE_DIR="/Users/kmcdonald/git/scriptorium/aloadgen-harness/azure/assets"
cd $BASE_DIR || { echo "Error: Failed to change to directory $BASE_DIR"; exit 1; }

DTS=$(date +%Y%m%d%H)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get the current date and time."
    exit 1
fi

mv azure_alg_suite.tgz archive/azure_alg_suite.tgz-$DTS
if [ $? -ne 0 ]; then
    echo "Warning: Failed to archive the prior azure_alg_suite.tgz."
fi

find . -name ".DS_Store" -type f -delete
find . -name "._*" -type f -delete

tar cvfz azure_alg_suite.tgz -C alg_suite_assets .
if [ $? -ne 0 ]; then
    echo "Error: Failed to create tarball azure_alg_suite.tgz."
    exit 1
fi

aws s3 cp azure_alg_suite.tgz s3://bucket-of-bytes/scripts/azure_alg_suite.tgz
if [ $? -ne 0 ]; then
    echo "Error: Failed to upload azure_alg_suite.tgz to S3."
    exit 1
fi

SIG=$(aws s3 presign s3://bucket-of-bytes/scripts/azure_alg_suite.tgz --expires-in 604800)
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate a presigned URL."
    exit 1
fi

echo ""
echo "Update the userdata script azure_linux_ud.sh using the Presigned URL below:"
echo ""
echo $SIG
echo ""
