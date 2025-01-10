#!/usr/bin/env bash
set -e

readonly DEBUG=${DEBUG:-unset}
[[ $DEBUG != unset ]] && set -x

# do not run in Circle CI
if [[ -z $CIRCLECI ]]; then
	# assert the circleci command exists
	if ! [ -x "$(command -v circleci)" ]; then
		echo 'circleci command not found'
		echo 'See https://circleci.com/docs/2.0/local-cli/ for installation instructions.'
		exit 1
	fi

	# Save original PATH
	ORIGINAL_PATH=$PATH

	# Create temporary git script for branch testing
	TMP_DIR=$(mktemp -d)
	GIT_BIN=$(command -v git)
	cat > "$TMP_DIR/git" << 'EOF'
#!/bin/bash
if [ "$1" = "rev-parse" ] && [ "$2" = "--abbrev-ref" ] && [ "$3" = "HEAD" ]; then
	echo "$MOCK_BRANCH"
	exit 0
fi
exec $GIT_BIN "$@"
EOF

	chmod +x "$TMP_DIR/git"

	# The following is needed by the circleci local build tool
	[ -f /dev/tty ] && exec /dev/tty

	# Test configuration against multiple branches
	branches=("$(git rev-parse --abbrev-ref HEAD)")

	# Add development branch if it exists
	if git show-ref --verify --quiet refs/heads/development; then
		branches+=("development")
	fi

	# Add development branch if it exists
	if git show-ref --verify --quiet refs/heads/main; then
		branches+=("main")
	fi

	# Add development branch if it exists
	if git show-ref --verify --quiet refs/heads/master; then
		branches+=("master")
	fi

	export PATH="$TMP_DIR:$PATH"

	for branch in "${branches[@]}"; do
		echo "Validating CircleCI config for branch: $branch"
		export MOCK_BRANCH="$branch"
		if ! msg=$(circleci config validate --skip-update-check "$@"); then
			echo "CircleCI Configuration Failed Validation for branch: $branch"
			echo "$msg"
			export PATH="$ORIGINAL_PATH"
			rm -rf "$TMP_DIR"
			exit 1
		else
			echo "CircleCI Configuration Validated for branch: $branch"
		fi
	done

	# Cleanup
	export PATH="$ORIGINAL_PATH"
	rm -rf "$TMP_DIR"
fi
