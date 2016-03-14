# Return number of untracked files in actual git repo
function git-get-number-of-untracked-files() {
	 expr $(git status --porcelain 2>/dev/null | grep "^??" | wc -l)
}

# Return number of staged files in actual git repo
function git-get-number-of-staged-files() {
	echo $(git status --porcelain 2>/dev/null| grep "^M" | wc -l)
}

# Return number of modified files in actual git repo
function git-get-number-of-modified-files() {
	echo $(git status --porcelain 2>/dev/null| grep "^ M" | wc -l)
}

# Return number of pending (modified, added, deleted, etc) files in actual git repo
function git-get-number-of-pending-files() {
	echo $(git status --porcelain 2>/dev/null| egrep "^( M|M| D|D| A|A| R|R| C|C| U|U|\?\?)" | wc -l)
}

# Check if a tag already exists in the remote repository
# Param 1: name of tag
function git-check-if-tag-exists() {
	git show-ref --tags | egrep -q "refs/tags/$1$"
	return $?
}
