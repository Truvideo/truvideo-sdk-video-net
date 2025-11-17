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
        void ConcatVideos(NSUrl[] input, NSUrl output, Action<TruvideoVideoSdkRequest, NSError> completion);
        
        [Export("mergeVideosWithInput:output:width:height:frameRate:completion:")]
        void MergeVideos(NSUrl[] input, NSUrl output, NSNumber width, NSNumber height, VideoFrameRate frameRate, Action<TruvideoVideoSdkRequest, NSError> completion);

        [Export("encodeVideoWithInput:output:width:height:frameRate:completion:")]
        void EncodeVideo(NSUrl input, NSUrl output, NSNumber width, NSNumber height, VideoFrameRate frameRate, Action<TruvideoVideoSdkRequest, NSError> completion);

        [Export("compareVideosWithInput:completion:")]
        void CompareVideos(NSUrl[] input, Action<bool, NSError> completion);

        [Export("clearNoiseWithInput:output:completion:")]
        void ClearNoise(NSUrl input, NSUrl output, Action<NSUrl, NSError> completion);
        
        // [Export("getVideoInfoWithInput:completion:")]
        // void GetVideoInfo(NSUrl input, Action<NSArray, NSError> completion);
        
        [Export("getVideoInfoWithInput:completion:")]
        void GetVideoInfo(NSUrl input, Action<NSDictionary, NSError> completion);
        
        // Additional exposed methods from your Swift
        
        
        [Export("getAllRequestObjCWithStatus:completion:")]
        void GetAllRequestObjC(VideoRequestStatus withStatus, Action<NSArray, NSError> completion);
        
        [Export("streamRequestsObjCWithStatus:completion:")]
        void StreamRequestsObjC(VideoRequestStatus withStatus, Action<NSArray, NSError> completion);
        
        [Export("streamRequestsWithId:completion:")]
        void StreamRequests(string id, Action<NSDictionary, NSError> completion);

        [Export("getRequestByIdWithId:completion:")]
        void GetRequestById(string id, Action<TruvideoVideoSdkRequest, NSError> completion);

        [Export("cancelWithId:completion:")]
        void Cancel(string id, Action<TruvideoVideoSdkRequest, NSError> completion);

        [Export("processWithId:completion:")]
        void Process(string id, Action<TruvideoVideoSdkRequest, NSError> completion);
        
        
    }
    
    [BaseType(typeof(NSObject),  Name = "_TtC13TruvideoVideo23TruvideoVideoSdkRequest")]
    interface TruvideoVideoSdkRequest
    {
        [Export("id")]
        NSUuid Id { get; }

        [Export("type")]
        VideoRequestType Type { get; }

        [Export("status")]
        VideoRequestStatus Status { get; }

        [NullAllowed, Export("createdAt")]
        NSDate CreatedAt { get; }

        [Export("updatedAt")]
        NSDate UpdatedAt { get; }

        [NullAllowed, Export("errorMessage")]
        string ErrorMessage { get; }

        [NullAllowed, Export("outputPath")]
        NSUrl OutputPath { get; }
    }
    
    
    [BaseType(typeof(NSObject),  Name = "_TtC13TruvideoVideo11VideoTracks")]
    interface VideoTracks
    {
        [Export("initWithEntryIndex:width:height:")]
        IntPtr Constructor(NSNumber entryIndex, [NullAllowed] NSNumber width, [NullAllowed] NSNumber height);
    }
    
    [BaseType(typeof(NSObject),  Name = "_TtC13TruvideoVideo16MergeVideoTracks")]
    interface MergeVideoTracks
    {
        [Export("initWithEntryIndex:width:height:fileIndex:")]
        IntPtr Constructor(NSNumber entryIndex, [NullAllowed] NSNumber width, [NullAllowed] NSNumber height, NSNumber fileIndex);
    }
    
    [BaseType(typeof(NSObject),  Name = "_TtC13TruvideoVideo16MergeAudioTracks")]
    interface MergeAudioTracks
    {
        [Export("initWithEntryIndex:fileIndex:")]
        IntPtr Constructor(NSNumber entryIndex, NSNumber fileIndex);
    }
}

