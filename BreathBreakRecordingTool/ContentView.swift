import SwiftUI

struct ContentView: View {
    @State private var selectedExercise: BreathingExercise = BreathingExercise.defaultExercises[0]
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 10.0
    @State private var exportSize: ExportSize = .instagram1080
    
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
                
                BreathingAnimationPreview(exercise: selectedExercise, exportSize: exportSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            }
            .frame(minWidth: 400)
            
            Divider()
            
            // Controls Panel
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
                        
                        Text("\(Int(exportSize.resolution.width)) × \(Int(exportSize.resolution.height))")
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
                        
                        Text("• Video will be saved to your Desktop")
                        Text("• Make sure you have enough disk space")
                        Text("• Higher resolutions take longer to render")
                        
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .frame(width: 300)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func startRecording() {
        isRecording = true
        
        let recorder = AnimationRecorder()
        recorder.recordAnimation(
            exercise: selectedExercise,
            duration: recordingDuration,
            size: exportSize.resolution
        ) { success, url in
            isRecording = false
            
            if success, let url = url {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                print("✅ Video saved to: \(url.path)")
            } else {
                print("❌ Recording failed")
            }
        }
    }
}
