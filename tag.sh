#!/usr/bin/env bash

VER=v$(grep 'version:' pubspec.yaml | cut -d " " -f 2)
git commit -am "$VER"
git tag "$VER"
git push --all
git push --tags

# URL encode
CLEANVER=$(jq -rn --arg x "$VER" '$x|@uri')
echo "Release notes: https://github.com/blopker/superduper/releases/new?tag=$CLEANVER&title=Release%20$CLEANVER"
