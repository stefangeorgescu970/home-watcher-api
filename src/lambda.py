import json
import boto3
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

def handler(event, context):
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
