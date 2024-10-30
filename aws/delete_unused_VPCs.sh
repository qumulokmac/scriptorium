#!/bin/bash

echo "Deleting a bunch of junk"
for vpc in vpc-2cf1f544 vpc-55e24c33 vpc-1ca39574 vpc-32e8eb4a vpc-4486532c vpc-84bd0cfd vpc-4070e229 vpc-3e92f054 vpc-e66d2c8f vpc-2c7cb34a vpc-f7158a9c vpc-b811eede vpc-2771a54c vpc-7c1cda1a vpc-762bff10
do
        aws ec2 delete-vpc --vpc-id $vpc --dry-run
done
