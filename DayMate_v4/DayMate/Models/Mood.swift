import Foundation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case ready = "Ready"
    case tired = "Tired"
    case stressed = "Stressed"
    case stuck = "Stuck"

    var id: Self { self }

    // Names of the four images already imported into Assets.xcassets.
    var iconName: String {
        switch self {
        case .ready: return "mood_ready"
        case .tired: return "mood_tired"
        case .stressed: return "mood_stressed"
        case .stuck: return "mood_stuck"
        }
    }

    var subtitle: String {
        switch self {
        case .ready: return "Full step, 25 min"
        case .tired: return "Shorter step, 10 min"
        case .stressed: return "Start with a break"
        case .stuck: return "Easier start, 5 min"
        }
    }

    var durationMinutes: Int {
        switch self {
        case .ready: return 25
        case .tired: return 10
        case .stressed: return 0
        case .stuck: return 5
        }
    }
}

enum BreakActivity: String, CaseIterable, Identifiable, Hashable {
    case walk = "Short walk"
    case stretch = "Stretch & breathe"
    case water = "Snack & water"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .walk: return "figure.walk"
        case .stretch: return "wind"
        case .water: return "cup.and.saucer"
        }
    }

    var subtitle: String {
        switch self {
        case .walk: return "Go outside, 10 min"
        case .stretch: return "4 easy moves"
        case .water: return "Refill your bottle"
        }
    }

    var minutes: Int {
        switch self {
        case .walk: return 10
        case .stretch: return 4
        case .water: return 5
        }
    }
}
