import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
items_table = dynamodb.Table('JunkWunk-Items')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Get itemId from path
        item_id = event['pathParameters']['itemId']
        
        # Get userId from Cognito authorizer
        user_id = event['requestContext']['authorizer']['claims']['sub']
        
        # Delete item (only if seller owns it)
        items_table.delete_item(
            Key={'itemId': item_id},
            ConditionExpression='sellerId = :sellerId',
            ExpressionAttributeValues={':sellerId': user_id}
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Item deleted successfully'})
        }
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        return {
            'statusCode': 403,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Not authorized to delete this item'})
        }
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
