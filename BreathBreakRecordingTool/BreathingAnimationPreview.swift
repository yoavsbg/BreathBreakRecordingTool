import SwiftUI

struct BreathingAnimationPreview: View {
    let exercise: BreathingExercise
    let exportSize: ContentView.ExportSize
    
    @State private var rotation: Double = 0
    @State private var startTime: Date = Date()
    @State private var phase: BreathingPhase = .inhale
    @State private var currentPhaseDuration: Double = 0
    
    private var patternComponents: (inhale: Double, hold: Double, exhale: Double) {
        let parts = exercise.pattern.split(separator: "-").compactMap { Double($0) }
        guard parts.count == 3 else { return (4, 0, 4) }
        return (parts[0], parts[1], parts[2])
    }
    
    private var totalCycleDuration: Double {
        let pattern = patternComponents
        return pattern.inhale + pattern.hold + pattern.exhale
    }
    
    enum BreathingPhase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        
        var color: Color {
            switch self {
            case .inhale: return Color.blue
            case .hold: return Color.purple
            case .exhale: return Color.green
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.25),
                        Color(red: 0.02, green: 0.02, blue: 0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                breathingExerciseView
                    .overlay(
                        TimelineView(.animation(minimumInterval: 0.016)) { timeline in
                            Color.clear
                                .onChange(of: timeline.date) { _, _ in
                                    let elapsed = Date().timeIntervalSince(startTime)
                                    let cycleTime = elapsed.truncatingRemainder(dividingBy: totalCycleDuration)
                                    
                                    let pattern = patternComponents
                                    
                                    let cycleProgress = cycleTime / totalCycleDuration
                                    rotation = 270 + (cycleProgress * 360)
                                    
                                    let newPhase: BreathingPhase
                                    let phaseDuration: Double
                                    
                                    if cycleTime < pattern.inhale {
                                        newPhase = .inhale
                                        phaseDuration = pattern.inhale
                                    } else if cycleTime < pattern.inhale + pattern.hold {
                                        newPhase = .hold
                                        phaseDuration = pattern.hold
                                    } else {
                                        newPhase = .exhale
                                        phaseDuration = pattern.exhale
                                    }
                                    
                                    if newPhase != phase {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            phase = newPhase
                                        }
                                    }
                                    
                                    currentPhaseDuration = phaseDuration
                                }
                        }
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(exportSize.resolution.width / exportSize.resolution.height, contentMode: .fit)
    }
    
    private var breathingExerciseView: some View {
        GeometryReader { geometry in
            let minDimension = min(geometry.size.width, geometry.size.height)
            let scale = minDimension / 400 // Base scale on 400pt reference
            let circleSize = 300 * scale
            let lineWidth = 6 * scale
            let glowRadius = 25 * scale
            let blurRadius = 20 * scale
            let movingCircleSize = 80 * scale
            let movingCircleSmallSize = 40 * scale
            let movingCircleOffset = circleSize / 2
            let indicatorSize = 50 * scale
            let indicatorRadius = (circleSize / 2) - (indicatorSize / 2) - 5
            let fontSize = 24 * scale
            
            ZStack {
                VStack {
                    Spacer()
                    
                    ZStack {
                        // Main glowing ring
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        phase.color.opacity(0.7),
                                        Color.purple.opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: lineWidth
                            )
                            .shadow(color: phase.color.opacity(0.6), radius: glowRadius)
                            .frame(width: circleSize, height: circleSize)
                        
                        // Soft inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        phase.color.opacity(0.25),
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
                                .fill(phase.color.opacity(0.3))
                                .blur(radius: blurRadius)
                                .frame(width: movingCircleSize, height: movingCircleSize)
                                .offset(x: movingCircleOffset)
                                .rotationEffect(.degrees(rotation))
                            
                            Circle()
                                .fill(.white)
                                .frame(width: movingCircleSmallSize, height: movingCircleSmallSize)
                                .shadow(color: phase.color.opacity(0.8), radius: blurRadius)
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
                                    .fill(phase == .inhale ? BreathingPhase.inhale.color : Color.white.opacity(0.15))
                                    .frame(width: indicatorSize, height: indicatorSize)
                                    .offset(x: radius)
                                    .rotationEffect(.degrees(inhaleStartAngle))
                                
                                Circle()
                                    .fill(phase == .hold ? BreathingPhase.hold.color : Color.white.opacity(0.15))
                                    .frame(width: indicatorSize, height: indicatorSize)
                                    .offset(x: radius)
                                    .rotationEffect(.degrees(holdStartAngle))
                                
                                Circle()
                                    .fill(phase == .exhale ? BreathingPhase.exhale.color : Color.white.opacity(0.15))
                                    .frame(width: indicatorSize, height: indicatorSize)
                                    .offset(x: radius)
                                    .rotationEffect(.degrees(exhaleStartAngle))
                            }
                        }
                        .frame(width: circleSize, height: circleSize)
                        
                        // Center text
                        VStack(spacing: 8) {
                            Text(phase.rawValue)
                                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: phase.color.opacity(0.7), radius: 10 * scale)
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
