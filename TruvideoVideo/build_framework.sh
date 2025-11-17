xcodebuild archive -scheme "TruvideoVideo" -destination generic/platform=iOS -archivePath "archives/TruvideoVideo_iOS" -derivedDataPath "$PWD/derivedData" -clonedSourcePackagesDirPath "$HOME/Library/Developer/Xcode/DerivedData/$XCODE_SCHEME" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive -scheme "TruvideoVideo" -destination "generic/platform=iOS Simulator" -archivePath "archives/TruvideoVideo_iOS_Simulator" -derivedDataPath "$PWD/derivedData" -clonedSourcePackagesDirPath "$HOME/Library/Developer/Xcode/DerivedData/$XCODE_SCHEME" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework -framework archives/TruvideoVideo_iOS.xcarchive/Products/Library/Frameworks/TruvideoVideo.framework -framework archives/TruvideoVideo_iOS_Simulator.xcarchive/Products/Library/Frameworks/TruvideoVideo.framework -output TruvideoVideo.xcframework

