MAKEFLAGS += -j4
.PHONY: *

watch: watch-runner dev

dev:
	flutter run --hot -d macos

watch-runner:
	dart run build_runner watch --delete-conflicting-outputs

build: build-runner
	make build-android
	make build-ios

build-runner:
	dart run build_runner build --delete-conflicting-outputs

build-android:
	flutter build appbundle
	flutter build apk
	open build/app/outputs/bundle/release/

build-ios:
	cd ios && pod update
	flutter build ipa
	open build/ios/ipa

tag:
	bash tag.sh

upgrade:
	flutter pub upgrade --precompile --major-versions
	cd ios && pod update

release: tag build

icons:
	dart run flutter_launcher_icons

docs:
	cd docs && hugo build

clean:
	flutter clean
	rm -rf build
