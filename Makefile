watch:
	flutter pub run build_runner watch

build: build-android build-ios
build-android:
	flutter build appbundle
	open build/app/outputs/bundle/release/

build-ios:
	flutter build ipa
	open build/ios/ipa

tag:
	bash tag.sh
.PHONY: build