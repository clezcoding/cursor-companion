import Foundation

/// Parst die JSON-Antworten der Cursor API in Domain-Modelle
public enum CursorUsageMapper: Sendable {
    public enum MappingError: Error, Equatable {
        case invalidFormat
        case noUsableData
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        
        let formatterFractional = ISO8601DateFormatter()
        formatterFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterFractional.date(from: string) {
            return date
        }

        let formatterStandard = ISO8601DateFormatter()
        formatterStandard.formatOptions = [.withInternetDateTime]
        return formatterStandard.date(from: string)
    }

    private static func extractDouble(_ val: Any?) -> Double? {
        if let d = val as? Double { return d }
        if let i = val as? Int { return Double(i) }
        if let n = val as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func extractInt(_ val: Any?) -> Int? {
        if let i = val as? Int { return i }
        if let d = val as? Double { return Int(d) }
        if let n = val as? NSNumber { return n.intValue }
        return nil
    }

    /// Mappt das JSON von GET https://cursor.com/api/usage-summary
    public static func mapSummary(_ json: [String: Any]) throws -> UsageSnapshot {
        let individualUsage = json["individualUsage"] as? [String: Any]
        let plan = individualUsage?["plan"] as? [String: Any]

        let cursorPercent = extractDouble(plan?["autoPercentUsed"])
        let otherPercent = extractDouble(plan?["apiPercentUsed"])
        let totalPercent = extractDouble(plan?["totalPercentUsed"])

        let cycleStart = parseDate(json["billingCycleStart"] as? String)
        let cycleEnd = parseDate(json["billingCycleEnd"] as? String)
        let creditsRemaining = extractDouble(json["creditsRemaining"] ?? individualUsage?["creditsRemaining"])

        return UsageSnapshot(
            cursorModelsPercent: cursorPercent,
            otherModelsPercent: otherPercent,
            totalPercent: totalPercent,
            cycleStart: cycleStart,
            cycleEnd: cycleEnd,
            creditsRemaining: creditsRemaining,
            requestsUsed: nil,
            requestsLimit: nil,
            lastUpdated: Date()
        )
    }

    /// Mappt das JSON von GET https://cursor.com/api/usage?user=<id> (Request-basierter Fallback)
    public static func mapRequestUsage(_ json: [String: Any]) throws -> (used: Int, limit: Int, breakdown: [String: ModelUsage]) {
        var totalUsed = 0
        var totalLimit = 0
        var foundAny = false
        var breakdown: [String: ModelUsage] = [:]

        for (key, value) in json {
            if let dict = value as? [String: Any] {
                let used = extractInt(dict["numRequests"]) ?? extractInt(dict["numRequestsTotal"])
                let limit = extractInt(dict["maxRequestUsage"])
                if let u = used, let l = limit {
                    totalUsed += u
                    totalLimit += l
                    foundAny = true
                    breakdown[key] = ModelUsage(used: u, limit: l)
                }
            }
        }

        if !foundAny {
            if let used = extractInt(json["numRequests"]) ?? extractInt(json["numRequestsTotal"]),
               let limit = extractInt(json["maxRequestUsage"]) {
                return (used: used, limit: limit, breakdown: [:])
            }
            throw MappingError.invalidFormat
        }

        return (used: totalUsed, limit: totalLimit, breakdown: breakdown)
    }
}
