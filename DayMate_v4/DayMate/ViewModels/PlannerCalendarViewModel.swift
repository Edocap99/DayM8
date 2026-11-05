import Foundation
import Combine

/// Owns the selected date independently from the visible horizontal date strip.
/// Date selection, week arrows and the month picker all drive the same state.
@MainActor
final class PlannerCalendarViewModel: ObservableObject {
    @Published private(set) var selectedDay: Date
    @Published private(set) var weekStart: Date
    @Published private(set) var timelineDates: [Date]

    private let calendar: Calendar

    init(initialDate: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        let day = calendar.startOfDay(for: initialDate)
        selectedDay = day
        weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day
        timelineDates = Self.makeTimeline(around: day, using: calendar)
    }

    // A lazy scroll view can browse ten years of dates efficiently. If the
    // month picker jumps beyond this range, generate a new range around it.
    private static func makeTimeline(around day: Date, using calendar: Calendar) -> [Date] {
        let start = calendar.date(byAdding: .day, value: -1825, to: day) ?? day
        return (0...3650).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var monthTitle: String {
        selectedDay.formatted(.dateTime.month(.wide).year())
    }

    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDay)
    }

    func select(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        if let start = timelineDates.first, let end = timelineDates.last,
           (day < start || day > end) {
            timelineDates = Self.makeTimeline(around: day, using: calendar)
        }
        selectedDay = day
        weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day
    }

    func moveWeek(by amount: Int) {
        guard let date = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDay) else { return }
        select(date)
    }

    func goToToday() { select(.now) }
}
