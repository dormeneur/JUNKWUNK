import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
items_table = dynamodb.Table('JunkWunk-Items')
users_table = dynamodb.Table('JunkWunk-Users')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Get userId from Cognito authorizer
        user_id = event['requestContext']['authorizer']['claims']['sub']
        
        # Parse request body
        body = json.loads(event['body'])
        
        # Generate item ID
        item_id = str(uuid.uuid4())
        
        # Get seller info
        seller_response = users_table.get_item(Key={'userId': user_id})
        seller_data = seller_response.get('Item', {})
        seller_name = seller_data.get('displayName', 'Unknown Seller')
        city = seller_data.get('city', '')
        
        # Create item
        item = {
            'itemId': item_id,
            'sellerId': user_id,
            'title': body.get('title', ''),
            'description': body.get('description', ''),
            'imageUrl': body.get('imageUrl', ''),
            'categories': body.get('categories', []),
            'price': Decimal(str(body.get('price', 0))),
            'quantity': body.get('quantity', 1),
            'status': 'active',
            'timestamp': datetime.utcnow().isoformat(),
            'sellerName': seller_name,
            'city': city,
            'coordinates': body.get('coordinates', {})
        }
        
        items_table.put_item(Item=item)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(item, cls=DecimalEncoder)
        }
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
