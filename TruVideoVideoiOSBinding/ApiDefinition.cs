using System;
using Foundation;
using ObjCRuntime;
using UIKit;

namespace TruvideoVideoiOS
{
    // @interface ThumbnailRequest : NSObject
    [BaseType(typeof(NSObject), Name = "_TtC13TruvideoVideo16ThumbnailRequest")]
    [DisableDefaultCtor]
    interface ThumbnailRequest
    {
        // -(instancetype _Nonnull)initWithUrl:(NSURL * _Nonnull)url position:(NSNumber * _Nullable)position width:(NSNumber * _Nullable)width height:(NSNumber * _Nullable)height __attribute__((objc_designated_initializer));
        [Export("initWithUrl:position:width:height:outputURL:")]
        [DesignatedInitializer]
        IntPtr Constructor(NSUrl url, [NullAllowed] NSNumber position, [NullAllowed] NSNumber width,
            [NullAllowed] NSNumber height,NSUrl outputURL);
    }

    // @interface TruvideoVideoSdk : NSObject
    [BaseType(typeof(NSObject), Name = "_TtC13TruvideoVideo16TruvideoVideoSdk")]
    interface TruvideoVideoSdk
    {
        [Static]
        [Export("shared", ArgumentSemantic.Strong)]
        TruvideoVideoSdk Shared { get; }

        [Export("generateThumbnailWithRequest:completion:")]
        void GenerateThumbnail(ThumbnailRequest request, Action<NSUrl, NSError> completion);

        [Export("editVideoWithInput:output:viewController:completion:")]
        void EditVideo(NSUrl input, NSUrl output, UIViewController viewController, Action<NSUrl, NSError> completion);

        [Export("concatVideosWithInput:output:completion:")]
        void ConcatVideos(NSUrl[] input, NSUrl output, Action<NSUrl, NSError> completion);

        [Export("mergeVideosWithInput:output:width:height:frameRate:completion:")]
        void MergeVideos(NSUrl[] input, NSUrl output, NSNumber width, NSNumber height, VideoFrameRate frameRate, Action<NSUrl, NSError> completion);

        [Export("encodeVideoWithInput:output:width:height:frameRate:completion:")]
        void EncodeVideo(NSUrl input, NSUrl output, NSNumber width, NSNumber height, VideoFrameRate frameRate, Action<NSUrl, NSError> completion);

        [Export("compareVideosWithInput:completion:")]
        void CompareVideos(NSUrl[] input, Action<bool, NSError> completion);

        [Export("clearNoiseWithInput:output:completion:")]
        void ClearNoise(NSUrl input, NSUrl output, Action<NSUrl, NSError> completion);
        
        [Export("getVideoInfoWithInput:completion:")]
        void GetVideoInfo(NSUrl input, Action<NSArray, NSError> completion);
    }
}

