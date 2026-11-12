import SwiftUI
import SudokuKit

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StreakCard()
                    .onTapGesture { router.path.append(.streak) }
                DailyCard()
                if let saved = model.lastInProgress {
                    ContinueCard(saved: saved, others: model.inProgress.count - 1)
                }
                levels
                shortcuts
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(L("Sudokuno"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.path.append(.leaderboard) } label: {
                    Image(systemName: "trophy")
                }
                .accessibilityLabel(L("Classements Game Center"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.path.append(.settings) } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel(L("Réglages"))
            }
        }
    }

    private var levels: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Niveaux"))
                .font(.title3.weight(.bold))
                .padding(.horizontal, 4)
            ForEach(Level.allCases) { level in
                LevelRow(level: level) { level == .legende ? router.path.append(.legends) : start(level) }
                .accessibilityIdentifier("level-\(level.servicesLetter)")
            }
        }
        .padding(.top, 4)
    }

    private var shortcuts: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ShortcutButton(title: L("Bac à sable"), symbol: "square.and.pencil") { router.path.append(.creator) }
                ShortcutButton(title: L("Entrer un code"), symbol: "number") { router.path.append(.enterCode) }
            }
            GridRow {
                ShortcutButton(title: L("Mes grilles"), symbol: "square.grid.3x3.fill") { router.path.append(.myGrids) }
                ShortcutButton(title: L("Historique"), symbol: "clock.arrow.circlepath") { router.path.append(.history) }
            }
            GridRow {
                ShortcutButton(title: L("Statistiques"), symbol: "chart.bar.fill") { router.path.append(.stats) }
                    .gridCellColumns(2)
            }
        }
    }

    private func start(_ level: Level) {
        router.play { await model.newLevelGame(level) }
    }
}

// MARK: - Cartes

struct StreakCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let streak = model.state.streak
        let atRisk = streak.isAtRisk(today: model.today)
        HStack(spacing: 16) {
            FlameBadge(count: streak.current, dimmed: streak.current == 0 || atRisk)
            VStack(alignment: .leading, spacing: 4) {
                Text(streak.current == 0 ? L("Lance ta série") : L("%lld jours de série", streak.current))
                    .font(.headline)
                Text(subtitle(atRisk: atRisk, current: streak.current))
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                if streak.freezes > 0 {
                    Label(L("%lld gels de série", streak.freezes), systemImage: "snowflake")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.freeze)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .card()
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("streakCard")
        .accessibilityAddTraits(.isButton)
    }

    private func subtitle(atRisk: Bool, current: Int) -> String {
        if current == 0 { return L("Réussis le Sudoku du jour pour allumer la flamme.") }
        if atRisk { return L("Fais le Sudoku du jour pour la prolonger !") }
        return L("Bravo, la flamme est entretenue aujourd'hui.")
    }
}

struct FlameBadge: View {
    let count: Int
    var dimmed = false
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(dimmed ? AnyShapeStyle(Color.gray.opacity(0.18)) : AnyShapeStyle(Palette.flame.opacity(0.18)))
            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.5))
                .foregroundStyle(dimmed ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Palette.flame))
                .symbolEffect(.bounce, value: count)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct DailyCard: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        let today = model.today
        let level = DailySchedule.level(for: today)
        let result = model.dailyResult(today)
        let saved = model.savedDaily(today)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L("Sudoku du jour"), systemImage: "calendar")
                    .font(.headline)
                Spacer()
                LevelPill(level: level)
            }
            Text(today.date.formatted(Date.FormatStyle(date: .complete, time: .omitted, locale: L10n.locale, timeZone: .gmt)).capitalizedFirst)
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)

            if let result, result.onTime {
                HStack(spacing: 12) {
                    Label(L("Réussi en %@", TimeFormat.clock(result.seconds)), systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Palette.success)
                    Text(result.hints == 0 ? L("Sans indice") : "💡 \(result.hints)")
                        .foregroundStyle(Palette.secondaryText)
                }
                .font(.subheadline.weight(.semibold))
            }

            HStack {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    let remaining = max(0, Int(today.nextStart.timeIntervalSince(context.date)))
                    Text(L("Prochaine grille dans %1$lld h %2$02lld", remaining / 3600, (remaining % 3600) / 60))
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .monospacedDigit()
                }
                Spacer()
                if result?.onTime != true {
                    Button {
                        router.play { await model.dailyGame(for: today) }
                    } label: {
                        Text(saved == nil ? L("Jouer") : L("Continuer"))
                            .font(.headline)
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Palette.accentStrong)
                    .accessibilityIdentifier("dailyPlay")
                }
            }
        }
        .card()
    }
}

struct ContinueCard: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    let saved: SavedGame
    var others = 0

    var body: some View {
        Button {
            router.activeGame = model.resume(saved)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(saved.level.tint.opacity(0.18), in: .circle)
                    .foregroundStyle(saved.level.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Reprendre · %@", saved.title)).font(.headline)
                    Text(L("%lld/81 cases · %@", saved.values.filter { $0 != 0 }.count, TimeFormat.clock(saved.elapsed)))
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .monospacedDigit()
                    if others > 0 {
                        Text(L("+ %lld autres parties en cours", others))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}

struct LevelRow: View {
    @Environment(AppModel.self) private var model
    let level: Level
    let action: () -> Void

    var body: some View {
        let progress = model.state.progress
        let unlocked = progress.isUnlocked(level)
        let stats = model.state.stats[level]

        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: unlocked ? level.symbol : "lock.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background((unlocked ? level.tint : .gray).opacity(0.16), in: .rect(cornerRadius: 12))
                    .foregroundStyle(unlocked ? level.tint : .gray)
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.name).font(.headline)
                    if let lock = progress.unlockProgress(level), let previous = Level(rawValue: level.rawValue - 1) {
                        Text(L("%1$lld/%2$lld victoires en %3$@ pour débloquer", lock.done, lock.needed, previous.name))
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                        ProgressView(value: Double(lock.done), total: Double(lock.needed))
                            .tint(previous.tint)
                    } else {
                        Text(level.summary)
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
                Spacer(minLength: 8)
                if unlocked, let best = stats?.bestSeconds {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(TimeFormat.clock(best)).font(.subheadline.weight(.semibold)).monospacedDigit()
                        Text(L("record")).font(.caption2).foregroundStyle(Palette.secondaryText)
                    }
                }
            }
            .card()
        }
        .buttonStyle(.plain)
        .allowsHitTesting(unlocked)
        .accessibilityHint(unlocked ? L("Lance une nouvelle grille") : L("Niveau verrouillé"))
    }
}

struct LevelPill: View {
    let level: Level

    var body: some View {
        Text(level.name)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(level.tint.opacity(0.16), in: .capsule)
            .foregroundStyle(level.tint)
    }
}

struct ShortcutButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.title3)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .card()
        }
        .buttonStyle(.plain)
    }
}
