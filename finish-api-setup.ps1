# Simplified JunkWunk API Gateway Setup Script
# This creates methods and integrations without CORS complexity

$Region = "ap-south-1"
$ApiId = "evtwkxans4"
$AuthorizerId = "gr0cdp"
$AccountId = "036338177433"

# Resource IDs from partial run
$userIdResourceId = "d9nyvr"
$itemsResourceId = "32ivv7"
$itemIdResourceId = "txcy3a"
$cartResourceId = "tz7xro"
$cartItemResourceId = "0gz6l6"

Write-Host "Continuing API Gateway Setup..." -ForegroundColor Cyan
Write-Host ""

# Need to create checkout and purchases resources
Write-Host "Creating remaining resources..." -ForegroundColor Yellow

$checkoutResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id $cartResourceId `
    --path-part "checkout" `
    --region $Region | ConvertFrom-Json
$checkoutResourceId = $checkoutResource.id
Write-Host "+ Created /cart/checkout: $checkoutResourceId" -ForegroundColor Green

$purchasesResource = aws apigateway create-resource `
    --rest-api-id $ApiId `
    --parent-id "nqjgd7msx3" `
    --path-part "purchases" `
    --region $Region | ConvertFrom-Json
$purchasesResourceId = $purchasesResource.id
Write-Host "+ Created /purchases: $purchasesResourceId" -ForegroundColor Green

Write-Host ""
Write-Host "Creating methods and integrations..." -ForegroundColor Yellow

# Function to create method and integration
function Add-APIMethod {
    param($ResourceId, $Method, $LambdaName, $Path)
    
    # Create method
    aws apigateway put-method --rest-api-id $ApiId --resource-id $ResourceId --http-method $Method --authorization-type COGNITO_USER_POOLS --authorizer-id $AuthorizerId --region $Region 2>$null | Out-Null
    
    # Create integration
    $uri = "arn:aws:apigateway:${Region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${Region}:${AccountId}:function:${LambdaName}/invocations"
    aws apigateway put-integration --rest-api-id $ApiId --resource-id $ResourceId --http-method $Method --type AWS_PROXY --integration-http-method POST --uri $uri --region $Region 2>$null | Out-Null
    
    # Grant permission
    aws lambda add-permission --function-name $LambdaName --statement-id "api-$Method-$(Get-Random)" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${Region}:${AccountId}:${ApiId}/*/$Method$Path" --region $Region 2>$null | Out-Null
    
    Write-Host "  + $Method $Path" -ForegroundColor Green
}

# Create all methods
Add-APIMethod $userIdResourceId "GET" "junkwunk-user-get" "/users/{userId}"
Add-APIMethod $userIdResourceId "PUT" "junkwunk-user-update" "/users/{userId}"
Add-APIMethod $itemsResourceId "GET" "junkwunk-items-list" "/items"
Add-APIMethod $itemIdResourceId "GET" "junkwunk-items-get" "/items/{itemId}"
Add-APIMethod $cartResourceId "GET" "junkwunk-cart-list" "/cart"
Add-APIMethod $cartResourceId "POST" "junkwunk-cart-add" "/cart"
Add-APIMethod $cartItemResourceId "DELETE" "junkwunk-cart-remove" "/cart/{itemId}"
Add-APIMethod $checkoutResourceId "POST" "junkwunk-cart-checkout" "/cart/checkout"
Add-APIMethod $purchasesResourceId "GET" "junkwunk-purchases-list" "/purchases"

Write-Host ""
Write-Host "Deploying API..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $ApiId --stage-name prod --region $Region | Out-Null
Write-Host "+ API deployed to prod stage" -ForegroundColor Green

$endpoint = "https://${ApiId}.execute-api.${Region}.amazonaws.com/prod"
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "API READY!" -ForegroundColor Green  
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Endpoint: $endpoint" -ForegroundColor White
Write-Host ""
Write-Host "Endpoints:" -ForegroundColor Yellow
Write-Host "  GET $endpoint/users/{userId}" 
Write-Host "  PUT $endpoint/users/{userId}"
Write-Host "  GET $endpoint/items"
Write-Host "  GET $endpoint/items/{itemId}"
Write-Host "  GET $endpoint/cart"
Write-Host "  POST $endpoint/cart"
Write-Host "  DELETE $endpoint/cart/{itemId}"
Write-Host "  POST $endpoint/cart/checkout"
Write-Host "  GET $endpoint/purchases"
Write-Host ""

$endpoint | Out-File "api-endpoint.txt"
Write-Host "+ Saved to api-endpoint.txt" -ForegroundColor Green
