#!/bin/bash
# setup-tur-chromium-builder.sh - script to setup an chromium building environment

set -e -u -o pipefail

# Enter the working directory
basedir=$(realpath "$(dirname "$0")")
cd "$basedir"

# Checkout the master branch of termux/termux-packages
if [ -d "./termux-packages/.git" ]; then
	echo "Pulling termux-packages..."
	pushd ./termux-packages
	git fetch origin
	git reset --hard origin/master
	# Remove leftovers merged from tur-repo/termux-packages on previous runs
	git clean -fd
	popd
else
	rm -rf ./termux-packages
	git clone https://github.com/termux/termux-packages.git --depth=1
fi

# Checkout the master branch of termux-user-repository/tur
if [ -d "./tur-repo/.git" ]; then
	echo "Pulling tur-repo..."
	pushd ./tur-repo
	git fetch origin
	git reset --hard origin/master
	git clean -fd
	popd
else
	rm -rf ./tur-repo
	git clone https://github.com/termux-user-repository/tur.git tur-repo --depth=1
fi

# Stash local changes (modifications and untracked files like tur-chromium/)
# so they survive the cleanup and merge below. Note that `git stash -u` fails
# with a non-zero exit code when there is nothing to stash, which would abort
# the script due to `set -e`, so check the worktree status first.
STASHED=0
if [ -n "$(git status --porcelain)" ]; then
	git stash push -u
	STASHED=1
fi

# Delete other files
# (glob does not match dotfiles, so .git is kept; this script is kept to be
# safe, it would be restored by `git reset --hard` below anyway)
shopt -s extglob
rm -rf !(termux-packages|tur-repo|setup-tur-chromium-builder.sh)
shopt -u extglob

# Reset to current branch
git reset --hard

# Merge files
# (`-n` keeps our own files like README.md and repo.json intact)
cp -rn ./termux-packages/* ./
cp -rn ./tur-repo/* ./

# Pop changes
if [ "$STASHED" -eq 1 ]; then
	git stash pop
fi

# Apply script patches
shopt -s nullglob
for _patch in ./common-files/building-system-patches/*.patch; do
	echo "Applying patch: $_patch"
	patch --silent -p1 --no-backup-if-mismatch < "$_patch"
done
shopt -u nullglob

# Remove override packages
if [ -f ./common-files/override-packages.txt ]; then
	xargs -r rm -rfv -- < ./common-files/override-packages.txt
fi
