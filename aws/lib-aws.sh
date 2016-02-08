if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source "$DIR/bash-lib/lib-log.sh"
source "$DIR/bash-lib/aws/lib-aws-ec2.sh"
source "$DIR/bash-lib/aws/lib-aws-iam.sh"
source "$DIR/bash-lib/aws/lib-aws-dynamodb.sh"
source "$DIR/bash-lib/aws/lib-aws-s3.sh"
source "$DIR/bash-lib/aws/lib-aws-apigateway.sh"

# Return Cognito pool id by name
function getCognitoPoolIdByName() {
	local POOL_NAME=$1
	local POOL_ID=$(aws cognito-identity list-identity-pools --max-results 60 --query "IdentityPools[?IdentityPoolName=='$POOL_NAME'].IdentityPoolId" --output text)

	echo $POOL_ID
}

# Verify if a Cognito pool exists
# Return 0 if the pool exists, 1 otherwise
function cognitoPoolExist() {
	local POOL_NAME=$1
	if [[ $(aws cognito-identity list-identity-pools --max-results 60 --query "IdentityPools[?IdentityPoolName=='$POOL_NAME'] | length(@)" --output text) == "1" ]]; then
		return 0
	else
		return 1
	fi
}

# Verify if a Lambda function exists
# Return 0 if the function exists, 1 otherwise
function lambdaFunctionExists() {
	local LAMBDA_FUNCTION_NAME=$1
	if [[ $(aws lambda list-functions --query "Functions[?FunctionName=='$LAMBDA_FUNCTION_NAME'] | length (@)") == "1" ]]; then
		return 0
	else
		return 1
	fi
}

function getLambdaArnByName() {
	local LAMBDA_FUNCTION_NAME=$1
	local ARN=$(aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --query "Configuration.FunctionArn" --output text)

	echo "$ARN"
}

function getListSize() {
	LIST=$1
	COUNTER=0
	for ELEM in $LIST; do
		((COUNTER+=1))
	done

	echo "$COUNTER"
}
