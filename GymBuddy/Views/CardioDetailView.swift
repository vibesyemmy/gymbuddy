import SwiftUI

/// Details for a walk/run session. Pick intervals (a mix of both), a free walk or a free run, then start.
/// Walks and runs count the same toward the weekly goal.
struct CardioDetailView: View {
    let week: RunWeek
    @Binding var mode: CardioMode
    let onStart: (CardioMode) -> Void

    var body: some View {
        ThemedScroll {
            Card {
                SectionLabel("Walk / run")
                Picker("Type", selection: $mode) {
                    ForEach(CardioMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .intervals:
                    Text(week.title).font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text("Week \(week.number) · about \(week.totalMinutes) min")
                        .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    tip("Run at a pace where you could still hold a conversation. Walk intervals are part of the plan, not a failure.")
                case .walk, .run:
                    Text("Free \(mode.title.lowercased())").font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text("Go at your own pace for as long as you like")
                        .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    tip("Time and distance are tracked by GPS. Pause whenever you need to, and tap stop when you're done to save it.")
                }
            }

            if mode == .intervals {
                Card {
                    SectionLabel("Your session")
                    let segments = week.segments
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: segment.phase == .run ? "figure.run" : "figure.walk")
                                    .foregroundStyle(segment.phase == .run ? Theme.mint : Theme.blue)
                                    .frame(width: 28)
                                Text(segment.phase.label)
                                    .font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(Format.clock(segment.duration))
                                    .font(.system(size: 15)).monospacedDigit().foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.vertical, 10)
                            if index < segments.count - 1 { Divider().overlay(Theme.divider) }
                        }
                    }
                }
            }

            Text("Run, walk or a mix: they all count toward your 3 sessions a week.")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
        .navigationTitle("Walk / run")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(title: "Start", icon: "play.fill") { onStart(mode) }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                .background(.ultraThinMaterial)
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.tile, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
    }
}
