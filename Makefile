watch:
	flutter pub run build_runner watch

build:
	flutter build appbundle
	open build/app/outputs/bundle/release/

tag:
	bash tag.sh
.PHONY: build