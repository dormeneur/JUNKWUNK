import json
import boto3
from decimal import Decimal
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
cart_table = dynamodb.Table('JunkWunk-Cart')
items_table = dynamodb.Table('JunkWunk-Items')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Get userId from Cognito
        user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub')
        
        if not user_id:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Unauthorized'})
            }
        
        body = json.loads(event.get('body', '{}'))
        item_id = body.get('itemId')
        seller_id = body.get('sellerId')
        quantity = body.get('quantity', 1)
        
        if not item_id or not seller_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'itemId and sellerId are required'})
            }
        
        # Get item details
        item_response = items_table.get_item(Key={'itemId': item_id})
        if 'Item' not in item_response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Item not found'})
            }
        
        item = item_response['Item']
        
        # Check if item is active and has sufficient quantity
        if item.get('status') != 'active':
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Item is not available'})
            }
        
        if item.get('quantity', 0) < quantity:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Insufficient quantity available'})
            }
        
        # Calculate TTL (30 days from now)
        ttl = int((datetime.now() + timedelta(days=30)).timestamp())
        
        # Add to cart (or update quantity if exists)
        try:
            # Try to get existing cart item
            existing = cart_table.get_item(Key={'userId': user_id, 'itemId': item_id})
            
            if 'Item' in existing:
                # Update quantity
                new_quantity = existing['Item'].get('quantity', 0) + quantity
                cart_table.update_item(
                    Key={'userId': user_id, 'itemId': item_id},
                    UpdateExpression='SET quantity = :q, #ttl = :ttl',
                    ExpressionAttributeNames={'#ttl': 'ttl'},
                    ExpressionAttributeValues={':q': new_quantity, ':ttl': ttl}
                )
            else:
                # Create new cart item
                cart_table.put_item(Item={
                    'userId': user_id,
                    'itemId': item_id,
                    'sellerId': seller_id,
                    'quantity': quantity,
                    'addedAt': int(datetime.now().timestamp()),
                    'ttl': ttl,
                    # Denormalized data for faster retrieval
                    'title': item.get('title', ''),
                    'description': item.get('description', ''),
                    'imageUrl': item.get('imageUrl', ''),
                    'categories': item.get('categories', []),
                    'price': item.get('price', 0),
                    'sellerName': item.get('sellerName', 'Unknown Seller'),
                    'city': item.get('city', ''),
                    'coordinates': item.get('coordinates', {})
                })
        except Exception as e:
            print(f"Error updating cart: {str(e)}")
            raise
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Item added to cart successfully'})
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
