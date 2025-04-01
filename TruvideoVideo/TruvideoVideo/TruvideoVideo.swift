import Foundation
import TruvideoSdkVideo
import CommonCrypto
import UIKit

@objc
final public class TruvideoVideoSdk: NSObject {
    
    @objc
    public static let shared = TruvideoVideoSdk()
    
    private func createError(_ message: String, code: Int = -1) -> NSError {
        return NSError(domain: "TruvideoVideoSdkError", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    @objc
    public func generateThumbnail(request: ThumbnailRequest,completion: @escaping (_ result: URL?, _ error: Error?) -> Void)   {
        Task {
            do {
                
                let result = try await TruvideoSdkVideo.generateThumbnail(input: TruvideoSdkVideoFile(url: request.url), output: TruvideoSdkVideoFileDescriptor.files(fileName: request.outputURL.lastPathComponent), position: request.position?.doubleValue ?? 1, width: request.width?.intValue, height: request.height?.intValue)
                completion(result.generatedThumbnailURL, nil)
                
            } catch {
                completion(nil, createError("Failed to generate thumbnail: \(error.localizedDescription)"))
            }
        }
    }
    
    @objc
    public func editVideo(input: URL, output: URL, viewController: UIViewController, completion: @escaping (_ result: URL?, _ error: Error?) -> Void) {
            let inputPath = TruvideoSdkVideoFile(url: input)
            let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
            
            DispatchQueue.main.async {
                viewController.presentTruvideoSdkVideoEditorView(input: inputPath, output: outputPath) { result in
                    if let editedURL = result.editedVideoURL {
                        completion(editedURL, nil)
                    } else {
                        completion(nil, self.createError("Failed to edit video. No URL returned."))
                    }
                }
            }
        
    }
    
    @objc
    public func concatVideos(input: [URL], output: URL, completion: @escaping (_ result: URL?, _ error: Error?) -> Void)  {
        Task {
            do {
                
                let inputPaths = input.map { TruvideoSdkVideoFile(url: $0) }
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let result = try await TruvideoSdkVideo.ConcatBuilder(input: inputPaths, output: outputPath).build().process()
                completion(result.videoURL, nil)
                
            } catch {
                completion(nil, createError("Failed to concatenate videos: \(error.localizedDescription)"))
            }
        }
    }
    
    @objc
    public func mergeVideos(input: [URL], output: URL, width: NSNumber?, height: NSNumber?, frameRate: String,completion: @escaping (_ result: URL?, _ error: Error?) -> Void)  {
        Task {
            do {
                let inputPaths = input.map { TruvideoSdkVideoFile(url: $0) }
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let builder = TruvideoSdkVideo.MergeBuilder(input: inputPaths, output: outputPath)
                builder.width = CGFloat(width?.intValue ?? 0)
                builder.height = CGFloat(height?.intValue ?? 0)
                builder.framesRate = convertStringToFramerate(frameRate)
                let result = try await builder.build().process()
                completion(result.videoURL, nil)
                
            } catch {
                completion(nil, createError("Failed to merge videos: \(error.localizedDescription)"))
            }
        }
    }
    
    @objc
    public func encodeVideo( input: URL, output: URL, width: NSNumber?, height: NSNumber?, frameRate: String,completion: @escaping (_ result: URL?, _ error: Error?) -> Void)  {
        Task {
            do {
                
                let inputPath = TruvideoSdkVideoFile(url: input)
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let builder = TruvideoSdkVideo.EncodingBuilder(input: inputPath, output: outputPath)
                builder.width = CGFloat(width?.intValue ?? 0)
                builder.height = CGFloat(height?.intValue ?? 0)
                builder.framesRate = convertStringToFramerate(frameRate)
                let result = try await builder.build().process()
                completion(result.videoURL, nil)
                
            } catch {
                completion(nil, createError("Failed to encode video: \(error.localizedDescription)"))
            }
        }
    }
    
    @objc
    public func compareVideos(input: [URL],completion: @escaping (_ result: Bool, _ error: Error?) -> Void)  {
        Task {
            do {
                
                let inputPaths = input.map { TruvideoSdkVideoFile(url: $0) }
                let result = try await TruvideoSdkVideo.canConcat(input: inputPaths)
                completion(result, nil)
                
            } catch {
                completion(false, createError("Failed to compare videos: \(error.localizedDescription)"))
            }
        }
    }
    
    @objc
    public func clearNoise( input: URL, output: URL,completion: @escaping (_ result: URL?, _ error: Error?) -> Void)  {
        Task {
            do {
                
                let inputPath = TruvideoSdkVideoFile(url: input)
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let result = try await TruvideoSdkVideo.engine.clearNoiseForFile(input: inputPath, output: outputPath)
                completion(result.fileURL, nil)
                
            } catch {
                completion(nil, createError("Failed to clear noise: \(error.localizedDescription)"))
            }
        }
    }
    
    @objc
    public func getVideoInfo(input: URL, completion: @escaping (_ response: [[String: Any]]?, _ error: Error?) -> Void) {
        Task {
            do {
                let inputPath: TruvideoSdkVideoFile = .init(url: input)
                let result = try await TruvideoSdkVideo.getVideosInformation(input: [inputPath])
                
                let dictionaryResult = result.map { videoInfo in
                    return [
                        "path": videoInfo.path,
                        "size": videoInfo.size,
                        "durationMillis": videoInfo.durationMillis,
                        "format": videoInfo.format,
                        "videos": videoInfo.videos.map { video in
                            return [
                                "index": video.index,
                                "width": video.width,
                                "height": video.height,
                                "rotatedWidth": video.rotatedWidth,
                                "rotatedHeight": video.rotatedHeight,
                                "codec": video.codec,
                                "codecTag": video.codecTag,
                                "pixelFormat": video.pixelFormat,
                                "bitRate": video.bitRate,
                                "frameRate": video.frameRate,
                                "rotation": video.rotation,
                                "durationMillis": video.durationMillis
                            ] as [String: Any]
                        },
                        "audios": videoInfo.audios.map { audio in
                            return [
                                "index": audio.index,
                                "codec": audio.codec,
                                "codecTag": audio.codecTag,
                                "sampleFormat": audio.sampleFormat,
                                "bitRate": audio.bitRate,
                                "sampleRate": audio.sampleRate,
                                "channels": audio.channels,
                                "channelLayout": audio.channelLayout,
                                "durationMillis": audio.durationMillis
                            ] as [String: Any]
                        }
                    ] as [String: Any]
                }
                
                completion(dictionaryResult, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    
    func convertStringToFramerate(_ frameRate: String) -> TruvideoSdkVideoFrameRate {
        switch frameRate {
        case "24": return .twentyFourFps
        case "25": return .twentyFiveFps
        case "30": return .thirtyFps
        case "50": return .fiftyFps
        case "60": return .sixtyFps
        default: return .twentyFourFps
        }
    }
}

@objc public class ThumbnailRequest: NSObject {
    @objc
    public init(url: URL, position: NSNumber?, width: NSNumber?, height: NSNumber?,outputURL: URL) {
        self.url = url
        self.position = position
        self.width = width
        self.height = height
        self.outputURL = outputURL
        super.init()
    }
    
    var url: URL
    var position: NSNumber?
    var width: NSNumber?
    var height: NSNumber?
    var outputURL: URL
}
