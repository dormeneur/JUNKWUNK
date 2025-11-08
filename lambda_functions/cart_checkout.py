import json
import boto3
import uuid
from decimal import Decimal
from datetime import datetime
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
cart_table = dynamodb.Table('JunkWunk-Cart')
items_table = dynamodb.Table('JunkWunk-Items')
purchases_table = dynamodb.Table('JunkWunk-Purchases')

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
        item_ids = body.get('itemIds', [])  # List of itemIds to checkout
        
        if not item_ids:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'itemIds array is required'})
            }
        
        # Get all cart items for user
        cart_response = cart_table.query(
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        cart_items = {item['itemId']: item for item in cart_response.get('Items', [])}
        
        # Process each item
        purchases_created = []
        errors = []
        
        for item_id in item_ids:
            if item_id not in cart_items:
                errors.append(f"Item {item_id} not in cart")
                continue
            
            cart_item = cart_items[item_id]
            quantity_requested = cart_item.get('quantity', 1)
            
            # Get current item from Items table
            item_response = items_table.get_item(Key={'itemId': item_id})
            if 'Item' not in item_response:
                errors.append(f"Item {item_id} not found")
                continue
            
            item = item_response['Item']
            current_quantity = item.get('quantity', 0)
            
            # Update item quantity
            new_quantity = current_quantity - quantity_requested
            
            if new_quantity <= 0:
                # Mark as inactive
                items_table.update_item(
                    Key={'itemId': item_id},
                    UpdateExpression='SET quantity = :q, #status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':q': 0, ':status': 'inactive'}
                )
            else:
                items_table.update_item(
                    Key={'itemId': item_id},
                    UpdateExpression='SET quantity = :q',
                    ExpressionAttributeValues={':q': new_quantity}
                )
            
            # Create purchase record
            purchase_id = str(uuid.uuid4())
            purchase = {
                'purchaseId': purchase_id,
                'userId': user_id,
                'sellerId': cart_item.get('sellerId', ''),
                'itemId': item_id,
                'timestamp': int(datetime.now().timestamp()),
                'status': 'completed',
                'title': cart_item.get('title', ''),
                'description': cart_item.get('description', ''),
                'categories': cart_item.get('categories', []),
                'imageUrl': cart_item.get('imageUrl', ''),
                'quantity': quantity_requested,
                'price': cart_item.get('price', 0),
                'sellerName': cart_item.get('sellerName', 'Unknown Seller'),
                'city': cart_item.get('city', '')
            }
            
            purchases_table.put_item(Item=purchase)
            purchases_created.append(purchase_id)
            
            # Remove from cart
            cart_table.delete_item(Key={'userId': user_id, 'itemId': item_id})
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Checkout completed',
                'purchasesCreated': purchases_created,
                'errors': errors
            })
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
