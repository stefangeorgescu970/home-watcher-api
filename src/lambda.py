import json
import boto3
import os
from decimal import Decimal

from boto3.dynamodb.conditions import Key

class DecimalEncoder(json.JSONEncoder):
	def default(self, o):
		if isinstance(o, Decimal):
			if abs(o) % 1 > 0:
				return float(o)
			else:
				return int(o)
		return super(DecimalEncoder, self).default(o)

def query_db(begin_timestamp, end_timestamp, table):
    response = table.scan(
        FilterExpression=Key('Timestamp').between(begin_timestamp, end_timestamp)
    )
    return response['Items']

def handle_api_event(event):  
    '''Provide an event that contains the following keys:

      - tableName: the table name from DynamoDB to scan.
      - beginTimestamp: the lower end of the range
      - endTimestamp: the higher end of the range
    '''
    body = json.loads(event["body"]) 
        
    if 'tableName' in body:
        dynamo = boto3.resource('dynamodb').Table(body['tableName'])
    else:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "tableName parameter not found"})
        }
        
    if 'beginTimestamp' in body:
       begin_timestamp = body['beginTimestamp']
    else:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "beginTimestamp parameter not found"})
        }
        
    if 'endTimestamp' in body:
        end_timestamp = body['endTimestamp']
    else:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "endTimestamp parameter not found"})
        }

    items = query_db(begin_timestamp, end_timestamp, dynamo)

    return {
        "statusCode": 200,
        "body": json.dumps(items, cls=DecimalEncoder)
    }

def handle_login_event(event):
    body = json.loads(event["body"]) 
    dynamo = boto3.resource('dynamodb').Table('network-service-auth-' + os.environ['ENV'])

    user = body["username"]
    password = body["password"]

    response = dynamo.query(
        KeyConditionExpression=Key('Email').eq(user)
    )

    if response["Count"] != 1:
        return {
            "statusCode": 400,
            "body": json.dumps(False)
        }

    item = response["Items"][0]

    if password == item["Password"]:
        return {
            "statusCode": 200,
            "body": json.dumps(item["Token"])
        }
    else:
        return {
            "statusCode": 400,
            "body": "Bad Credentials"
        }


def handler(event, context):
    path = event["path"]

    if path == "/login":
        return handle_login_event(event)
    elif path == "/api":
        return handle_api_event(event)
    else:
        return {
            "statusCode": 501,
            "body": "Method not implemented"
        }


if __name__=="__main__":
    print(handle_login_event({"body": '{"username": "stefan.georgescu.970@gmail.com", "password": "s0me-S3cure-Pa55w0rd"}'}))