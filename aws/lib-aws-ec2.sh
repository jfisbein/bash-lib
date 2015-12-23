# Return group-id by the group-name
function getGroupIdByGroupName() {
	local GROUP_NAME=$1
	local GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=$GROUP_NAME --query "SecurityGroups[].GroupId" --output text)

	echo $GROUP_ID
}

# Return the list of instances-id in a group
function getInstancesByGroupName() {
	local GROUP_NAME=$1
	local GROUP_ID=$(getGroupIdByGroupName $GROUP_NAME)
	local INSTANCES_ID=$(aws ec2 describe-instances --filters Name=instance.group-id,Values=$GROUP_ID --query "Reservations[].Instances[].InstanceId" --output text)

	echo $INSTANCES_ID
}

# Return the server addresses for all the intances in a group
function getServerAddressesByGroupName() {
	local GROUP_NAME=$1
	local GROUP_ID=$(getGroupIdByGroupName $GROUP_NAME)
	local HOSTS=$(aws ec2 describe-instances --filters Name=instance.group-id,Values=$GROUP_ID --query "Reservations[].Instances[].PublicDnsName" --output text)

	echo $HOSTS
}

# Add a tag to all the ec2 intances of a group
function addTagToInstancesByGroupName() {
	local GROUP_NAME=$1
	local KEY=$2
	local VALUE=$3

	local INSTANCES_ID=$(getInstancesByGroupName $GROUP_NAME)
	log "Adding tag $KEY:$VALUE to $INSTANCES_ID"
	aws ec2 create-tags --resources $INSTANCES_ID --tags Key=$KEY,Value=$VALUE
}
