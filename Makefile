watch:
	dart run build_runner watch --delete-conflicting-outputs

build: build-runner build-android build-ios

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

clean:
	flutter clean
	rm -rf build

.PHONY: build