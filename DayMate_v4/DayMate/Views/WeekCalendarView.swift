import SwiftUI

/// Calendario orizzontale: titolo del mese sincronizzato con lo scroll.
/// Le frecce spostano la striscia di un mese senza cambiare il giorno selezionato.
struct WeekCalendarView: View {
    @ObservedObject var calendar: PlannerCalendarViewModel
    let onChooseDate: () -> Void

    @State private var visibleMonth = Date()

    private var visibleMonthTitle: String {
        visibleMonth.formatted(.dateTime.month(.wide).year())
    }

    private func startOfMonth(for date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }

    private func monthTarget(by amount: Int) -> Date? {
        let start = startOfMonth(for: visibleMonth)

        return Calendar.current.date(byAdding: .month, value: amount,to: start)
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Button {
                        if let target = monthTarget(by: -1) {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                proxy.scrollTo(target, anchor: .leading)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 38)
                    }
                    .accessibilityLabel("Previous month")

                    Spacer(minLength: 2)
                    Button(action: onChooseDate) {
                        HStack(spacing: 7) {
                            Text(visibleMonthTitle)
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Choose month and day")

                    Spacer(minLength: 2)
                    Button {
                        if let target = monthTarget(by: 1) {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                proxy.scrollTo(target, anchor: .leading)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 38)
                    }
                    .accessibilityLabel("Next month")

                    Button {
                        calendar.goToToday()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            proxy.scrollTo(calendar.selectedDay, anchor: .center)
                        }
                    } label: {
                        Text("Today")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 7)
                            .background(DayMateTheme.surfaceLight, in: Capsule())
                    }
                    .accessibilityLabel("Go to today")
                }
                .foregroundStyle(DayMateTheme.lilac)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 6) {
                        ForEach(calendar.timelineDates, id: \.self) { day in
                            let selected = calendar.isSelected(day)
                            Button {
                                calendar.select(day)
                            } label: {
                                VStack(spacing: 9) {
                                    Text(day.formatted(.dateTime.weekday(.narrow)))
                                        .font(.system(size: 13))
                                    Text(day.formatted(.dateTime.day()))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(selected ? DayMateTheme.background : .white)
                                .frame(width: 45, height: 67)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(selected ? AnyShapeStyle(DayMateTheme.gradient)
                                              : AnyShapeStyle(DayMateTheme.surface))
                                }
                            }
                            .buttonStyle(.plain)
                            .id(day)
                            .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 2)
                }
                // La UI si aggiorna SOLO al cambio del mese centrale.
                .onScrollGeometryChange(for: Date.self) { geometry in
                    let chipWidth: CGFloat = 45
                    let step: CGFloat = chipWidth + 6
                    let center = geometry.contentOffset.x + geometry.containerSize.width / 2
                    let index = Int(((center - chipWidth / 2) / step).rounded())
                    let safeIndex = min(max(index, 0), calendar.timelineDates.count - 1)
                    return startOfMonth(for: calendar.timelineDates[safeIndex])
                } action: { _, month in
                    if !Calendar.current.isDate(month, equalTo: visibleMonth, toGranularity: .month) {
                        visibleMonth = month
                    }
                }
                .onAppear {
                    visibleMonth = startOfMonth(for: calendar.selectedDay)
                    proxy.scrollTo(calendar.selectedDay, anchor: .center)
                }
                .onChange(of: calendar.selectedDay) { _, day in
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo(day, anchor: .center)
                    }
                }
                .onChange(of: calendar.timelineDates) { _, _ in
                    proxy.scrollTo(calendar.selectedDay, anchor: .center)
                }
                .accessibilityHint("Swipe to browse days; arrows move one month")
            }
        }
    }
}
