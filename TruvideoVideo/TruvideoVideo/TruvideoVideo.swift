import Foundation
import TruvideoSdkVideo
import CommonCrypto

@objc
final public class TruvideoVideoSdk: NSObject {
    
    @objc
    public static let shared = TruvideoVideoSdk()
    
    @objc
    public func generateThumbnail(request: ThumbnailRequest) async throws -> URL {
        let result = try await TruvideoSdkVideo.generateThumbnail(
            input: TruvideoSdkVideoFile(url: request.url),
            output: .files(fileName: UUID().uuidString),
            position: request.position?.doubleValue ?? 0.5,
            width: request.width?.intValue,
            height: request.height?.intValue
        ).generatedThumbnailURL
        return result
    }
}

@objc public class ThumbnailRequest: NSObject {
    @objc
    public init(url: URL, position: NSNumber?, width: NSNumber?, height: NSNumber?) {
        self.url = url
        self.position = position
        self.width = width
        self.height = height
        super.init()
    }
    
    var url: URL
    var position: NSNumber?
    var width: NSNumber?
    var height: NSNumber?
}
