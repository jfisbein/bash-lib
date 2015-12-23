# Return website URL for a S3 Bucket
function getS3WebsiteURL() {
	local BUCKET_NAME=$1
	local INDEX_DOC=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --query "IndexDocument.Suffix" --output text)
	local BUCKET_REGION=$(aws s3api get-bucket-location --bucket "$BUCKET_NAME" --query "LocationConstraint" --output text)

	if [[ "$BUCKET_REGION" == "None" ]]; then
		local BUCKET_REGION="us-east-1"
	fi

	echo "http://$BUCKET_NAME.s3-website-$BUCKET_REGION.amazonaws.com/$INDEX_DOC"
}

# Create S3 Bucket and configure website
function createS3Website() {
	local BUCKET_NAME=$1
	local INDEX_DOC=${2:-index.html}
	local ERROR_DOC=${3:-error.html}
	local REGION=$(aws configure get region)

	# Create Bucket
	aws s3api create-bucket --bucket "$BUCKET_NAME" --create-bucket-configuration "LocationConstraint=$REGION" --acl public-read

	if [[ "$?"=="0" ]]; then
		# Wait for bucket to be created
		aws s3api wait bucket-exists --bucket "$BUCKET_NAME"

		# Configure website settings
		aws s3 website "s3://$BUCKET_NAME" --index-document "$INDEX_DOC" --error-document "$ERROR_DOC"

		# Add policy to make it publicly accesible
		local POLICY=$(sed "s/%BUCKET_NAME%/$BUCKET_NAME/g" iam/WebsiteBucketPolicy.json.template)
		aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$POLICY"

		echo $(getS3WebsiteURL $BUCKET_NAME)
		return 0
	else
		return 255
	fi
}

# Update S3 website content
function updateS3Website() {
	local ORIGIN_PATH=$1
	local BUCKET_NAME=$2
	aws s3 sync "$ORIGIN_PATH" "s3://$BUCKET_NAME" --delete &>/dev/null

	echo $(getS3WebsiteURL $BUCKET_NAME)
}

# Delete S3 Bucket associated with a website
function deleteS3Website() {
	local BUCKET_NAME=$1
	aws s3 rm "s3://$BUCKET_NAME" --recursive
	aws s3 rb "s3://$BUCKET_NAME" --force
	aws s3api wait bucket-not-exists --bucket "$BUCKET_NAME"
}

# Verify if a S3 Bucket exists
function bucketExist() {
	local BUCKET_NAME=$1

	if [[ $(aws s3api list-buckets --query "Buckets[?Name=='$BUCKET_NAME'] | length (@)") == "1" ]]; then
		return 0
	else
		return 1
	fi
}
