# Get Resource id
function apigateway-get-resource-id() {
	local API_ID=${1}
	local RESOURCE_PATH=${2}

	local RESOURCE_ID=$(aws apigateway get-resources --rest-api-id ${API_ID} --query "items[?path=='${RESOURCE_PATH}'].id" --output text)

	echo "${RESOURCE_ID}"
}


# Get Api id from Api name
function apigateway-get-api-id-by-name() {
	local API_NAME=${1}

	local API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${API_NAME}'].id" --output text)

	echo "${API_ID}"
}

# Associate Api Method to Lambda function
function apigateway-bind-method-to-lambda-function() {
	local API_ID=${1}
	local RESOURCE_ID=${2}
	local METHOD=${3}
	local LAMBDA_FUNCTION_NAME=${4}
	local REQUEST_TEMPLATES=${5:-"{}"}

	local LAMBDA_ARN=$(lambda-get-arn-by-name "${LAMBDA_FUNCTION_NAME}")
	local REGION=$(aws configure get region)

	local LAMBDA_URI="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

	aws apigateway put-integration --rest-api-id ${API_ID} --resource-id ${RESOURCE_ID} --http-method ${METHOD} --integration-http-method ${METHOD} --type "AWS" --uri "${LAMBDA_URI}" --request-templates "${REQUEST_TEMPLATES}"
}


# Add needed CORS headers to Api Method
function apigateway-configure-cors-to-method() {
	local API_ID=${1}
	local RESOURCE_ID=${2}
	local METHOD=${3}
	local ALLOW_METHODS=${4:-"$METHOD"}
	local RESPONSE_PARAMS=""

	read -r -d '' RESPONSE_PARAMS << EOM
	{
		"method.response.header.Access-Control-Allow-Origin": false,
		"method.response.header.Access-Control-Allow-Methods": false,
		"method.response.header.Access-Control-Allow-Headers": false
	}
EOM

	aws apigateway put-method-response --rest-api-id ${API_ID} --resource-id ${RESOURCE_ID} --http-method "${METHOD}" --status-code 200 --response-models '{"application/json": "Empty"}' --response-parameters "${RESPONSE_PARAMS}"

	read -r -d '' RESPONSE_PARAMS << EOM
	{
		"method.response.header.Access-Control-Allow-Headers" : "'Content-Type,X-Amz-Date,Authorization'",
		"method.response.header.Access-Control-Allow-Methods" : "'${ALLOW_METHODS}'",
		"method.response.header.Access-Control-Allow-Origin" : "'*'"
	}
EOM

	aws apigateway put-integration-response --rest-api-id ${API_ID} --resource-id ${RESOURCE_ID} --http-method "${METHOD}" --status-code 200 --response-templates '{"application/json":""}' --response-parameters "${RESPONSE_PARAMS}"
}
