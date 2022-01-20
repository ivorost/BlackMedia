#FOLDER_NAME="bonjour"
#SCHEME_NAME="Bonjour-Package"
#PROJECT_NAME="Bonjour"
#FRAMEWORK_NAME="Bonjour"

FOLDER_NAME="$1"
SCHEME_NAME="$2"
PROJECT_NAME="$3"
FRAMEWORK_NAME="$4"

rm -r "build/Fat/$FRAMEWORK_NAME.xcframework"

#echo "Building for iOS..."
xcodebuild archive \
    -quiet \
    -sdk iphoneos IPHONEOS_DEPLOYMENT_TARGET=12.0 \
    -arch arm64 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -project "./repository/$FOLDER_NAME/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -archivePath "./build/iOS/$FRAMEWORK_NAME.xcarchive" SKIP_INSTALL=NO


#echo "Building for iOS Simulator..."
xcodebuild archive \
    -quiet \
    -sdk iphonesimulator IPHONEOS_DEPLOYMENT_TARGET=12.0 \
    -arch x86_64 -arch arm64 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -project "./repository/$FOLDER_NAME/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -archivePath "./build/iOSsimulator/$FRAMEWORK_NAME.xcarchive" SKIP_INSTALL=NO


echo "Building for Catalyst..."
xcodebuild archive \
    -quiet \
    MACOSX_DEPLOYMENT_TARGET=10.15 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -destination "generic/platform=macOS,variant=Mac Catalyst,name=Any Mac" \
    -project "./repository/$FOLDER_NAME/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -archivePath "./build/MacCatalyst/$FRAMEWORK_NAME.xcarchive" SKIP_INSTALL=NO


#echo "Building for macOS..."
xcodebuild archive \
    -quiet \
    -sdk macosx MACOSX_DEPLOYMENT_TARGET=10.13 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -project "./repository/$FOLDER_NAME/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -archivePath "./build/Mac/$FRAMEWORK_NAME.xcarchive" SKIP_INSTALL=NO

echo "Building xcframework..."
xcodebuild -create-xcframework -output "Build/Fat/$FRAMEWORK_NAME.xcframework" \
  -framework "build/iOS/$FRAMEWORK_NAME.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "build/iOSsimulator/$FRAMEWORK_NAME.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "build/MacCatalyst/$FRAMEWORK_NAME.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "build/Mac/$FRAMEWORK_NAME.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"


