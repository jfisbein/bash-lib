# Return number of untracked files in actual git repo
function git-get-number-of-untracked-files() {
	 git status --porcelain 2>/dev/null | grep -c "^??"
}

# Return number of staged files in actual git repo
function git-get-number-of-staged-files() {
	git status --porcelain 2>/dev/null| grep -c "^M"
}

# Return number of modified files in actual git repo
function git-get-number-of-modified-files() {
	git status --porcelain 2>/dev/null| grep -c "^ M"
}

# Return number of pending (modified, added, deleted, etc) files in actual git repo
function git-get-number-of-pending-files() {
	git status --porcelain 2>/dev/null| grep -E -c "^( M|M| D|D| A|A| R|R| C|C| U|U|\?\?)"
}

# Check if a tag already exists in the remote repository
# Param 1: name of tag
function git-check-if-tag-exists() {
	git show-ref --tags | grep -E -q "refs/tags/${1}$"
	return $?
}
