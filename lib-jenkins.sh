JENKINS_HOST="http://jenkins.fon.ofi:8080/"
JENKINS=""

function jenkins-init() {
	if [ $# -eq 0 ]; then
		JENKINS="java -jar jenkins-cli.jar -s $JENKINS_HOST/"
		_jenkins-download-cli $JENKINS_HOST
		return 0
	elif [ $# -eq 1 ]; then
		JENKINS_HOST="$1"
		JENKINS="java -jar jenkins-cli.jar -s $JENKINS_HOST/"
		_jenkins-download-cli $JENKINS_HOST
		return 0
	else
		return 1
	fi
}

function _jenkins-download-cli() {
	local JENKINS_HOST=$1

	if [ ! -f jenkins-cli.jar ]; then
		wget -q $JENKINS_HOST/jnlpJars/jenkins-cli.jar
	fi
}

function jenkins-get-job() {
	local PROJECT=$1
	$JENKINS get-job $PROJECT
}

function jenkins-update-job() {
	local PROJECT=$1
	local JOB_FILE="$2"

	cat "$JOB_FILE" | $JENKINS update-job $PROJECT
}

function jenkins-update-job() {
	local PROJECT=$1
	$JENKINS reload-job $PROJECT
}

function jenkins-enable-job() {
	local PROJECT=$1
	$JENKINS enable-job $PROJECT
}

function jenkins-copy-job() {
	local SOURCE=$1
	local DEST=$2
	$JENKINS copy-job $SOURCE $DEST
}



function jenkins-job-update-git-url() {
	local JOB_FILE="$1"
	local GIT_URL="$2"

	xmlstarlet ed --inplace --pf --update '/project/scm/userRemoteConfigs/hudson.plugins.git.UserRemoteConfig/url' --value "$GIT_URL" "$JOB_FILE"
}

jenkins-init "http://jenkins.fon.ofi:8080/"
# jenkins-get-job "w4b-themes-default" > /tmp/test_file.xml
jenkins-job-update-git-url /tmp/test_file.xml "test2@test:merchant/w4b-test.git"
cat /tmp/test_file.xml
