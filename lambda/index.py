from __future__ import print_function
from cmath import e
from urllib import response
import boto3
import urllib

prefix_source = 'topics/observability-metrica-capturada/'

s3 = boto3.client('s3')

def lambda_handler(event, context):
    
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    target_bucket = 'metricsdev-dst-bucket'
    file_path = 'tbff20001_metrica/'
    #source_path = 'observability-metrica-capturada/'
    copy_source = {'Bucket': source_bucket, 'Key': object_key}
    print ("Source bucket : ", source_bucket)
    print ("Target bucket : ", target_bucket)
    print ("Log Stream name: ", context.log_stream_name)
    print ("Log Group name: ", context.log_group_name)
    print ("Request ID: ", context.aws_request_id)
    print ("Mem. limits(MB): ", context.memory_limit_in_mb)
    try:
        print ("waiter for persistence object")
        waiter = s3.get_waiter('object_exists')
        waiter.wait(Bucket=source_bucket, Key=object_key)
        s3.copy_object(Bucket=target_bucket, Key=file_path+object_key.removeprefix(prefix_source), CopySource=copy_source)
        #delete objects copied
        s3.delete_object(Bucket=source_bucket, Key=object_key)
        return response['ContentType']
    except Exception as err:
        print ("Error -"+str(err))
        return 'erro'
