watch:
	flutter pub run build_runner watch

build: build-android build-ios
build-android:
	flutter build appbundle
	open build/app/outputs/bundle/release/

build-ios:
	cd ios && pod update
	flutter build ipa
	open build/ios/ipa

tag:
	bash tag.sh

release: tag build-android build-ios

.PHONY: build