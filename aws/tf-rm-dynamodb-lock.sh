

aws dynamodb scan --table-name qumulo-specai-tfstate

aws dynamodb delete-item --table-name qumulo-specai-tfstate --key '{"LockID": {"S": "LockID"}}'
