import json
import boto3
from datetime import datetime
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
        
        # Parse request body
        body = json.loads(event['body'])
        
        # Build update expression
        update_expr = 'SET '
        expr_attr_values = {}
        expr_attr_names = {}
        
        allowed_fields = ['title', 'description', 'imageUrl', 'categories', 'price', 'quantity', 'status']
        
        for field in allowed_fields:
            if field in body:
                if field == 'price':
                    expr_attr_values[f':{field}'] = Decimal(str(body[field]))
                else:
                    expr_attr_values[f':{field}'] = body[field]
                expr_attr_names[f'#{field}'] = field
                update_expr += f'#{field} = :{field}, '
        
        if not expr_attr_values:
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'No valid fields to update'})
            }
        
        # Remove trailing comma
        update_expr = update_expr.rstrip(', ')
        
        # Update item (only if seller owns it)
        response = items_table.update_item(
            Key={'itemId': item_id},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_attr_values,
            ExpressionAttributeNames=expr_attr_names,
            ConditionExpression='sellerId = :sellerId',
            ReturnValues='ALL_NEW'
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response['Attributes'], cls=DecimalEncoder)
        }
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        return {
            'statusCode': 403,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Not authorized to update this item'})
        }
    except Exception as e:
        debugPrint(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
