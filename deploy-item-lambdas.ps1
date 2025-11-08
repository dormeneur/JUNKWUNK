$ErrorActionPreference = "Continue"

# Configuration
$region = "ap-south-1"
$roleArn = "arn:aws:iam::036338177433:role/JunkWunkLambdaExecutionRole"
$apiId = "evtwkxans4"
$authorizerId = "gr0cdp"

Write-Host "Deploying Item Management Lambda Functions..." -ForegroundColor Green

# Create and deploy Lambda functions
$functions = @(
    @{Name="junkwunk-items-create"; File="items_create.py"; Method="POST"; Resource="/items"},
    @{Name="junkwunk-items-update"; File="items_update.py"; Method="PUT"; Resource="/items/{itemId}"},
    @{Name="junkwunk-items-delete"; File="items_delete.py"; Method="DELETE"; Resource="/items/{itemId}"}
)

Set-Location "lambda_functions"

foreach ($func in $functions) {
    Write-Host "+ Creating $($func.Name)..." -ForegroundColor Cyan
    
    # Zip the function
    if (Test-Path "$($func.File).zip") { Remove-Item "$($func.File).zip" }
    Compress-Archive -Path $func.File -DestinationPath "$($func.File).zip"
    
    # Check if function exists
    $existingFunction = aws lambda get-function --function-name $func.Name --region $region 2>$null
    
    if ($existingFunction) {
        Write-Host "  Updating existing function..." -ForegroundColor Yellow
        aws lambda update-function-code `
            --function-name $func.Name `
            --zip-file "fileb://$($func.File).zip" `
            --region $region
    } else {
        Write-Host "  Creating new function..." -ForegroundColor Yellow
        aws lambda create-function `
            --function-name $func.Name `
            --runtime python3.12 `
            --role $roleArn `
            --handler $($func.File.Replace('.py', '')).lambda_handler `
            --zip-file "fileb://$($func.File).zip" `
            --timeout 30 `
            --memory-size 128 `
            --region $region
    }
}

Set-Location ..

Write-Host "`nConfiguring API Gateway..." -ForegroundColor Green

# Get resource IDs
$itemsResourceId = "32ivv7"
$itemIdResourceId = "txcy3a"

# Create POST /items method
Write-Host "+ Creating POST /items..." -ForegroundColor Cyan
aws apigateway put-method `
    --rest-api-id $apiId `
    --resource-id $itemsResourceId `
    --http-method POST `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $authorizerId `
    --region $region 2>$null

aws apigateway put-integration `
    --rest-api-id $apiId `
    --resource-id $itemsResourceId `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:036338177433:function:junkwunk-items-create/invocations" `
    --region $region

# Grant permission
aws lambda add-permission `
    --function-name junkwunk-items-create `
    --statement-id apigateway-post-items `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${region}:036338177433:${apiId}/*/POST/items" `
    --region $region 2>$null

# Create PUT /items/{itemId} method
Write-Host "+ Creating PUT /items/{itemId}..." -ForegroundColor Cyan
aws apigateway put-method `
    --rest-api-id $apiId `
    --resource-id $itemIdResourceId `
    --http-method PUT `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $authorizerId `
    --region $region 2>$null

aws apigateway put-integration `
    --rest-api-id $apiId `
    --resource-id $itemIdResourceId `
    --http-method PUT `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:036338177433:function:junkwunk-items-update/invocations" `
    --region $region

aws lambda add-permission `
    --function-name junkwunk-items-update `
    --statement-id apigateway-put-items `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${region}:036338177433:${apiId}/*/PUT/items/*" `
    --region $region 2>$null

# Create DELETE /items/{itemId} method
Write-Host "+ Creating DELETE /items/{itemId}..." -ForegroundColor Cyan
aws apigateway put-method `
    --rest-api-id $apiId `
    --resource-id $itemIdResourceId `
    --http-method DELETE `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $authorizerId `
    --region $region 2>$null

aws apigateway put-integration `
    --rest-api-id $apiId `
    --resource-id $itemIdResourceId `
    --http-method DELETE `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:036338177433:function:junkwunk-items-delete/invocations" `
    --region $region

aws lambda add-permission `
    --function-name junkwunk-items-delete `
    --statement-id apigateway-delete-items `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${region}:036338177433:${apiId}/*/DELETE/items/*" `
    --region $region 2>$null

# Deploy API
Write-Host "`nDeploying API to prod stage..." -ForegroundColor Green
aws apigateway create-deployment `
    --rest-api-id $apiId `
    --stage-name prod `
    --region $region

Write-Host "`n=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host "API Endpoint: https://$apiId.execute-api.$region.amazonaws.com/prod" -ForegroundColor Cyan
