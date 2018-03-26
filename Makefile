###############################################
#
# Makefile
#
###############################################

SWIFTC_OPTS := -c release -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13 -Xswiftc -static-stdlib
LINKER_OPTS :=

all: build

build:
	swift package update
	swift build $(SWIFTC_OPTS) $(LINKER_OPTS) --build-path=macosBuild

test: clean
	swift test $(SWIFTC_OPTS) $(LINKER_OPTS) -Xswiftc -enable-testing

clean:
	swift package clean
	rm -rf .build
	rm -rf iosBuild
	rm -rf macosBuild
	rm -f Package.pins
	rm -rf iosBuild iosBuild.swiftdoc

lint:
	swiftlint

xc:
	swift package generate-xcodeproj

xcbuild:
	xcodebuild -workspace SwiftLog.xcworkspace -scheme macOSLog -configuration Debug -destination 'platform=macOS,arch=x86_64' BUILD_DIR=macosBuild

SYS_PATH  := /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform
INCL_PATH := $(SYS_PATH)/Developer/SDKs/iPhoneOS.sdk/usr/include
LIB_PATH  := $(SYS_PATH)/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks
SDK_PATH  := $(SYS_PATH)/Developer/SDKs/iPhoneOS.sdk
TARGET    := arm64-apple-ios11.0
MODULE    := SwiftLog

ios:
	rm -rf iosBuild iosBuild.swiftdoc
	mkdir -p iosBuild
	swiftc -I $(INCL_PATH) -F $(LIB_PATH) -target $(TARGET) -sdk $(SDK_PATH) -o iosBuild/libSwiftLog.dylib -emit-library -emit-module -emit-module-path iosBuild -module-name $(MODULE) -framework Foundation -framework AVFoundation Sources/*.swift

tag: TAG :=  0.0.1
tag:
	git tag -d $(TAG)
	git push origin :refs/tags/$(TAG)
	git tag -a $(TAG) -m "Release version $(TAG)"
	git push origin master --tags
