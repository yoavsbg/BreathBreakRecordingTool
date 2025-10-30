import SwiftUI

struct BreathingExercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let pattern: String
    let purpose: String
    let duration: String
    let colors: [CodableColor]
    var isFavorite: Bool
    let musicFileName: String?
    
    init(id: UUID = UUID(), name: String, pattern: String, purpose: String, duration: String, colors: [Color], isFavorite: Bool = false, musicFileName: String? = nil) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.purpose = purpose
        self.duration = duration
        self.colors = colors.map { CodableColor(color: $0) }
        self.isFavorite = isFavorite
        self.musicFileName = musicFileName
    }
    
    var isBoxBreathing: Bool {
        return pattern == "4-4-4-4"
    }
    
    var isLungTest: Bool {
        return name == "Lung Test"
    }
    
    var colorArray: [Color] {
        return colors.map { $0.color }
    }
    
    var textColor: Color {
        return Color(red: 0.1, green: 0.1, blue: 0.15)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BreathingExercise, rhs: BreathingExercise) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    init(color: Color) {
        #if os(macOS)
        let nsColor = NSColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        #else
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        #endif
    }
}

extension BreathingExercise {
    static let defaultExercises: [BreathingExercise] = [
        BreathingExercise(
            name: "Sleep Sync",
            pattern: "4-7-8",
            purpose: "Fall asleep faster",
            duration: "5 mins",
            colors: [Color(red: 0.75, green: 0.8, blue: 0.95), Color(red: 0.8, green: 0.75, blue: 0.9)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Equal Flow",
            pattern: "5-0-5",
            purpose: "Sharpen focus & clarity",
            duration: "4 mins",
            colors: [Color(red: 0.75, green: 0.85, blue: 0.95), Color(red: 0.8, green: 0.9, blue: 1.0)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Pre-Workout Boost",
            pattern: "2-0-4",
            purpose: "Energize before training",
            duration: "3 mins",
            colors: [Color(red: 0.75, green: 0.9, blue: 0.85), Color(red: 0.8, green: 0.95, blue: 0.9)],
            isFavorite: false,
            musicFileName: "eona-emotional-ambient-pop"
        ),
        
        BreathingExercise(
            name: "Post-Workout Reset",
            pattern: "4-2-6",
            purpose: "Cool down & lower stress",
            duration: "4 mins",
            colors: [Color(red: 0.8, green: 0.9, blue: 0.75), Color(red: 0.85, green: 0.95, blue: 0.8)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Stomach Release",
            pattern: "5-2-7",
            purpose: "Loosen tight belly & anxiety",
            duration: "4 mins",
            colors: [Color(red: 0.85, green: 0.75, blue: 0.9), Color(red: 0.9, green: 0.8, blue: 0.95)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Face Release",
            pattern: "4-2-4",
            purpose: "Ease jaw tension & relax expression",
            duration: "3 mins",
            colors: [Color(red: 0.75, green: 0.9, blue: 0.9), Color(red: 0.8, green: 0.95, blue: 0.95)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Zen Reset",
            pattern: "6-3-6",
            purpose: "Instant clarity in chaos",
            duration: "5 mins",
            colors: [Color(red: 0.95, green: 0.9, blue: 0.8), Color(red: 1.0, green: 0.95, blue: 0.85)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Panic Pause",
            pattern: "3-3-6",
            purpose: "Calm your racing mind fast",
            duration: "3 mins",
            colors: [Color(red: 0.8, green: 0.92, blue: 0.95), Color(red: 0.85, green: 0.95, blue: 1.0)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Morning Kickstart",
            pattern: "2-0-2",
            purpose: "Wake up & feel fresh",
            duration: "2 mins",
            colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Midday Reset",
            pattern: "4-2-4",
            purpose: "Break stress loops during the day",
            duration: "3 mins",
            colors: [Color(red: 0.8, green: 0.85, blue: 0.95), Color(red: 0.85, green: 0.9, blue: 1.0)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Main Character Energy",
            pattern: "4-2-6",
            purpose: "Breathe like you own the moment",
            duration: "3 mins",
            colors: [Color(red: 1.0, green: 0.8, blue: 0.75), Color(red: 0.75, green: 0.9, blue: 0.85)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Unclench Your Jaw",
            pattern: "5-2-7",
            purpose: "Release hidden tension (yes, there)",
            duration: "4 mins",
            colors: [Color(red: 0.75, green: 0.85, blue: 0.85), Color(red: 0.8, green: 0.9, blue: 0.9)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "No Thoughts Just Vibes",
            pattern: "6-3-6",
            purpose: "Quiet your brain & float",
            duration: "5 mins",
            colors: [Color(red: 0.95, green: 0.92, blue: 0.85), Color(red: 1.0, green: 0.95, blue: 0.9)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Anxiety? Never Heard of Her",
            pattern: "3-3-6",
            purpose: "Bye bye panic mode",
            duration: "3 mins",
            colors: [Color(red: 0.8, green: 0.9, blue: 0.95), Color(red: 0.85, green: 0.95, blue: 1.0)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        ),
        
        BreathingExercise(
            name: "Hot Girl Calm Down",
            pattern: "4-2-6",
            purpose: "Radiate peace, not chaos",
            duration: "4 mins",
            colors: [Color(red: 0.95, green: 0.8, blue: 0.85), Color(red: 1.0, green: 0.85, blue: 0.9)],
            isFavorite: false,
            musicFileName: "autumn-ambient"
        )
    ]
}
