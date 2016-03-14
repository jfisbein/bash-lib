# Detach all user-policies for the username
function iam-detach-policies-by-username() {
	local USER_NAME=$1

	local POLICIES=$(aws iam list-attached-user-policies --user-name $USER_NAME --query "AttachedPolicies[].PolicyArn"  --output text)
	for POLICY in $POLICIES; do
		log "detaching policy $POLICY from $USER_NAME"
		aws iam detach-user-policy --user-name $USER_NAME --policy-arn $POLICY
	done
}

# Delete all access-keys for the username
function iam-delete-access-keys-by-username() {
	local USER_NAME=$1
	local ACCESS_KEYS=$(aws iam list-access-keys --user-name $USER_NAME --query "AccessKeyMetadata[].AccessKeyId" --output text)
	for KEY in $ACCESS_KEYS; do
		log "deleting AccessKey $KEY from $USER_NAME"
		aws iam delete-access-key --user-name $USER_NAME --access-key-id $KEY
	done
}

# Delete username, after deleting his access-keys and detaching his policies
function iam-delete-user-by-username() {
	local USER_NAME=$1
	iam-detach-policies-by-username $USER_NAME
	iam-delete-access-keys-by-username $USER_NAME
	log "deleting user $USER_NAME"
	aws iam delete-user --user-name $USER_NAME
}

# Creates iam policy and return the associated arn
function iam-create-policy() {
	local POLICY_NAME=$1
	local POLICY_DESC=$2
	local POLICY_DOC=$3

	local ARN=$(aws iam create-policy --policy-name $POLICY_NAME --description "$POLICY_DESC" --policy-document "file://$POLICY_DOC" --query "Policy.Arn" --output text)

	echo $ARN
}

# Return the policy arn by the name
function iam-get-policy-arn-by-name() {
	local POLICY_NAME=$1
	local ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

	echo $ARN
}

# Create iam Role
# Return Role arn
function iam-create-role() {
	local ROLE_NAME=$1
	local ROLE_DOC=$2

	if [[ -f $ROLE_DOC ]]; then
		local ROLE_DOC="file://$ROLE_DOC"
	fi

	local ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$ROLE_DOC" --query "Role.Arn" --output text)

	echo $ARN
}

# Delete a Role after detaching all his policies
function iam-delete-role() {
	local ROLE_NAME=$1

	local POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[].PolicyArn" --output text)
	for POLICY in $POLICIES; do
		log "detaching policy $POLICY from $ROLE_NAME"
		aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY"
	done

	aws iam delete-role --role-name "$ROLE_NAME"
}

# Delete a Policy and all his versions
function iam-delete-policy() {
	local POLICY_ARN=$1
	local VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query "Versions[?to_string(IsDefaultVersion)=='false'].VersionId" --output text)

	for VERSION in $VERSIONS; do
		aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$VERSION"
	done
	aws iam delete-policy --policy-arn "$POLICY_ARN"
}

# Verify if a Role exists
# Return 0 if the Role exists, 1 otherwise
function iam-role-exists() {
	local ROLE_NAME=$1

	aws iam get-role --role-name "$ROLE_NAME" &>/dev/null

	return $?
}

# Verify if a Policy exists
# Return 0 if the Policy exists, 1 otherwise
function iam-policy-exists() {
	local POLICY_ARN=$1

	aws iam get-policy --policy-arn "$POLICY_ARN" &>/dev/null

	return $?
}

# Verify if a Role and a Policy are attached
# Return 0 if they are attached, 1 otherwise
function iam-role-policy-attached() {
	local ROLE_NAME=$1
	local POLICY_NAME=$2
	
	if [[ $(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[?PolicyName=='$POLICY_NAME'] | length (@)") == "1" ]]; then
		return 0
	else
		return 1
	fi
}
