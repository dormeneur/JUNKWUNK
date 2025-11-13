import json
import boto3
from decimal import Decimal
from datetime import datetime

dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
table = dynamodb.Table('JunkWunk-Users')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        debugPrint(f"Event received: {json.dumps(event)}")
        
        # Get userId from Cognito authorizer
        user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub')
        
        if not user_id:
            user_id = event.get('pathParameters', {}).get('userId')
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'userId is required'})
            }
        
        debugPrint(f"Updating user: {user_id}")
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        debugPrint(f"Request body: {json.dumps(body)}")
        
        # Build update expression
        update_expr = "SET updatedAt = :updatedAt"
        expr_values = {':updatedAt': int(datetime.now().timestamp())}
        expr_names = {}
        
        allowed_fields = ['displayName', 'email', 'phone', 'location', 'coordinates', 'city', 
                         'role', 'profileCompleted', 'photoURL', 'creditPoints']
        
        for field in allowed_fields:
            if field in body:
                if field == 'coordinates' and isinstance(body[field], dict):
                    # Handle coordinates as map {lat: number, lng: number}
                    update_expr += f", #{field} = :{field}"
                    expr_names[f'#{field}'] = field
                    expr_values[f':{field}'] = body[field]
                else:
                    update_expr += f", #{field} = :{field}"
                    expr_names[f'#{field}'] = field
                    expr_values[f':{field}'] = body[field]
        
        debugPrint(f"Update expression: {update_expr}")
        debugPrint(f"Expression values: {json.dumps(expr_values, default=str)}")
        
        response = table.update_item(
            Key={'userId': user_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_names if expr_names else None,
            ExpressionAttributeValues=expr_values,
            ReturnValues='ALL_NEW'
        )
        
        debugPrint(f"Update successful. New attributes: {json.dumps(response['Attributes'], cls=DecimalEncoder)}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response['Attributes'], cls=DecimalEncoder)
        }
        
    except Exception as e:
        debugPrint(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
