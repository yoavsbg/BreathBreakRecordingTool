import SwiftUI

struct ContentView: View {
    @State private var selectedExercise: BreathingExercise = BreathingExercise.defaultExercises[0]
    @State private var selectedTheme: BreathingTheme = BreathingTheme.defaultThemes[0]
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 10.0
    @State private var exportSize: ExportSize = .instagram1080
    @StateObject private var logger = RecordingLogger()
    
    enum ExportSize: String, CaseIterable {
        case instagram1080 = "Instagram (1080x1080)"
        case instagram1920 = "Instagram Story (1080x1920)"
        case fullHD = "Full HD (1920x1080)"
        case fourK = "4K (3840x2160)"
        
        var resolution: CGSize {
            switch self {
            case .instagram1080: return CGSize(width: 1080, height: 1080)
            case .instagram1920: return CGSize(width: 1080, height: 1920)
            case .fullHD: return CGSize(width: 1920, height: 1080)
            case .fourK: return CGSize(width: 3840, height: 2160)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Preview Panel
            VStack {
                Text("Preview")
                    .font(.headline)
                    .padding(.top)
                
                BreathingAnimationPreview(
                    exercise: selectedExercise,
                    exportSize: exportSize,
                    theme: selectedTheme
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            }
            .frame(minWidth: 400)
            
            Divider()
            
            // Controls Panel
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Recording Settings")
                            .font(.title2)
                            .bold()
                            .padding(.top)
                        
                        // Exercise Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercise")
                                .font(.headline)
                            
                            Picker("Exercise", selection: $selectedExercise) {
                                ForEach(BreathingExercise.defaultExercises) { exercise in
                                    if !exercise.isLungTest {
                                        Text(exercise.name).tag(exercise)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Theme Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme")
                                .font(.headline)
                            
                            Picker("Theme", selection: $selectedTheme) {
                                ForEach(BreathingTheme.defaultThemes) { theme in
                                    Text(theme.name).tag(theme)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text(selectedTheme.mood)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        // Export Size
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export Size")
                                .font(.headline)
                            
                            Picker("Size", selection: $exportSize) {
                                ForEach(ExportSize.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("\(Int(exportSize.resolution.width)) Ã— \(Int(exportSize.resolution.height))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.headline)
                            
                            HStack {
                                Slider(value: $recordingDuration, in: 5...60, step: 5)
                                Text("\(Int(recordingDuration))s")
                                    .frame(width: 40)
                            }
                        }
                        
                        Divider()
                        
                        // Record Button
                        Button(action: {
                            startRecording()
                        }) {
                            HStack {
                                Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                                Text(isRecording ? "Recording..." : "Start Recording")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isRecording)
                        
                        // Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recording Tips")
                                .font(.headline)
                            
                            Text("â€¢ Video will be saved to temp folder")
                            Text("â€¢ Make sure you have enough disk space")
                            Text("â€¢ Higher resolutions take longer to render")
                            
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
                
                Divider()
                
                // Log Viewer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recording Log")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            logger.clear()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding([.horizontal, .top])
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                if logger.logs.isEmpty {
                                    Text("No logs yet. Start recording to see progress...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                } else {
                                    ForEach(logger.logs) { log in
                                        Text(log.formattedMessage)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(log.type.color)
                                            .textSelection(.enabled)
                                            .id(log.id)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                        .frame(height: 200)
                        .background(Color.black.opacity(0.05))
                        .onChange(of: logger.logs.count) { _ in
                            if let lastLog = logger.logs.last {
                                withAnimation {
                                    proxy.scrollTo(lastLog.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .frame(width: 350)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func startRecording() {
        isRecording = true
        logger.clear()
        logger.log("Starting recording process...", type: .info)
        
        let recorder = AnimationRecorder(logger: logger)
        recorder.recordAnimation(
            exercise: selectedExercise,
            duration: recordingDuration,
            size: exportSize.resolution,
            theme: selectedTheme
        ) { success, url in
            isRecording = false
            
            if success, let url = url {
                logger.log("Video saved to: \(url.path)", type: .success)
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            } else {
                logger.log("Recording failed", type: .error)
            }
        }
    }
}
