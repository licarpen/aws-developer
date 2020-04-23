import json

print('Loading function')


def lambda_handler(event, context):
    return "Hello world"  # Echo back the first key value
    #raise Exception('Something went wrong')