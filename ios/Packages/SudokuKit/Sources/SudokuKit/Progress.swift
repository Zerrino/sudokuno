/// Série à la Duolingo, fondée sur la grille du jour (jours UTC).
public struct StreakState: Codable, Hashable, Sendable {
    public private(set) var current = 0
    public private(set) var longest = 0
    public private(set) var freezes = 0
    /// Dernier jour couvert (grille du jour réussie, ou jour protégé par un gel).
    public private(set) var coveredThrough: DayStamp?
    public private(set) var completedDays: Set<DayStamp> = []
    public private(set) var frozenDays: Set<DayStamp> = []

    public static let maxFreezes = 2
    public static let daysPerFreeze = 7
    public static let milestones = [3, 7, 14, 30, 50, 100, 365]

    public init() {}

    public enum Event: Hashable, Sendable {
        case freezesUsed(Int)
        case reset
    }

    /// À appeler au lancement et avant tout affichage : consomme les gels pour les jours manqués
    /// ou remet la série à zéro. Idempotent.
    @discardableResult
    public mutating func refresh(today: DayStamp) -> Event? {
        guard let covered = coveredThrough, current > 0 else { return nil }
        let missed = today.dayNumber - covered.dayNumber - 1
        guard missed > 0 else { return nil }
        if missed <= freezes {
            freezes -= missed
            for k in 1...missed { frozenDays.insert(covered.adding(days: k)) }
            coveredThrough = today.adding(days: -1)
            return .freezesUsed(missed)
        }
        current = 0
        return .reset
    }

    /// Grille du jour `day` réussie le jour même. Retourne le jalon atteint, s'il y en a un.
    @discardableResult
    public mutating func recordCompletion(day: DayStamp) -> Int? {
        refresh(today: day)
        if let covered = coveredThrough, covered >= day {
            completedDays.insert(day)
            return nil
        }
        if let covered = coveredThrough, covered.dayNumber == day.dayNumber - 1, current > 0 {
            current += 1
        } else {
            current = 1
        }
        coveredThrough = day
        completedDays.insert(day)
        longest = max(longest, current)
        if current % Self.daysPerFreeze == 0 && freezes < Self.maxFreezes {
            freezes += 1
        }
        return Self.milestones.contains(current) ? current : nil
    }

    /// La série n'est pas encore prolongée aujourd'hui (pour l'affichage « en danger »).
    public func isAtRisk(today: DayStamp) -> Bool {
        current > 0 && coveredThrough != today
    }

    public func isCompleted(_ day: DayStamp) -> Bool { completedDays.contains(day) }
}

/// Progression des niveaux : déblocage après N victoires au niveau précédent.
public struct LevelProgress: Codable, Hashable, Sendable {
    public private(set) var wins: [Level: Int] = [:]

    public init() {}

    /// Victoires nécessaires au niveau précédent pour débloquer un niveau.
    public static func requirement(for level: Level) -> Int {
        switch level {
        case .facile: 0
        case .moyen: 5
        case .difficile, .expert, .diabolique: 10
        }
    }

    public func winCount(_ level: Level) -> Int { wins[level, default: 0] }

    public func isUnlocked(_ level: Level) -> Bool {
        guard let previous = Level(rawValue: level.rawValue - 1) else { return true }
        return isUnlocked(previous) && winCount(previous) >= Self.requirement(for: level)
    }

    /// (victoires au niveau précédent, victoires requises) pour un niveau verrouillé.
    public func unlockProgress(_ level: Level) -> (done: Int, needed: Int)? {
        guard !isUnlocked(level), let previous = Level(rawValue: level.rawValue - 1) else { return nil }
        return (min(winCount(previous), Self.requirement(for: level)), Self.requirement(for: level))
    }

    /// Enregistre une victoire. Retourne le niveau nouvellement débloqué, s'il y en a un.
    @discardableResult
    public mutating func recordWin(_ level: Level) -> Level? {
        let before = Level.allCases.filter(isUnlocked)
        wins[level, default: 0] += 1
        return Level.allCases.first { isUnlocked($0) && !before.contains($0) }
    }
}
