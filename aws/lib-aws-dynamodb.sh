# Verify if a DynamoDB table exists
# return 0 if the table exists, 1 otherwise
function DynamoTableExists() {
	local TABLE_NAME=$1
	if [[ $(aws dynamodb list-tables --query "TableNames[?@=='$TABLE_NAME'] | length(@)") == "1" ]]; then
		return 0
	else
		return 1
	fi
}

# Delete all content from DynamoDB table
function EmptyDynamoTable() {
	local TABLE_NAME=$1

	local ROW_IDS=$(aws dynamodb scan --table-name "$TABLE_NAME" --query "Items[*].Id.S" --output text)
	local SIZE=$(getListSize "$ROW_IDS")

	log "Deleting existing [$SIZE] items on table $TABLE_NAME"
	for ID in $ROW_IDS; do
		log_step
		aws dynamodb delete-item --table-name "$TABLE_NAME" --key "{ \"Id\": { \"S\": \"$ID\" }}"
	done
	log ""  # new line
}
