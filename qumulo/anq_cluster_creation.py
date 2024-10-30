"""
Script: anq_cluster_creation.py
Author: kmac@qumulo.com
Date: April 29th, 2024
Description: This script submits a cluster creation request to Azure using the az CLI for the STAGING environment.
             Added code to capture and print "Azure-AsyncOperation" from the response header

Example Usage:
python azure_cluster_creation.py \
--subscription your-subscription-code-here \
--fs-name cluster-name \
--user-email emailaddr@qumulo.com \
--location region \
--availability-zone zone \
--qumulo-num-nodes num_nodes \
--rg-name resource-group-name \
--cluster-subnet-id /subscriptions/$subscription/resourceGroups/$rg-name/providers/Microsoft.Network/virtualNetworks/$vnet/subnets/$subnet

"""

import subprocess
import json
import argparse

def submit_cluster_creation(subscription, fs_name, user_email, location, availability_zone, qumulo_num_nodes, rg_name, cluster_subnet_id):
    body = {
        'properties': {
            'marketplaceDetails': {
                'planId': 'azure-native-qumulo-hot-cold-iops',
                'offerId': 'qaas-staging-mpp'
            },
            'userDetails': {'email': user_email},
            'delegatedSubnetId': cluster_subnet_id,
            'storageSku': 'Hot',
            'adminPassword': 'Admin123',
            'availabilityZone': availability_zone
        },
        'location': location,
        'tags': {
            'ProvisionResource': '55e031c5d497a3508838f44ec8767c84',
            'qumulo_num_nodes': str(qumulo_num_nodes),
            'qumulo_production': 'true'
        }
    }

    body_str = json.dumps(body, indent=4)
    print("Submitting cluster create for:\n")
    print(body_str)
    print("\n")

    try:
        result = subprocess.run(
            [
                'az',
                'rest',
                '--method',
                'PUT',
                '--url',
                f'https://centraluseuap.management.azure.com/subscriptions/{subscription}/resourceGroups/{rg_name}/providers/Qumulo.Storage/fileSystems/{fs_name}?api-version=2024-02-01-preview',
                '--resource',
                'https://management.azure.com/',
                '--body',
                body_str,
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        headers = result.stdout.splitlines()
        azure_async_operation_header = None
        for header in headers:
            if header.startswith("Azure-AsyncOperation"):
                azure_async_operation_header = header.split(": ", 1)[1].strip()
                break

        if azure_async_operation_header:
            print("Azure-AsyncOperation Header:")
            print(azure_async_operation_header)
        else:
            print("Azure-AsyncOperation Header not found.")

    except subprocess.CalledProcessError as e:
        print("Error:", e)
        print("Standard Output:")
        print(e.stdout)
        print("Standard Error:")
        print(e.stderr)


def main():
    usage = "python script.py --subscription SUB --fs-name FS --user-email EMAIL --location LOC --availability-zone AZ --qumulo-num-nodes NODES --rg-name RG --cluster-subnet-id SUBNET_ID"
    parser = argparse.ArgumentParser(description='Submit cluster creation to Azure.', usage=usage)
    parser.add_argument('--subscription', type=str, help='Azure subscription ID', required=True)
    parser.add_argument('--fs-name', type=str, help='File system name', required=True)
    parser.add_argument('--user-email', type=str, help='User email', required=True)
    parser.add_argument('--location', type=str, help='Location', required=True)
    parser.add_argument('--availability-zone', type=str, help='Availability zone', required=True)
    parser.add_argument('--qumulo-num-nodes', type=int, help='Number of Qumulo nodes', required=True)
    parser.add_argument('--rg-name', type=str, help='Resource group name', required=True)
    parser.add_argument('--cluster-subnet-id', type=str, help='Cluster subnet ID', required=True)

    args = parser.parse_args()

    submit_cluster_creation(
        args.subscription, args.fs_name, args.user_email, args.location,
        args.availability_zone, args.qumulo_num_nodes, args.rg_name, args.cluster_subnet_id
    )

if __name__ == "__main__":
    main()
