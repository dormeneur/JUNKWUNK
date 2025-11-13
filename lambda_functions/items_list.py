import json
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
table = dynamodb.Table('JunkWunk-Items')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Get query parameters
        params = event.get('queryStringParameters') or {}
        category = params.get('category')
        seller_id = params.get('sellerId')
        status = params.get('status', 'active')
        
        # Query by status first (most common query)
        if seller_id:
            # Query by sellerId using GSI
            response = table.query(
                IndexName='SellerIdIndex',
                KeyConditionExpression=Key('sellerId').eq(seller_id)
            )
        else:
            # Query by status using GSI
            response = table.query(
                IndexName='StatusIndex',
                KeyConditionExpression=Key('status').eq(status)
            )
        
        items = response.get('Items', [])
        
        # Filter by category if provided
        if category and items:
            items = [item for item in items if category in item.get('categories', [])]
        
        # Sort by timestamp descending
        items.sort(key=lambda x: x.get('timestamp', 0), reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'items': items,
                'count': len(items)
            }, cls=DecimalEncoder)
        }
        
    except Exception as e:
        debugPrint(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
