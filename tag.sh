#!/usr/bin/env bash

VER=v$(grep 'version:' pubspec.yaml | cut -d " " -f 2)
git commit -am "$VER"
git tag "$VER"
git push --all
git push --tags

# URL encode
CLEANVER=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$VER" | cut -c 3-)
echo "Release notes: https://github.com/blopker/superduper/releases/new?tag=$CLEANVER&title=Release%20$CLEANVER"
