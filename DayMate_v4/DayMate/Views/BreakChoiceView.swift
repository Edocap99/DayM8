import SwiftUI

struct BreakChoiceView: View {
    @EnvironmentObject private var store: DayMateStore
    let onHome: () -> Void
    let onStart: (BreakActivity) -> Void
    @State private var selected: BreakActivity = .walk

    var body: some View {
        ZStack {
            DayMateBackground()
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    Button("‹ Home", action: onHome)
                        .font(.system(size: 14))
                        .foregroundStyle(DayMateTheme.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Break time").font(.system(size: 30, weight: .bold))
                    Text("10 minutes, away from the screen")
                        .foregroundStyle(DayMateTheme.secondary)
                        .font(.system(size: 14))
                }
                DMCard {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("STEP DONE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DayMateTheme.green)

                            Text("Nice work!")
                                .font(.system(size: 25, weight: .bold))
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)

                            Text(store.snapshot.lastCompletedStep ?? "Take a moment for yourself")
                                .font(.system(size: 13))
                                .foregroundStyle(DayMateTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image("MascotStepDone")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .fixedSize()
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 12) {
                    DMSectionLabel(title: "Pick one")
                    DMCard(padding: 4) {
                        VStack(spacing: 0) {
                            ForEach(BreakActivity.allCases) { activity in
                                Button { selected = activity } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: activity.symbol)
                                            .font(.system(size: 20))
                                            .foregroundStyle(DayMateTheme.lilac)
                                            .frame(width: 39, height: 39)
                                            .background(DayMateTheme.surfaceLight,
                                                        in: RoundedRectangle(cornerRadius: 12))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(activity.rawValue).font(.system(size: 15, weight: .semibold))
                                            Text(activity.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundStyle(DayMateTheme.secondary)
                                        }
                                        Spacer()
                                        DMStepCheck(isDone: selected == activity)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 72)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Spacer()
                DMButton(title: "Start my break") { onStart(selected) }
                    .padding(.bottom, 25)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

