DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${DIR}/lib-log.sh"
source "${DIR}/aws/lib-aws-ec2.sh"
source "${DIR}/aws/lib-aws-iam.sh"
source "${DIR}/aws/lib-aws-dynamodb.sh"
source "${DIR}/aws/lib-aws-s3.sh"
source "${DIR}/aws/lib-aws-apigateway.sh"

# Return Cognito pool id by name
function cognito-get-pool-id-by-name() {
	local POOL_NAME=${1}
	local POOL_ID=$(aws cognito-identity list-identity-pools --max-results 60 --query "IdentityPools[?IdentityPoolName=='${POOL_NAME}'].IdentityPoolId" --output text)

	echo ${POOL_ID}
}

# Verify if a Cognito pool exists
# Return 0 if the pool exists, 1 otherwise
function cognito-check-if-pool-exist() {
	local POOL_NAME=${1}
	if [[ $(aws cognito-identity list-identity-pools --max-results 60 --query "IdentityPools[?IdentityPoolName=='${POOL_NAME}'] | length(@)" --output text) == "1" ]]; then
		return 0
	else
		return 1
	fi
}

# Verify if a Lambda function exists
# Return 0 if the function exists, 1 otherwise
function lambda-check-if-function-exists() {
	local LAMBDA_FUNCTION_NAME=${1}
	if [[ $(aws lambda list-functions --query "Functions[?FunctionName=='${LAMBDA_FUNCTION_NAME}'] | length (@)") == "1" ]]; then
		return 0
	else
		return 1
	fi
}

function lambda-get-arn-by-name() {
	local LAMBDA_FUNCTION_NAME=${1}
	local ARN=$(aws lambda get-function --function-name "${LAMBDA_FUNCTION_NAME}" --query "Configuration.FunctionArn" --output text)

	echo "${ARN}"
}

function get-list-size() {
	local LIST=${1}
	local COUNTER=0
	for ELEM in ${LIST}; do
		((COUNTER+=1))
	done

	echo "${COUNTER}"
}
