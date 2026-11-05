import SwiftUI

enum DayMateTheme {
    static let background = Color(red: 0.055, green: 0.047, blue: 0.135)
    static let surface = Color(red: 0.115, green: 0.102, blue: 0.255)
    static let surfaceLight = Color(red: 0.17, green: 0.15, blue: 0.35)
    static let purple = Color(red: 0.59, green: 0.35, blue: 0.99)
    static let lilac = Color(red: 0.75, green: 0.59, blue: 1.00)
    static let blue = Color(red: 0.54, green: 0.72, blue: 1.00)
    static let green = Color(red: 0.45, green: 0.91, blue: 0.62)
    static let secondary = Color(red: 0.73, green: 0.71, blue: 0.83)
    static let gradient = LinearGradient(
        colors: [Color(red: 0.65, green: 0.37, blue: 0.98),
                 Color(red: 0.72, green: 0.55, blue: 1.0),
                 Color(red: 0.52, green: 0.75, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing)
}

struct DayMateBackground: View {
    var body: some View {
        ZStack {
            DayMateTheme.background
            RadialGradient(colors: [DayMateTheme.purple.opacity(0.19), .clear],
                           center: .init(x: 0.85, y: 0.10),
                           startRadius: 20, endRadius: 420)
            RadialGradient(colors: [DayMateTheme.blue.opacity(0.07), .clear],
                           center: .init(x: 0.05, y: 0.75),
                           startRadius: 10, endRadius: 320)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Navigation transitions

enum HomeEntry: String { case study, plan }

/// Uses Apple's native matched zoom transition on iOS 18+, falling back to
/// NavigationStack's standard navigation animation on iOS 17.
struct DMHomeZoomSource: ViewModifier {
    let id: String
    let namespace: Namespace.ID

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

struct DMHomeZoomDestination: ViewModifier {
    let id: String
    let namespace: Namespace.ID

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

struct DMHomePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.68),
                       value: configuration.isPressed)
    }
}

/// Gentle purple -> blue radial wash while the destination screen opens.
/// Does not interfere with controls or scroll gestures.
struct DMGradientArrival: ViewModifier {
    @State private var finished = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    RadialGradient(
                        colors: [DayMateTheme.purple.opacity(0.35),
                                 DayMateTheme.blue.opacity(0.18), .clear],
                        center: .init(x: 0.5, y: 0.76),
                        startRadius: 8,
                        endRadius: max(proxy.size.width, proxy.size.height) * 0.85
                    )
                    .ignoresSafeArea()
                    .opacity(finished ? 0 : 1)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                finished = false
                withAnimation(.easeOut(duration: 0.72)) { finished = true }
            }
    }
}
