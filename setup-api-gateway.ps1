# JunkWunk API Gateway Setup Script
# This script creates the complete API Gateway with Cognito authorizer and all routes

$Region = "ap-south-1"
$ApiId = "evtwkxans4"
$RootResourceId = "nqjgd7msx3"
$CognitoUserPoolArn = "arn:aws:cognito-idp:ap-south-1:036338177433:userpool/ap-south-1_KEGPzHo0I"
$AccountId = "036338177433"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "JunkWunk API Gateway Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create Cognito Authorizer
Write-Host "Step 1: Creating Cognito Authorizer..." -ForegroundColor Yellow
$authorizerResponse = aws apigateway create-authorizer `
    --rest-api-id $ApiId `
    --name "JunkWunkCognitoAuthorizer" `
    --type COGNITO_USER_POOLS `
    --provider-arns $CognitoUserPoolArn `
    --identity-source "method.request.header.Authorization" `
    --region $Region | ConvertFrom-Json

$AuthorizerId = $authorizerResponse.id
Write-Host "+ Authorizer created: $AuthorizerId" -ForegroundColor Green
Write-Host ""

# Step 2: Create API Resources
Write-Host "Step 2: Creating API Resources..." -ForegroundColor Yellow

# Create /users resource
$usersResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $RootResourceId `
    --path-part "users" `
    --region $Region | ConvertFrom-Json
$usersResourceId = $usersResource.id
Write-Host "+ Created /users resource: $usersResourceId" -ForegroundColor Green

# Create /users/{userId} resource
$userIdResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $usersResourceId `
    --path-part "{userId}" `
    --region $Region | ConvertFrom-Json
$userIdResourceId = $userIdResource.id
Write-Host "+ Created /users/{userId} resource: $userIdResourceId" -ForegroundColor Green

# Create /items resource
$itemsResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $RootResourceId `
    --path-part "items" `
    --region $Region | ConvertFrom-Json
$itemsResourceId = $itemsResource.id
Write-Host "+ Created /items resource: $itemsResourceId" -ForegroundColor Green

# Create /items/{itemId} resource
$itemIdResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $itemsResourceId `
    --path-part "{itemId}" `
    --region $Region | ConvertFrom-Json
$itemIdResourceId = $itemIdResource.id
Write-Host "+ Created /items/{itemId} resource: $itemIdResourceId" -ForegroundColor Green

# Create /cart resource
$cartResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $RootResourceId `
    --path-part "cart" `
    --region $Region | ConvertFrom-Json
$cartResourceId = $cartResource.id
Write-Host "+ Created /cart resource: $cartResourceId" -ForegroundColor Green

# Create /cart/{itemId} resource
$cartItemResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $cartResourceId `
    --path-part "{itemId}" `
    --region $Region | ConvertFrom-Json
$cartItemResourceId = $cartItemResource.id
Write-Host "+ Created /cart/{itemId} resource: $cartItemResourceId" -ForegroundColor Green

# Create /cart/checkout resource
$checkoutResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $cartResourceId `
    --path-part "checkout" `
    --region $Region | ConvertFrom-Json
$checkoutResourceId = $checkoutResource.id
Write-Host "+ Created /cart/checkout resource: $checkoutResourceId" -ForegroundColor Green

# Create /purchases resource
$purchasesResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $RootResourceId `
    --path-part "purchases" `
    --region $Region | ConvertFrom-Json
$purchasesResourceId = $purchasesResource.id
Write-Host "+ Created /purchases resource: $purchasesResourceId" -ForegroundColor Green

Write-Host ""

# Step 3: Create Methods and Integrations
Write-Host "Step 3: Creating Methods and Lambda Integrations..." -ForegroundColor Yellow

# Function to create method, integration, and CORS
function Add-LambdaMethod {
    param(
        [string]$ResourceId,
        [string]$HttpMethod,
        [string]$LambdaFunctionName,
        [string]$ResourcePath
    )
    
    # Create method
    aws apigateway put-method `
        --rest-api-id $ApiId `
        --resource-id $ResourceId `
        --http-method $HttpMethod `
        --authorization-type COGNITO_USER_POOLS `
        --authorizer-id $AuthorizerId `
        --region $Region | Out-Null
    
    # Create integration
    $lambdaUri = "arn:aws:apigateway:${Region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${Region}:${AccountId}:function:${LambdaFunctionName}/invocations"
    
    aws apigateway put-integration `
        --rest-api-id $ApiId `
        --resource-id $ResourceId `
        --http-method $HttpMethod `
        --type AWS_PROXY `
        --integration-http-method POST `
        --uri $lambdaUri `
        --region $Region | Out-Null
    
    # Grant API Gateway permission to invoke Lambda
    aws lambda add-permission `
        --function-name $LambdaFunctionName `
        --statement-id "apigateway-${LambdaFunctionName}-${HttpMethod}" `
        --action lambda:InvokeFunction `
        --principal apigateway.amazonaws.com `
        --source-arn "arn:aws:execute-api:${Region}:${AccountId}:${ApiId}/*/${HttpMethod}${ResourcePath}" `
        --region $Region 2>$null | Out-Null
    
    Write-Host "  + $HttpMethod $ResourcePath -> $LambdaFunctionName" -ForegroundColor Green
}

# Function to enable CORS
function Enable-CORS {
    param(
        [string]$ResourceId
    )
    
    # Create OPTIONS method
    aws apigateway put-method `
        --rest-api-id $ApiId `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --authorization-type NONE `
        --region $Region | Out-Null
    
    # Create MOCK integration
    aws apigateway put-integration `
        --rest-api-id $ApiId `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --type MOCK `
        --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}' `
        --region $Region | Out-Null
    
    # Create method response
    aws apigateway put-method-response `
        --rest-api-id $ApiId `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --status-code 200 `
        --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" `
        --region $Region | Out-Null
    
    # Create integration response
    $corsHeaders = @{
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
    $corsHeadersJson = ($corsHeaders | ConvertTo-Json -Compress).Replace('"', '\"')
    
    aws apigateway put-integration-response `
        --rest-api-id $ApiId `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --status-code 200 `
        --response-parameters $corsHeadersJson `
        --region $Region | Out-Null
}

# User endpoints
Add-LambdaMethod -ResourceId $userIdResourceId -HttpMethod "GET" -LambdaFunctionName "junkwunk-user-get" -ResourcePath "/users/{userId}"
Add-LambdaMethod -ResourceId $userIdResourceId -HttpMethod "PUT" -LambdaFunctionName "junkwunk-user-update" -ResourcePath "/users/{userId}"

# Items endpoints
Add-LambdaMethod -ResourceId $itemsResourceId -HttpMethod "GET" -LambdaFunctionName "junkwunk-items-list" -ResourcePath "/items"
Add-LambdaMethod -ResourceId $itemIdResourceId -HttpMethod "GET" -LambdaFunctionName "junkwunk-items-get" -ResourcePath "/items/{itemId}"

# Cart endpoints
Add-LambdaMethod -ResourceId $cartResourceId -HttpMethod "GET" -LambdaFunctionName "junkwunk-cart-list" -ResourcePath "/cart"
Add-LambdaMethod -ResourceId $cartResourceId -HttpMethod "POST" -LambdaFunctionName "junkwunk-cart-add" -ResourcePath "/cart"
Add-LambdaMethod -ResourceId $cartItemResourceId -HttpMethod "DELETE" -LambdaFunctionName "junkwunk-cart-remove" -ResourcePath "/cart/{itemId}"
Add-LambdaMethod -ResourceId $checkoutResourceId -HttpMethod "POST" -LambdaFunctionName "junkwunk-cart-checkout" -ResourcePath "/cart/checkout"

# Purchases endpoints
Add-LambdaMethod -ResourceId $purchasesResourceId -HttpMethod "GET" -LambdaFunctionName "junkwunk-purchases-list" -ResourcePath "/purchases"

Write-Host ""

# Step 4: Enable CORS on all resources
Write-Host "Step 4: Enabling CORS..." -ForegroundColor Yellow
Enable-CORS -ResourceId $userIdResourceId
Enable-CORS -ResourceId $itemsResourceId
Enable-CORS -ResourceId $itemIdResourceId
Enable-CORS -ResourceId $cartResourceId
Enable-CORS -ResourceId $cartItemResourceId
Enable-CORS -ResourceId $checkoutResourceId
Enable-CORS -ResourceId $purchasesResourceId
Write-Host "+ CORS enabled on all endpoints" -ForegroundColor Green
Write-Host ""

# Step 5: Deploy API
Write-Host "Step 5: Deploying API to 'prod' stage..." -ForegroundColor Yellow
$deployment = aws apigateway create-deployment `
    --rest-api-id $ApiId `
    --stage-name prod `
    --stage-description "Production stage" `
    --description "Initial deployment" `
    --region $Region | ConvertFrom-Json

Write-Host "+ API deployed successfully!" -ForegroundColor Green
Write-Host ""

# Display API endpoint
$ApiEndpoint = "https://${ApiId}.execute-api.${Region}.amazonaws.com/prod"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoint: " -NoNewline -ForegroundColor Yellow
Write-Host $ApiEndpoint -ForegroundColor White
Write-Host ""
Write-Host "Available Endpoints:" -ForegroundColor Yellow
Write-Host "  GET    $ApiEndpoint/users/{userId}" -ForegroundColor White
Write-Host "  PUT    $ApiEndpoint/users/{userId}" -ForegroundColor White
Write-Host "  GET    $ApiEndpoint/items" -ForegroundColor White
Write-Host "  GET    $ApiEndpoint/items/{itemId}" -ForegroundColor White
Write-Host "  GET    $ApiEndpoint/cart" -ForegroundColor White
Write-Host "  POST   $ApiEndpoint/cart" -ForegroundColor White
Write-Host "  DELETE $ApiEndpoint/cart/{itemId}" -ForegroundColor White
Write-Host "  POST   $ApiEndpoint/cart/checkout" -ForegroundColor White
Write-Host "  GET    $ApiEndpoint/purchases" -ForegroundColor White
Write-Host ""
Write-Host "Save this endpoint URL - you'll need it in Flutter!" -ForegroundColor Cyan
Write-Host ""

# Save endpoint to file
$ApiEndpoint | Out-File -FilePath "api-endpoint.txt" -Encoding UTF8
Write-Host "+ API endpoint saved to api-endpoint.txt" -ForegroundColor Green
