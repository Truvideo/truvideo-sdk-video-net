import Foundation
import TruvideoSdkVideo
import CommonCrypto
import UIKit
import Combine

@objc
final public class TruvideoVideoSdk: NSObject {
    
    @objc
    public static let shared = TruvideoVideoSdk()
    private var cancellables = Set<AnyCancellable>()
    private var requestStreams: [UUID: AnyCancellable] = [:]
    private var processingRequests = Set<UUID>()
    private var cancellingRequests = Set<UUID>()
    
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
    public func getAllRequestObjC(withStatus: VideoRequestStatus, completion: @escaping (_ result: NSArray?, _ error: NSError?) -> Void) {
        guard let status = convertMediaStatusToTruvideoStatus(withStatus) as? TruvideoSdkVideoRequest.Status else {
            completion(nil, NSError(domain: "Invalid status", code: -1, userInfo: nil))
            return
        }

        Task {
            do {
                let requests = try TruvideoSdkVideo.getRequests(withStatus: status)
                let array = requests.map { request in
                    return [
                        "id": request.id.uuidString,
                        "status": "\(request.status)",
                        "type": "\(request.type)"
                    ] as NSDictionary
                }
                completion(array as NSArray, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }
    
    @objc
    public func streamRequestsObjC(withStatus: VideoRequestStatus, completion: @escaping (_ result: NSArray?, _ error: NSError?) -> Void) {
        guard let status = convertMediaStatusToTruvideoStatus(withStatus) as? TruvideoSdkVideoRequest.Status else {
            completion(nil, NSError(domain: "Invalid status", code: -1, userInfo: nil))
            return
        }

        TruvideoSdkVideo.streamRequests(withStatus: status)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(nil, error as NSError)
                }
            }, receiveValue: { requests in
                let array = requests.map { request in
                    return [
                        "id": request.id.uuidString,
                        "status": "\(request.status)",
                        "type": "\(request.type)"
                    ] as NSDictionary
                }
                completion(array as NSArray, nil)
            })
            .store(in: &cancellables)
    }


    
    @objc
    public func streamRequests(withId: String, completion: @escaping (_ result: NSDictionary?, _ error: NSError?) -> Void) {
        
        Task{
            do{
                guard let uuid = UUID(uuidString: withId) else {
                    completion(nil, NSError(domain: "Invalid UUID", code: -1, userInfo: nil))
                    return
                }

               try TruvideoSdkVideo.streamRequest(withId: uuid)
                    .sink(receiveCompletion: { result in
                        if case .failure(let error) = result {
                            completion(nil, error as NSError)
                        }
                    }, receiveValue: { videoRequest in
                        var dict: [String: Any] = [
                            "id": videoRequest.id.uuidString,
                            "status": "\(videoRequest.status)",
                            "type": "\(videoRequest.type)",
                            "createdAt": videoRequest.createdAt.description,
                            "updatedAt": videoRequest.updatedAt.description,
                        ]

                        if let errorMessage = videoRequest.errorMessage {
                            dict["errorMessage"] = errorMessage
                        }

                        if let outputPath = videoRequest.outputPath {
                            dict["outputPath"] = outputPath.absoluteString
                        }
                        let output = videoRequest.output
                        dict["output"] = "\(output)" // fallback text representation

                        if let encodingData = videoRequest.encodingData {
                            var enc: [String: Any] = [
                                "inputFileURL": encodingData.inputFileURL.absoluteString,
                                "videoTracksCount": encodingData.videoTracks.count,
                                "audioTracksCount": encodingData.audioTracks.count,
                                "framesRate": "\(encodingData.framesRate)"
                            ]
                            if let width = encodingData.width {
                                enc["width"] = width
                            }
                            if let height = encodingData.height {
                                enc["height"] = height
                            }
                            dict["encodingData"] = enc
                        }
                      
                        if let mergeData = videoRequest.mergeData {
                            var merge: [String: Any] = [
                                "videos": mergeData.videos.map { $0.absoluteString },
                                "framesRate": "\(mergeData.framesRate)",
                                "videoTracksCount": mergeData.videoTracks.count,
                                "audioTracksCount": mergeData.audioTracks.count
                            ]
                            
                            if let width = mergeData.width {
                                merge["width"] = width
                            }
                            if let height = mergeData.height {
                                merge["height"] = height
                            }

                            dict["mergeData"] = merge
                        }
                        if let concatData = videoRequest.concatData {
                            let concat: [String: Any] = [
                                "videos": concatData.videos.map { $0.absoluteString },
                                "videoCount": concatData.videos.count
                            ]
                            dict["concatData"] = concat
                        }
                        completion(dict as NSDictionary, nil)
                    })
                    .store(in: &cancellables)
            }
            catch{
                completion(nil,error as NSError)
            }
        }
    }

    private func convertMediaStatusToTruvideoStatus(_ status: VideoRequestStatus) -> TruvideoSdkVideoRequest.Status {
        switch status {
        case .processing:
            return .processing
     
        case .cancelled:
            return .cancelled
        
        case .error:
            return .error
            
        case .idle:
            return .idle
            
        case .complete:
            return .complete
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
    public func concatVideos(input: [URL], output: URL, completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void)  {
        Task {
            do {
                
                let inputPaths = input.map { TruvideoSdkVideoFile(url: $0) }
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let result = try TruvideoSdkVideo.ConcatBuilder(input: inputPaths, output: outputPath).build()
                completion(result.videoRequest, nil)
                
            } catch {
                completion(nil, createError("Failed to concatenate videos: \(error.localizedDescription)"))
            }
        }
    }
    
    
    @objc
    public func mergeVideos(input: [URL], output: URL, width: NSNumber?, height: NSNumber?, frameRate: VideoFrameRate, completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void)  {
        Task {
            do {
                let inputPaths = input.map { TruvideoSdkVideoFile(url: $0) }
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let builder = TruvideoSdkVideo.MergeBuilder(input: inputPaths, output: outputPath)
                builder.width = CGFloat(width?.intValue ?? 0)
                builder.height = CGFloat(height?.intValue ?? 0)
                builder.framesRate = convertFramerate(frameRate)
                let result = try builder.build()
                completion(result.videoRequest, nil)
            } catch {
                completion(nil, createError("Failed to merge videos: \(error.localizedDescription)"))
            }
        }
    }
    
    
    
    private func convertAudioTracksToTruvideoMergeTracks(_ videoTracks: [MergeAudioTracks]) -> [TruvideoSdkVideoMergeAudioTrack] {
        let mediaEntries = videoTracks.map {
            TruvideoSdkVideoMergeMediaEntry(
                fileIndex: $0.fileIndex.intValue,
                entryIndex: $0.entryIndex.intValue
            )
        }


        let mergeTrack = TruvideoSdkVideoMergeAudioTrack(tracks: mediaEntries)

        return [mergeTrack]
    }
    
    private func convertVideoTracksToTruvideoMergeTracks(_ videoTracks: [MergeVideoTracks]) -> [TruvideoSdkVideoMergeVideoTrack] {
        let mediaEntries = videoTracks.map {
            TruvideoSdkVideoMergeMediaEntry(
                fileIndex: $0.fileIndex.intValue,
                entryIndex: $0.entryIndex.intValue
            )
        }

        // Optional width and height — use first valid one if exists
        let width = videoTracks.first(where: { $0.width != nil })?.width?.intValue
        let height = videoTracks.first(where: { $0.height != nil })?.height?.intValue

        let mergeTrack = TruvideoSdkVideoMergeVideoTrack(
            tracks: mediaEntries,
            width: width,
            height: height
        )

        return [mergeTrack]
    }

    @objc
    public func encodeVideo( input: URL, output: URL, width: NSNumber?, height: NSNumber?, frameRate: VideoFrameRate,completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void)  {
        Task {
            do {
                let inputPath = TruvideoSdkVideoFile(url: input)
                let outputPath = TruvideoSdkVideoFileDescriptor.files(fileName: output.lastPathComponent)
                let builder = TruvideoSdkVideo.EncodingBuilder(input: inputPath, output: outputPath)
                builder.width = CGFloat(width?.intValue ?? 0)
                builder.height = CGFloat(height?.intValue ?? 0)
                builder.framesRate = convertFramerate(frameRate)
                let result = builder.build()
                completion(result.videoRequest, nil)
                
            } catch {
                completion(nil, createError("Failed to encode video: \(error.localizedDescription)"))
            }
        }
    }
    
    private func convertVideoTracksTOTruvideVideoTracks(_ videoTracks: [VideoTracks]) -> [TruvideoSdkVideoEncodeVideoEntry] {
        return videoTracks.map { track in
            TruvideoSdkVideoEncodeVideoEntry(
                entryIndex: track.entryIndex.intValue,
                width: track.width?.intValue,
                height: track.height?.intValue
            )
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
    public func getRequestById(
        id: String,
        completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void
    ) {
        guard let uuid = UUID(uuidString: id) else {
            completion(nil, createError("Invalid id"))
            return
        }

        do {
            let cancellable = try TruvideoSdkVideo.streamRequest(withId: uuid)
                .first()
                .sink(
                    receiveCompletion: { completionState in
                        if case .failure(let error) = completionState {
                            completion(nil, error)
                        }
                    },
                    receiveValue: { request in
                        completion(request.videoRequest, nil)
                    }
                )

            requestStreams[uuid] = cancellable
        } catch {
            completion(nil, error)
        }
    }

    
//    @objc
//    public func process(
//        id: String,
//        completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void
//    ) {
//        guard let uuid = UUID(uuidString: id) else {
//            completion(nil, createError("Invalid request id"))
//            return
//        }
//
//        guard processingRequests.insert(uuid).inserted else {
//            completion(nil, createError("Process already started"))
//            return
//        }
//
//        do {
//            let publisher = try TruvideoSdkVideo.streamRequest(withId: uuid)
//                .removeDuplicates(by: { $0.status == $1.status })
//                .share()
//
//            let cancellable = publisher
//                .sink(
//                    receiveCompletion: { [weak self] completionState in
//                        self?.processingRequests.remove(uuid)
//                        if case .failure(let error) = completionState {
//                            completion(nil, error)
//                        }
//                    },
//                    receiveValue: { [weak self] request in
//                        guard request.status == .idle else { return }
//
//                        Task {
//                            do {
//                                try await request.process()
//                                completion(request.videoRequest, nil)
//                            } catch {
//                                completion(nil, error)
//                            }
//                            self?.processingRequests.remove(uuid)
//                        }
//                    }
//                )
//
//            requestStreams[uuid] = cancellable
//
//        } catch {
//            processingRequests.remove(uuid)
//            completion(nil, error)
//        }
//    }
//
//    @objc
//    public func cancel(
//        id: String,
//        completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void
//    ) {
//        guard let uuid = UUID(uuidString: id) else {
//            completion(nil, createError("Invalid request id"))
//            return
//        }
//
//        guard cancellingRequests.insert(uuid).inserted else {
//            completion(nil, createError("Cancel already in progress"))
//            return
//        }
//
//        do {
//            let publisher = try TruvideoSdkVideo.streamRequest(withId: uuid)
//                .removeDuplicates(by: { $0.status == $1.status })
//                .share()
//
//            let cancellable = publisher
//                .sink(
//                    receiveCompletion: { [weak self] completionState in
//                        self?.cancellingRequests.remove(uuid)
//                        if case .failure(let error) = completionState {
//                            completion(nil, error)
//                        }
//                    },
//                    receiveValue: { [weak self] request in
//                        guard request.status != .cancelled,
//                              request.status != .complete else {
//                            self?.cancellingRequests.remove(uuid)
//                            completion(request.videoRequest, nil)
//                            return
//                        }
//
//                        do {
//                            try request.cancel()
//                            completion(request.videoRequest, nil)
//                        } catch {
//                            completion(nil, error)
//                        }
//
//                        self?.cancellingRequests.remove(uuid)
//                    }
//                )
//
//            requestStreams[uuid] = cancellable
//
//        } catch {
//            cancellingRequests.remove(uuid)
//            completion(nil, error)
//        }
//    }

    @objc
    public func process(
        id: String,
        completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void
    ) {
        guard let uuid = UUID(uuidString: id) else {
            completion(nil, createError("Invalid request id"))
            return
        }

        guard processingRequests.insert(uuid).inserted else {
            completion(nil, createError("Request already processing"))
            return
        }

        var hasCalledCompletion = false
        let completionOnce: (TruvideoVideoSdkRequest?, Error?) -> Void = { result, error in
            guard !hasCalledCompletion else { return }
            hasCalledCompletion = true
            completion(result, error)
        }

        do {
            let cancellable = try TruvideoSdkVideo.streamRequest(withId: uuid)
                .first() // 🔑 ALWAYS take first emission
                .sink(
                    receiveCompletion: { [weak self] completionState in
                        self?.processingRequests.remove(uuid)
                        self?.requestStreams.removeValue(forKey: uuid)

                        if case .failure(let error) = completionState {
                            completionOnce(nil, error)
                        }
                    },
                    receiveValue: { [weak self] request in
                        guard let self = self else { return }
                        
                        // Cancel subscription immediately after getting the value
                        self.requestStreams.removeValue(forKey: uuid)?.cancel()

                        // 🔑 STATE CHECK HERE
                        guard request.status == .idle else {
                            completionOnce(
                                request.videoRequest,
                                self.createError("Request already in progress")
                            )
                            self.processingRequests.remove(uuid)
                            return
                        }

                        Task {
                            do {
                                try await request.process()
                                completionOnce(request.videoRequest, nil)
                            } catch {
                                completionOnce(nil, error)
                            }

                            self.processingRequests.remove(uuid)
                        }
                    }
                )

            requestStreams[uuid] = cancellable

        } catch {
            processingRequests.remove(uuid)
            completion(nil, error)
        }
    }

    @objc
    public func cancel(
        id: String,
        completion: @escaping (_ result: TruvideoVideoSdkRequest?, _ error: Error?) -> Void
    ) {
        guard let uuid = UUID(uuidString: id) else {
            completion(nil, createError("Invalid request id"))
            return
        }

        guard cancellingRequests.insert(uuid).inserted else {
            completion(nil, createError("Cancel already in progress"))
            return
        }

        var hasCalledCompletion = false
        let completionOnce: (TruvideoVideoSdkRequest?, Error?) -> Void = { result, error in
            guard !hasCalledCompletion else { return }
            hasCalledCompletion = true
            completion(result, error)
        }

        do {
            let cancellable = try TruvideoSdkVideo.streamRequest(withId: uuid)
                .first() // 🔑 NOT first(where:)
                .sink(
                    receiveCompletion: { [weak self] completionState in
                        self?.cancellingRequests.remove(uuid)
                        self?.requestStreams.removeValue(forKey: uuid)

                        if case .failure(let error) = completionState {
                            completionOnce(nil, error)
                        }
                    },
                    receiveValue: { [weak self] request in
                        guard let self = self else { return }
                        
                        // Cancel subscription immediately after getting the value
                        self.requestStreams.removeValue(forKey: uuid)?.cancel()

                        guard request.status == .processing else {
                            completionOnce(
                                request.videoRequest,
                                self.createError("Request is not processing")
                            )
                            self.cancellingRequests.remove(uuid)
                            return
                        }

                        Task {
                            do {
                                try await request.cancel()
                                completionOnce(request.videoRequest, nil)
                            } catch {
                                completionOnce(nil, error)
                            }

                            self.cancellingRequests.remove(uuid)
                        }
                    }
                )

            requestStreams[uuid] = cancellable

        } catch {
            cancellingRequests.remove(uuid)
            completion(nil, error)
        }
    }


    @objc
    public func getVideoInfo(input: URL, completion: @escaping (_ response: [String: Any]?, _ error: Error?) -> Void) {
        Task {
            do {
                let inputPath: TruvideoSdkVideoFile = .init(url: input)
                let result = try await TruvideoSdkVideo.getVideoInformation(input: .init(url: input))
                let newResult: [String: Any] = [
                    "path": result.path,
                    "size": result.size,
                    "durationMillis": result.durationMillis,
                    "format": result.format,
                    "videos": result.videoTracks.map { video in
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
                    "audios": result.audioTracks.map { audio in
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
                ]
//                let dictionaryResult = result.map { videoInfo in
//                    return [
//                        "path": videoInfo.path,
//                        "size": videoInfo.size,
//                        "durationMillis": videoInfo.durationMillis,
//                        "format": videoInfo.format,
//                        "videos": videoInfo.videos.map { video in
//                            return [
//                                "index": video.index,
//                                "width": video.width,
//                                "height": video.height,
//                                "rotatedWidth": video.rotatedWidth,
//                                "rotatedHeight": video.rotatedHeight,
//                                "codec": video.codec,
//                                "codecTag": video.codecTag,
//                                "pixelFormat": video.pixelFormat,
//                                "bitRate": video.bitRate,
//                                "frameRate": video.frameRate,
//                                "rotation": video.rotation,
//                                "durationMillis": video.durationMillis
//                            ] as [String: Any]
//                        },
//                        "audios": videoInfo.audios.map { audio in
//                            return [
//                                "index": audio.index,
//                                "codec": audio.codec,
//                                "codecTag": audio.codecTag,
//                                "sampleFormat": audio.sampleFormat,
//                                "bitRate": audio.bitRate,
//                                "sampleRate": audio.sampleRate,
//                                "channels": audio.channels,
//                                "channelLayout": audio.channelLayout,
//                                "durationMillis": audio.durationMillis
//                            ] as [String: Any]
//                        }
//                    ] as [String: Any]
//                }
                
                completion(newResult, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    
    func convertFramerate(_ frameRate: VideoFrameRate) -> TruvideoSdkVideoFrameRate {
        switch frameRate {
        case .twentyFourFps : return .twentyFourFps
        case .twentyFiveFps : return .twentyFiveFps
        case .thirtyFps : return .thirtyFps
        case .fiftyFps : return .fiftyFps
        case .sixtyFps : return .sixtyFps
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

@objc public class VideoTracks: NSObject{
    
    @objc public init(entryIndex: NSNumber, width: NSNumber? = nil, height: NSNumber? = nil){
        self.entryIndex = entryIndex
        self.width = width
        self.height = height
        
    }
    
    var entryIndex: NSNumber
    var width: NSNumber?
    var height: NSNumber?
}


@objc public class MergeVideoTracks: NSObject{
    
    @objc public init(entryIndex: NSNumber, width: NSNumber? = nil, height: NSNumber? = nil,fileIndex : NSNumber){
        self.entryIndex = entryIndex
        self.width = width
        self.height = height
        self.fileIndex = fileIndex
    }
    
    var fileIndex: NSNumber
    var entryIndex: NSNumber
    var width: NSNumber?
    var height: NSNumber?
}

@objc public class MergeAudioTracks: NSObject{
    
    @objc public init(entryIndex: NSNumber,fileIndex : NSNumber){
        self.entryIndex = entryIndex
        self.fileIndex = fileIndex
    }
    
    var fileIndex: NSNumber
    var entryIndex: NSNumber
}


@objc public enum VideoRequestStatus: Int {
    case cancelled
    case error
    case idle
    case processing
    case complete
}

@objc public enum VideoFrameRate: Int {
    case twentyFourFps
    case twentyFiveFps
    case thirtyFps
    case fiftyFps
    case sixtyFps
}

extension TruvideoSdkVideoRequest{
    var videoRequest:TruvideoVideoSdkRequest{
        TruvideoVideoSdkRequest(id: id as NSUUID,
                                type: convertTruvideoTypeToVideoRequestType(type),
                                status: convertMediaStatusToTruvideoStatus(status),
                                createdAt: createdAt,
                                updatedAt: updatedAt,
                                errorMessage: errorMessage,
                                outputPath: outputPath
        )
        
    }
    
    private func convertTruvideoTypeToVideoRequestType(_ truvideoType: TruvideoSdkVideo.TruvideoSdkVideoRequest.`Type`) -> VideoRequestType {
        switch truvideoType {
        case .encode:
            return .encode
        case .merge:
            return .merge
        case .concat:
            return .concat
        default:
            return .concat
        }
    }
    
    private func convertMediaStatusToTruvideoStatus(_ status: TruvideoSdkVideoRequest.Status) ->  VideoRequestStatus{
        switch status {
        case .processing:
            return .processing
     
        case .cancelled:
            return .cancelled
        
        case .error:
            return .error
            
        case .idle:
            return .idle
            
        case .complete:
            return .complete
        @unknown default:
            return .idle
        }
    }
}

@objc public class TruvideoVideoSdkRequest: NSObject{
    
    internal init(
        id: NSUUID,
        type: VideoRequestType ,
        status: VideoRequestStatus,
        createdAt: Date? = nil,
        updatedAt: Date = Date(),
        errorMessage: String? = nil,
        outputPath: URL? = nil
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.errorMessage = errorMessage
        self.outputPath = outputPath
    }
    
    @objc public let id: NSUUID
    @objc public let type: VideoRequestType
    @objc public let status: VideoRequestStatus
    @objc public let createdAt: Date?
    @objc public let updatedAt: Date
    @objc public let errorMessage: String?
    @objc public let outputPath: URL?
}

@objc public enum VideoRequestType: Int {
    case encode
    case merge
    case concat
}



