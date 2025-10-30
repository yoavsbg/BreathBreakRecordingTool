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
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(exportSize.resolution.width / exportSize.resolution.height, contentMode: .fit)
    }
    
    private var breathingExerciseView: some View {
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
                            lineWidth: 6
                        )
                        .shadow(color: phase.color.opacity(0.6), radius: 25)
                        .frame(width: 300, height: 300)
                    
                    // Soft inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    phase.color.opacity(0.25),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 180
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)
                    
                    // Moving glowing circle
                    ZStack {
                        Circle()
                            .fill(phase.color.opacity(0.3))
                            .blur(radius: 20)
                            .frame(width: 80, height: 80)
                            .offset(x: 150)
                            .rotationEffect(.degrees(rotation))
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: phase.color.opacity(0.8), radius: 20)
                            .offset(x: 150)
                            .rotationEffect(.degrees(rotation))
                    }
                    
                    // Phase indicator circles
                    GeometryReader { _ in
                        let pattern = patternComponents
                        
                        let inhaleStartAngle = 270.0
                        let holdStartAngle = 270.0 + (pattern.inhale / totalCycleDuration) * 360
                        let exhaleStartAngle = 270.0 + ((pattern.inhale + pattern.hold) / totalCycleDuration) * 360
                        
                        Group {
                            Circle()
                                .fill(phase == .inhale ? BreathingPhase.inhale.color : Color.white.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .position(
                                    x: 150 + 145 * cos(inhaleStartAngle * .pi / 180),
                                    y: 150 + 145 * sin(inhaleStartAngle * .pi / 180)
                                )
                            
                            Circle()
                                .fill(phase == .hold ? BreathingPhase.hold.color : Color.white.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .position(
                                    x: 150 + 145 * cos(holdStartAngle * .pi / 180),
                                    y: 150 + 145 * sin(holdStartAngle * .pi / 180)
                                )
                            
                            Circle()
                                .fill(phase == .exhale ? BreathingPhase.exhale.color : Color.white.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .position(
                                    x: 150 + 145 * cos(exhaleStartAngle * .pi / 180),
                                    y: 150 + 145 * sin(exhaleStartAngle * .pi / 180)
                                )
                        }
                    }
                    .frame(width: 300, height: 300)
                    
                    // Center text
                    VStack(spacing: 8) {
                        Text(phase.rawValue)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: phase.color.opacity(0.7), radius: 10)
                    }
                }
                
                Spacer()
            }
        }
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
}
