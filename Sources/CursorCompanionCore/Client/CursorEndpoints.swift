import Foundation

/// Endpunkt-Definitionen der Cursor-API
public enum CursorEndpoints: Sendable {
    public static let clientID = "KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB"

    public static let oauthTokenURL = URL(string: "https://api2.cursor.sh/oauth/token")!
    public static let currentPeriodUsageURL = URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage")!
    public static let planInfoURL = URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetPlanInfo")!

    public static let usageSummaryURL = URL(string: "https://cursor.com/api/usage-summary")!
    public static func requestUsageURL(userID: String) -> URL {
        return URL(string: "https://cursor.com/api/usage?user=\(userID)")!
    }
    public static let stripeURL = URL(string: "https://cursor.com/api/auth/stripe")!
}
