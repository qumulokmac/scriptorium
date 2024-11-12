aws ec2 modify-vpc-attribute --vpc-id vpc-03898071954204955 --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id vpc-03898071954204955 --enable-dns-hostnames

sleep 10 
# aws ec2 modify-vpc-attribute --vpc-id vpc-03898071954204955 --enable-dns-support "{\"Value\":true}"
# aws ec2 modify-vpc-attribute --vpc-id vpc-03898071954204955 --enable-dns-hostnames "{\"Value\":true}"

aws ec2 describe-vpcs --vpc-ids vpc-03898071954204955 --query "Vpcs[*].{DnsSupport:EnableDnsSupport, DnsHostnames:EnableDnsHostnames}" --output table
