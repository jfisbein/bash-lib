# Return group-id by the group-name
function ec2-get-group-id-by-name() {
	local GROUP_NAME=${1}
	local GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${GROUP_NAME} --query "SecurityGroups[].GroupId" --output text)

	echo ${GROUP_ID}
}

# Return the list of instances-id in a group
function ec2-get-instances-by-group-name() {
	local GROUP_NAME=${1}
	local GROUP_ID=$(ec2-get-group-id-by-name ${GROUP_NAME})
	local INSTANCES_ID=$(aws ec2 describe-instances --filters Name=instance.group-id,Values=${GROUP_ID} --query "Reservations[].Instances[].InstanceId" --output text)

	echo ${INSTANCES_ID}
}

# Return the server addresses for all the intances in a group
function ec2-get-public-server-addresses-by-group-name() {
	local GROUP_NAME=${1}
	local GROUP_ID=$(ec2-get-group-id-by-name ${GROUP_NAME})
	local HOSTS=$(aws ec2 describe-instances --filters Name=instance.group-id,Values=${GROUP_ID} --query "Reservations[].Instances[].PublicDnsName" --output text)

	echo ${HOSTS}
}

# Add a tag to all the ec2 intances of a group
function ec2-add-tag-to-instances-by-group-name() {
	local GROUP_NAME=${1}
	local KEY=${2}
	local VALUE=${3}

	local INSTANCES_ID=$(ec2-get-instances-by-group-name ${GROUP_NAME})
	log "Adding tag ${KEY}:${VALUE} to ${INSTANCES_ID}"
	aws ec2 create-tags --resources ${INSTANCES_ID} --tags Key=${KEY},Value=${VALUE}
}

function ec2-get-public-ip() {
	local INSTANCE_ID=${1}
	aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp" --output text
}

function ec2-get-instances-id-by-name() {
	local NAME=${1}
	aws ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}" "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" --query "Reservations[].Instances[].InstanceId | join(' ', @)" --output text
}

function ec2-terminate-instance-by-name() {
	NAME=${1}
	WAIT=${2:-false}

	INSTANCE_ID=$(ec2-get-instances-id-by-name ${NAME})
	if [ "$INSTANCE_ID" != "" ]; then
		aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}
		if ${WAIT}; then
			log "Waiting for Intance [${NAME} - ${INSTANCE_ID}] to terminate"
			aws ec2 wait instance-terminated --instance-ids ${INSTANCE_ID}
		fi
	fi
}

function ec2-get-vpc-id-by-name() {
	local VPC_NAME="${1}"

	aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${VPC_NAME}" --query "Vpcs[].VpcId" --output text
}

function ec2-delete-security-group-by-name() {
	local GROUP_NAME="${1}"
	local GROUP_ID=$(ec2-get-group-id-by-name "${GROUP_NAME}")

	if [ "${GROUP_ID}" != "" ]; then
		aws ec2 delete-security-group --group-id ${GROUP_ID}
	fi
}

function ec2-get-subnet-id-by-name() {
	local SUB_NAME="${1}"

	aws ec2 describe-subnets --filters "Name=tag:Name,Values=${SUB_NAME}" --query "Subnets[].SubnetId" --output text
}

function ec2-delete-vpc-by-name() {
	local VPC_NAME="${1}"

	local VPC_ID=$(ec2-get-vpc-id-by-name "${VPC_NAME}")
	if [ "$VPC_ID" != "" ]; then
		aws ec2 delete-vpc --vpc-id ${VPC_ID}
	fi
}

function ec2-delete-subnet-by-name() {
	local SUB_NAME="${1}"

	local SUB_ID=$(ec2-get-subnet-id-by-name "${SUB_NAME}")
	if [ "${SUB_ID}" != "" ]; then
		aws ec2 delete-subnet --subnet-id ${SUB_ID}
	fi
}
