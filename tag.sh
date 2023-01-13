#!/usr/bin/env bash

VER=$(grep 'version:' pubspec.yaml | cut -d " " -f 2)
git commit -am "v$VER"
git tag "v$VER"
git push --all
git push --tags
echo "Release notes: https://github.com/octo-org/octo-repo/releases/new?tag=$VER&title=Release%20$VER"