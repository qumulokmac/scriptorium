import boto3
import concurrent.futures

def delete_bucket_contents(bucket_name):
    s3 = boto3.client('s3')
    paginator = s3.get_paginator('list_object_versions')
    delete_objects = []
    
    for page in paginator.paginate(Bucket=bucket_name):
        if 'Versions' in page:
            delete_objects.extend([{'Key': item['Key'], 'VersionId': item['VersionId']} for item in page['Versions']])
        if 'DeleteMarkers' in page:
            delete_objects.extend([{'Key': item['Key'], 'VersionId': item['VersionId']} for item in page['DeleteMarkers']])
        
        if delete_objects:
            s3.delete_objects(Bucket=bucket_name, Delete={'Objects': delete_objects})
            delete_objects = []

def delete_bucket(bucket_name):
    try:
        delete_bucket_contents(bucket_name)
        s3 = boto3.client('s3')
        s3.delete_bucket(Bucket=bucket_name)
        print(f'Deleted bucket {bucket_name} and all its contents.')
    except Exception as e:
        print(f'Error deleting bucket {bucket_name}: {str(e)}')

def delete_buckets_parallel(bucket_names):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(delete_bucket, bucket_names)

if __name__ == "__main__":
    bucket_list = [
        'y5rbryxl7gr-cnq-specai-05-tlsbf07763c-qps-5',
        '5zgtducjbnj-cnq-specai-05-tlsbf07763c-qps-1',
        'hsw1nbyeoro-cnq-specai-05-tlsbf07763c-qps-6',
        'e0dfymdmonz-cnq-specai-05-tlsbf07763c-qps-3',
        '0luwbnomtbc-cnq-specai-05-tlsbf07763c-qps-9',
        't4vfteevnuk-cnq-specai-05-tlsbf07763c-qps-10',
        '1qrkbwdsvz6-cnq-specai-05-tlsbf07763c-qps-4',
        'h5wkikkoz9x-cnq-specai-05-tlsbf07763c-qps-2',
        '5ummdmjtil4-cnq-specai-05-tlsbf07763c-qps-7'
    ]
    delete_buckets_parallel(bucket_list)