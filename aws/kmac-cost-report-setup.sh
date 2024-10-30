###
# Steps to setup a cost report by tags 
###

###
# Create an S3 bucket (if one doesnt exist)
###
aws s3api create-bucket --bucket kmac-cost-report --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
    "Location": "http://kmac-cost-report.s3.amazonaws.com/"


###
# Create a CUR report
###
aws cur put-report-definition \
    --report-definition '{
        "ReportName": "kmac-cost-report",
        "TimeUnit": "DAILY",
        "Format": "textORcsv",
        "Compression": "GZIP",
        "AdditionalSchemaElements": ["RESOURCES"],
        "S3Bucket": "kmac-cost-report",
        "S3Prefix": "reports/",
        "S3Region": "us-west-2",
        "ReportVersioning": "OVERWRITE_REPORT"
    }'

###
# Create a Cost and Usage report filtered by the tag:
###
aws ce get-cost-and-usage \
    --time-period Start=$(date -v-1d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --filter '{
        "Tags": {
            "Key": "Project",
            "Values": ["cnqdemo"]
        }
    }'

###
# Set up a simple cron job that runs once a day on your macbook
# chmod 755 cost_report.sh
# crontab -e
# 0 1 * * * /Users/kmcdonald/bin/kmacs-aws-cost-reporter.sh
# crontab -l
###

###
# MacOS Bash script 
###

#!/bin/bash
# /Users/kmcdonald/bin/kmacs-aws-cost-reporter.sh

START_DATE=$(date -d "yesterday" +%Y-%m-%d)
END_DATE=$(date -d "today" +%Y-%m-%d)

aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --filter '{
        "Tags": {
            "Key": "Project",
            "Values": ["cnqdemo"]
        }
    }' \
    --output text > /Users/kmcdonald/cur/kmac-aws-cost-report-$START_DATE.txt







