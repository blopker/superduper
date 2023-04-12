watch:
	flutter pub run build_runner watch --delete-conflicting-outputs

build: build-android build-ios
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
	flutter pub upgrade
	cd ios && pod update

release: tag build

icons:
	flutter pub run flutter_launcher_icons

clean:
	flutter clean
	rm -rf build

.PHONY: build