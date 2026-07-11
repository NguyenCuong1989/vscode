#!/bin/sh
set -eu

normalize_git_identity() {
	current_name="$(git config --global --get user.name 2>/dev/null || true)"
	current_email="$(git config --global --get user.email 2>/dev/null || true)"

	case "$current_email" in
		*@* ) email_valid=true ;;
		* ) email_valid=false ;;
	esac

	case "$current_email" in
		*"(none)"*|*".none"* ) email_valid=false ;;
	esac

	if [ -n "$current_name" ] && [ "$email_valid" = true ]; then
		echo "Git identity already configured: $current_name <$current_email>"
		return 0
	fi

	login="${GITHUB_USER:-${GITHUB_ACTOR:-}}"
	account_id=""
	display_name=""

	if command -v gh >/dev/null 2>&1; then
		login_from_api="$(gh api user --jq '.login' 2>/dev/null || true)"
		account_id="$(gh api user --jq '.id' 2>/dev/null || true)"
		display_name="$(gh api user --jq '.name // .login' 2>/dev/null || true)"
		[ -n "$login_from_api" ] && login="$login_from_api"
	fi

	if [ -z "$login" ]; then
		echo "WARNING: Git identity is missing and the GitHub login could not be resolved."
		echo "Run: git config --global user.name '<name>'"
		echo "     git config --global user.email '<email>'"
		return 0
	fi

	[ -n "$display_name" ] || display_name="$login"
	if [ -n "$account_id" ]; then
		noreply_email="${account_id}+${login}@users.noreply.github.com"
	else
		noreply_email="${login}@users.noreply.github.com"
	fi

	git config --global user.name "$display_name"
	git config --global user.email "$noreply_email"

	# Remove only malformed repository-local values that would override the
	# valid global identity. Preserve any valid contributor-specific overrides.
	local_email="$(git config --local --get user.email 2>/dev/null || true)"
	case "$local_email" in
		*"(none)"*|*".none"* ) git config --local --unset-all user.email 2>/dev/null || true ;;
	esac

	echo "Configured Git identity: $(git var GIT_AUTHOR_IDENT)"
}

normalize_git_identity
npm i
npm run electron
