import SwiftUI
import SudokuKit

struct StreakView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var monthOffset = 0

    /// Premier Sudoku du jour disponible.
    static let firstDay = DayStamp(year: 2026, month: 11, day: 1)!

    var body: some View {
        let streak = model.state.streak
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    FlameBadge(count: streak.current, dimmed: streak.current == 0, size: 110)
                    Text("\(streak.current)")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                    Text(L("Série en cours")).font(.headline).foregroundStyle(Palette.secondaryText)
                }
                .padding(.top, 8)

                HStack(spacing: 12) {
                    tile("\(streak.longest)", L("Record"), "trophy.fill", Palette.flameEnd)
                    tile("\(streak.freezes)/\(StreakState.maxFreezes)", L("Gels"), "snowflake", Palette.freeze)
                    tile("\(streak.completedDays.count)", L("Grilles du jour"), "calendar", Palette.accent)
                }

                Text(L("Tu gagnes un gel tous les %1$lld jours de série (%2$lld au maximum). Un gel protège ta série si tu oublies un jour.", StreakState.daysPerFreeze, StreakState.maxFreezes))
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                milestones
                calendar
            }
            .padding(16)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(L("Série"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(_ value: String, _ label: String, _ symbol: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(value).font(.title3.weight(.bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private var milestones: some View {
        let longest = model.state.streak.longest
        return VStack(alignment: .leading, spacing: 10) {
            Text(L("Jalons")).font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(StreakState.milestones, id: \.self) { m in
                        let reached = longest >= m
                        VStack(spacing: 4) {
                            Image(systemName: reached ? "flame.fill" : "flame")
                                .font(.title2)
                                .foregroundStyle(reached ? AnyShapeStyle(Palette.flame) : AnyShapeStyle(Color.gray))
                            Text(L("%lld j", m)).font(.caption.weight(.bold))
                        }
                        .frame(width: 64, height: 70)
                        .background(Palette.card, in: .rect(cornerRadius: 14))
                        .opacity(reached ? 1 : 0.6)
                        .accessibilityLabel(reached ? L("%lld jours, atteint", m) : L("%lld jours, pas encore atteint", m))
                    }
                }
            }
        }
    }

    // MARK: - Calendrier (jours UTC)

    private var calendar: some View {
        let today = model.today
        let (year, month) = shiftedMonth(today.components.year, today.components.month, by: monthOffset)
        let first = DayStamp(year: year, month: month, day: 1)!
        let daysInMonth = (28...31).last { DayStamp(year: year, month: month, day: $0) != nil }!
        let leading = first.weekday
        let monthName = first.date.formatted(Date.FormatStyle(locale: L10n.locale, timeZone: .gmt).month(.wide).year()).capitalizedFirst

        return VStack(spacing: 12) {
            HStack {
                Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left") }
                    .disabled(first <= Self.firstDay)
                Spacer()
                Text(monthName).font(.headline)
                Spacer()
                Button { monthOffset += 1 } label: { Image(systemName: "chevron.right") }
                    .disabled(monthOffset >= 0)
            }
            let symbols = Self.weekdaySymbols()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                // Identifiants distincts : en-têtes, cases vides et jours ne doivent pas se confondre.
                ForEach(0..<7, id: \.self) { k in
                    Text(symbols[k]).font(.caption.weight(.bold)).foregroundStyle(Palette.secondaryText).id("h\(k)")
                }
                ForEach(0..<leading, id: \.self) { k in Color.clear.frame(height: 40).id("b\(k)") }
                ForEach(1...daysInMonth, id: \.self) { d in
                    dayCell(DayStamp(year: year, month: month, day: d)!, today: today).id("d\(d)")
                }
            }
            Text(L("Touche un jour passé pour rejouer sa grille (sans effet sur la série)."))
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .card()
    }

    private func dayCell(_ day: DayStamp, today: DayStamp) -> some View {
        let streak = model.state.streak
        let done = streak.isCompleted(day)
        let frozen = streak.frozenDays.contains(day)
        let playable = day >= Self.firstDay && day <= today
        let n = day.components.day

        return Button {
            router.play { await model.dailyGame(for: day) }
        } label: {
            ZStack {
                if done {
                    Circle().fill(Palette.flame)
                } else if frozen {
                    Circle().fill(Palette.freeze.opacity(0.25))
                } else if day == today {
                    Circle().stroke(Palette.accent, lineWidth: 2)
                }
                if frozen && !done {
                    Image(systemName: "snowflake").font(.caption).foregroundStyle(Palette.freeze)
                } else {
                    Text("\(n)")
                        .font(.subheadline.weight(done ? .bold : .regular))
                        .foregroundStyle(done ? .white : (playable ? .primary : .secondary))
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(!playable)
        .accessibilityLabel(done ? L("%lld, réussi", n) : frozen ? L("%lld, gelé", n) : L("%lld, non joué", n))
    }

    /// Initiales des jours, du lundi au dimanche, dans la langue choisie.
    static func weekdaySymbols() -> [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = L10n.locale
        let s = cal.veryShortStandaloneWeekdaySymbols // commence par dimanche
        return Array(s[1...]) + [s[0]]
    }

    private func shiftedMonth(_ y: Int, _ m: Int, by offset: Int) -> (Int, Int) {
        let total = y * 12 + (m - 1) + offset
        return (total / 12, total % 12 + 1)
    }
}
