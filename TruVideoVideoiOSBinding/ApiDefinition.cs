using System;
using Foundation;
using ObjCRuntime;

namespace TruvideoVideoiOS {
    // @interface ThumbnailRequest : NSObject
    [BaseType(typeof(NSObject), Name = "_TtC13TruvideoVideo16ThumbnailRequest")]
    [DisableDefaultCtor]
    interface ThumbnailRequest
    {
        // -(instancetype _Nonnull)initWithUrl:(NSURL * _Nonnull)url position:(NSNumber * _Nullable)position width:(NSNumber * _Nullable)width height:(NSNumber * _Nullable)height __attribute__((objc_designated_initializer));
        [Export("initWithUrl:position:width:height:")]
        [DesignatedInitializer]
        IntPtr Constructor(NSUrl url, [NullAllowed] NSNumber position, [NullAllowed] NSNumber width, [NullAllowed] NSNumber height);
    }

    // @interface TruvideoVideoSdk : NSObject
    [BaseType(typeof(NSObject), Name = "_TtC13TruvideoVideo16TruvideoVideoSdk")]
    interface TruvideoVideoSdk
    {
        // @property (readonly, nonatomic, strong, class) TruvideoVideoSdk * _Nonnull shared;
        [Static]
        [Export("shared", ArgumentSemantic.Strong)]
        TruvideoVideoSdk Shared { get; }

        // -(void)generateThumbnailWithRequest:(ThumbnailRequest * _Nonnull)request completionHandler:(void (^ _Nonnull)(NSURL * _Nullable, NSError * _Nullable))completionHandler;
        [Export("generateThumbnailWithRequest:completionHandler:")]
        void GenerateThumbnailWithRequest(ThumbnailRequest request, Action<NSUrl, NSError> completionHandler);
    }
}