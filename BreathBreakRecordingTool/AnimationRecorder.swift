import SwiftUI
import AVFoundation
import AppKit

class AnimationRecorder {
    private let logger: RecordingLogger?
    
    init(logger: RecordingLogger? = nil) {
        self.logger = logger
    }
    
    private func log(_ message: String, type: RecordingLogger.LogEntry.LogType = .info) {
        logger?.log(message, type: type)
        print(message) // Keep console logging as well
    }
    
    func recordAnimation(
        exercise: BreathingExercise,
        duration: TimeInterval,
        size: CGSize,
        theme: BreathingTheme,
        completion: @escaping (Bool, URL?) -> Void
    ) {
        // Use temporary directory (always works, no permissions needed)
        let tempDir = FileManager.default.temporaryDirectory
        
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "BreathingAnimation_\(exercise.name.replacingOccurrences(of: " ", with: "_"))_\(timestamp).mov"
        let outputURL = tempDir.appendingPathComponent(fileName)
        
        log("Ã°Å¸â€œâ€š Saving to temp: \(outputURL.path)", type: .info)
        
        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        // Start recording
        self.startRecording(
            exercise: exercise,
            duration: duration,
            size: size,
            outputURL: outputURL,
            theme: theme,
            completion: completion
        )
    }
    
    private func startRecording(
        exercise: BreathingExercise,
        duration: TimeInterval,
        size: CGSize,
        outputURL: URL,
        theme: BreathingTheme,
        completion: @escaping (Bool, URL?) -> Void
    ) {
        // Setup video writer
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else {
            log("Ã¢ÂÅ’ Failed to create AVAssetWriter", type: .error)
            log("Output URL: \(outputURL.path)", type: .error)
            completion(false, nil)
            return
        }
        
        log("Ã¢Å“â€¦ AVAssetWriter created successfully", type: .success)
        log("Ã°Å¸Å½Â¬ Output: \(outputURL.lastPathComponent)", type: .info)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000, // 10 Mbps for high quality
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
        )
        
        videoWriter.add(videoWriterInput)
        
        // Render frames settings
        let fps: Int32 = 60
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        let totalFrames = Int(duration * Double(fps))
        
        log("Ã°Å¸Å½Â¬ Starting video writing session...", type: .info)
        log("   Resolution: \(Int(size.width))Ãƒâ€”\(Int(size.height))", type: .info)
        log("   Duration: \(duration) seconds", type: .info)
        log("   FPS: \(fps)", type: .info)
        log("   Total frames: \(totalFrames)", type: .info)
        
        // Start writing
        guard videoWriter.startWriting() else {
            log("Ã¢ÂÅ’ Failed to start writing", type: .error)
            if let error = videoWriter.error {
                log("   Error: \(error.localizedDescription)", type: .error)
            }
            log("   Writer status: \(videoWriter.status.rawValue)", type: .error)
            completion(false, nil)
            return
        }
        
        log("Ã¢Å“â€¦ Writing started successfully", type: .success)
        
        videoWriter.startSession(atSourceTime: .zero)
        
        var frameCount: Int64 = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.log("Starting to render \(totalFrames) frames...", type: .progress)
            
            for i in 0..<totalFrames {
                autoreleasepool {
                    while !videoWriterInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.01)
                    }
                    
                    let presentationTime = CMTime(value: frameCount, timescale: CMTimeScale(fps))
                    
                    if let pixelBuffer = self.createPixelBuffer(
                        for: exercise,
                        at: Double(i) / Double(fps),
                        size: size,
                        theme: theme
                    ) {
                        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    }
                    
                    frameCount += 1
                    
                    // Progress logging
                    if i % Int(fps) == 0 {
                        let progress = Int((Double(i) / Double(totalFrames)) * 100)
                        self.log("Progress: \(progress)%", type: .progress)
                    }
                }
            }
            
            // Finish writing
            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                DispatchQueue.main.async {
                    if videoWriter.status == .completed {
                        self.log("Ã¢Å“â€¦ Video recording completed successfully!", type: .success)
                        completion(true, outputURL)
                    } else {
                        self.log("Ã¢ÂÅ’ Video recording failed with status: \(videoWriter.status.rawValue)", type: .error)
                        if let error = videoWriter.error {
                            self.log("Error: \(error.localizedDescription)", type: .error)
                        }
                        completion(false, nil)
                    }
                }
            }
        }
    }
    
    private func createPixelBuffer(
        for exercise: BreathingExercise,
        at time: TimeInterval,
        size: CGSize,
        theme: BreathingTheme
    ) -> CVPixelBuffer? {
        var resultBuffer: CVPixelBuffer?
        
        // MUST create SwiftUI views on main thread
        DispatchQueue.main.sync {
            let view = BreathingAnimationSnapshot(
                exercise: exercise,
                currentTime: time,
                size: size,
                theme: theme
            )
            
            // Use ImageRenderer for proper SwiftUI rendering
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(size)
            
            // Render to CGImage
            guard let cgImage = renderer.cgImage else {
                return
            }
            
            // Create pixel buffer
            var pixelBuffer: CVPixelBuffer?
            let options: [String: Any] = [
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
            
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                Int(size.width),
                Int(size.height),
                kCVPixelFormatType_32ARGB,
                options as CFDictionary,
                &pixelBuffer
            )
            
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
                return
            }
            
            // Lock pixel buffer
            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
            
            // Create bitmap context
            guard let context = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer),
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            ) else {
                return
            }
            
            // Draw the CGImage into the context
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
            
            resultBuffer = buffer
        }
        
        return resultBuffer
    }
}

// Snapshot view for rendering individual frames
struct BreathingAnimationSnapshot: View {
    let exercise: BreathingExercise
    let currentTime: TimeInterval
    let size: CGSize
    let theme: BreathingTheme
    
    private var patternComponents: (inhale: Double, hold: Double, exhale: Double) {
        let parts = exercise.pattern.split(separator: "-").compactMap { Double($0) }
        guard parts.count == 3 else { return (4, 0, 4) }
        return (parts[0], parts[1], parts[2])
    }
    
    private var totalCycleDuration: Double {
        let pattern = patternComponents
        return pattern.inhale + pattern.hold + pattern.exhale
    }
    
    private var currentPhase: BreathingPhase {
        let cycleTime = currentTime.truncatingRemainder(dividingBy: totalCycleDuration)
        let pattern = patternComponents
        
        if cycleTime < pattern.inhale {
            return .inhale
        } else if cycleTime < pattern.inhale + pattern.hold {
            return .hold
        } else {
            return .exhale
        }
    }
    
    private var rotation: Double {
        let cycleTime = currentTime.truncatingRemainder(dividingBy: totalCycleDuration)
        let cycleProgress = cycleTime / totalCycleDuration
        return 270 + (cycleProgress * 360)
    }
    
    enum BreathingPhase {
        case inhale, hold, exhale
        
        var text: String {
            switch self {
            case .inhale: return "Inhale"
            case .hold: return "Hold"
            case .exhale: return "Exhale"
            }
        }
        
        func color(for theme: BreathingTheme) -> Color {
            switch self {
            case .inhale: return theme.glowColor1
            case .hold: return theme.glowColor2
            case .exhale: return theme.glowColor2.opacity(0.7)
            }
        }
    }
    
    var body: some View {
        let minDimension = min(size.width, size.height)
        let scale = minDimension / 400 // Base scale on 400pt reference
        let circleSize = 300 * scale
        let lineWidth = 6 * scale
        let glowRadius = 25 * scale
        let blurRadius = 20 * scale
        let movingCircleSize = 80 * scale
        let movingCircleSmallSize = 40 * scale
        let movingCircleOffset = circleSize / 2
        let indicatorSize = 50 * scale
        let fontSize = 24 * scale
        
        ZStack {
            // Gradient background with theme colors
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.backgroundGradientStart,
                    theme.backgroundGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack {
                Spacer()
                
                ZStack {
                    // Main glowing ring with theme colors
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.glowColor1.opacity(0.7),
                                    theme.glowColor2.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: lineWidth
                        )
                        .shadow(color: theme.glowColor1.opacity(0.6), radius: glowRadius)
                        .frame(width: circleSize, height: circleSize)
                    
                    // Soft inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    theme.glowColor1.opacity(0.25),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 50 * scale,
                                endRadius: 180 * scale
                            )
                        )
                        .frame(width: circleSize, height: circleSize)
                        .blur(radius: blurRadius)
                    
                    // Moving glowing circle
                    ZStack {
                        Circle()
                            .fill(theme.glowColor1.opacity(0.3))
                            .blur(radius: blurRadius)
                            .frame(width: movingCircleSize, height: movingCircleSize)
                            .offset(x: movingCircleOffset)
                            .rotationEffect(.degrees(rotation))
                        
                        Circle()
                            .fill(.white)
                            .frame(width: movingCircleSmallSize, height: movingCircleSmallSize)
                            .shadow(color: theme.glowColor1.opacity(0.8), radius: blurRadius)
                            .offset(x: movingCircleOffset)
                            .rotationEffect(.degrees(rotation))
                    }
                    
                    // Phase indicator circles
                    ZStack {
                        let pattern = patternComponents
                        
                        let inhaleStartAngle = 270.0
                        let holdStartAngle = 270.0 + (pattern.inhale / totalCycleDuration) * 360
                        let exhaleStartAngle = 270.0 + ((pattern.inhale + pattern.hold) / totalCycleDuration) * 360
                        
                        let radius = circleSize / 2
                        
                        Group {
                            Circle()
                                .fill(currentPhase == .inhale ? BreathingPhase.inhale.color(for: theme) : Color.white.opacity(0.15))
                                .frame(width: indicatorSize, height: indicatorSize)
                                .offset(x: radius)
                                .rotationEffect(.degrees(inhaleStartAngle))
                            
                            Circle()
                                .fill(currentPhase == .hold ? BreathingPhase.hold.color(for: theme) : Color.white.opacity(0.15))
                                .frame(width: indicatorSize, height: indicatorSize)
                                .offset(x: radius)
                                .rotationEffect(.degrees(holdStartAngle))
                            
                            Circle()
                                .fill(currentPhase == .exhale ? BreathingPhase.exhale.color(for: theme) : Color.white.opacity(0.15))
                                .frame(width: indicatorSize, height: indicatorSize)
                                .offset(x: radius)
                                .rotationEffect(.degrees(exhaleStartAngle))
                        }
                    }
                    .frame(width: circleSize, height: circleSize)
                    
                    // Center text
                    Text(currentPhase.text)
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.glowColor1.opacity(0.7), radius: 10 * scale)
                }
                
                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
