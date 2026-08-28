import Foundation

/// Snapshot der Cursor-Nutzungswerte eines Accounts
public struct UsageSnapshot: Sendable, Codable, Equatable {
    public var cursorModelsPercent: Double?
    public var otherModelsPercent: Double?
    public var totalPercent: Double?
    public var cycleStart: Date?
    public var cycleEnd: Date?
    public var creditsRemaining: Double?
    public var requestsUsed: Int?
    public var requestsLimit: Int?
    public var lastUpdated: Date

    public init(
        cursorModelsPercent: Double? = nil,
        otherModelsPercent: Double? = nil,
        totalPercent: Double? = nil,
        cycleStart: Date? = nil,
        cycleEnd: Date? = nil,
        creditsRemaining: Double? = nil,
        requestsUsed: Int? = nil,
        requestsLimit: Int? = nil,
        lastUpdated: Date = Date()
    ) {
        self.cursorModelsPercent = cursorModelsPercent
        self.otherModelsPercent = otherModelsPercent
        self.totalPercent = totalPercent
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.creditsRemaining = creditsRemaining
        self.requestsUsed = requestsUsed
        self.requestsLimit = requestsLimit
        self.lastUpdated = lastUpdated
    }
}

/// Status eines Cursor-Accounts
public enum AccountStatus: Sendable, Codable, Equatable {
    case loading
    case ok
    case loginRequired
    case error(String)
}

/// Domain-Modell eines Cursor-Accounts
public struct CursorAccount: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public var label: String
    public var isActive: Bool
    public var plan: String?
    public var snapshot: UsageSnapshot?
    public var status: AccountStatus
    public var lastSeen: Date

    public init(
        id: String,
        label: String,
        isActive: Bool,
        plan: String? = nil,
        snapshot: UsageSnapshot? = nil,
        status: AccountStatus = .ok,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.isActive = isActive
        self.plan = plan
        self.snapshot = snapshot
        self.status = status
        self.lastSeen = lastSeen
    }
}

/// Authentifizierungs-Tokens für Keychain-Speicherung
public struct AuthTokens: Sendable, Codable, Equatable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

/// Unverarbeitete Auth-Rohdaten aus SQLite oder Keychain
public struct RawAuthData: Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let membershipType: String?

    public init(accessToken: String, refreshToken: String, membershipType: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.membershipType = membershipType
    }
}

/// Benutzereinstellungen
public struct UserSettings: Sendable, Codable, Equatable {
    public var refreshIntervalMinutes: Int
    public var launchAtLogin: Bool
    public var menubarDisplayMode: MenubarDisplayMode

    public enum MenubarDisplayMode: String, Sendable, Codable, CaseIterable {
        case textWithDots = "textWithDots"
        case dualMiniBars = "dualMiniBars"
        case singleMetric = "singleMetric"
    }

    public init(
        refreshIntervalMinutes: Int = 5,
        launchAtLogin: Bool = false,
        menubarDisplayMode: MenubarDisplayMode = .textWithDots
    ) {
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.launchAtLogin = launchAtLogin
        self.menubarDisplayMode = menubarDisplayMode
    }
}
