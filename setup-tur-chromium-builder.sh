#!/bin/bash
# setup-tur-chromium-builder.sh - script to setup an chromium building environment

set -e -u -o pipefail

# Enter the working directory
basedir=$(realpath $(dirname $0))
cd $basedir

# Checkout the master branch of termux/termux-packages
if [ -d "./termux-packages" ] && [ -d "./termux-packages/.git" ]; then
	echo "Pulling termux-packages..."
	pushd ./termux-packages
	git reset --hard origin/master
	git pull --rebase
	popd
else
	rm -rf ./termux-packages
	git clone https://github.com/termux/termux-packages.git --depth=1
fi

# Checkout the master branch of termux-user-repository/tur
if [ -d "./tur-repo" ] && [ -d "./tur-repo/.git" ]; then
	echo "Pulling termux-packages..."
	pushd ./termux-packages
	git reset --hard origin/master
	git pull --rebase
	popd
else
	rm -rf ./tur-repo
	git clone https://github.com/termux-user-repository/tur.git tur-repo --depth=1
fi

# Push changes
git stash -u

# Delete other files
shopt -s extglob
rm -rf !(termux-packages|tur-repo)
shopt -u extglob

# Reset to current branch
git reset --hard

# Merge files
cp -rn ./termux-packages/* ./
cp -rn ./tur-repo/* ./

# Pop changes
if [ "$(git stash list)" != "" ]; then
	git stash pop
fi

# Apply script patches
shopt -s nullglob
_patch=
for _patch in ./common-files/building-system-patches/*.patch; do
	echo "Applying patch: $_patch"
	patch --silent -p1 < $_patch
done
unset _patch
shopt -u nullglob

# Remove override packages
cat ./common-files/override-packages.txt | xargs rm -rfv --

# Remove files
rm -f build-package.sh.orig
