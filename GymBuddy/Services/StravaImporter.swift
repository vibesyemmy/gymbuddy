import Foundation

/// Reads activities of every type from the `activities.csv` file in a Strava bulk data export
/// (Strava → Settings → My Account → Download or Delete Your Account → Get Started → Request Your Archive).
enum StravaImporter {
    enum ImportError: LocalizedError {
        case missingColumns

        var errorDescription: String? {
            "This doesn't look like Strava's activities.csv. Unzip the export and choose the activities.csv file inside."
        }
    }

    /// Strava's run variants are all shown as "Run" so they match runs imported from Health.
    private static func label(for stravaType: String) -> String {
        switch stravaType {
        case "Trail Run", "Virtual Run": "Run"
        case "Weight Training": "Strength"
        case "": "Workout"
        default: stravaType
        }
    }

    static func runs(fromCSV text: String) throws -> [ImportedRun] {
        let rows = parseCSV(text)
        guard let header = rows.first else { throw ImportError.missingColumns }

        // The export repeats some headers ("Distance" in km, then again in metres; "Elapsed Time" twice),
        // and the later, unformatted columns are the ones in metres and seconds, so take the last match.
        func column(_ name: String) -> Int? { header.lastIndex(of: name) }
        guard let idIndex = column("Activity ID"),
              let dateIndex = column("Activity Date"),
              let typeIndex = column("Activity Type"),
              let distanceIndex = column("Distance"),
              let durationIndex = column("Moving Time") ?? column("Elapsed Time")
        else { throw ImportError.missingColumns }

        // Strava writes dates in UTC, e.g. "Oct 22, 2026, 7:30:00 AM".
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "MMM d, yyyy, h:mm:ss a"

        let needed = [idIndex, dateIndex, typeIndex, distanceIndex, durationIndex].max() ?? 0
        return rows.dropFirst().compactMap { row in
            guard row.count > needed,
                  let date = formatter.date(from: row[dateIndex].replacingOccurrences(of: "\u{202F}", with: " ")),
                  let seconds = Double(row[durationIndex]), seconds > 0
            else { return nil }
            // Activities without distance (gym sessions, yoga…) have an empty or zero distance.
            let meters = Double(row[distanceIndex]) ?? 0
            return ImportedRun(sourceID: "strava-\(row[idIndex])", activity: label(for: row[typeIndex]), date: date, distanceMeters: meters, duration: seconds)
        }
    }

    /// Minimal CSV parser: handles quoted fields containing commas, doubled quotes and newlines.
    private static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var chars = text.makeIterator()
        var pending = chars.next()

        while let c = pending {
            pending = chars.next()
            if inQuotes {
                if c == "\"" {
                    if pending == "\"" { field.append("\""); pending = chars.next() } else { inQuotes = false }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",": row.append(field); field = ""
                case "\n", "\r\n", "\r":
                    row.append(field); field = ""
                    if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
                    row = []
                default: field.append(c)
                }
            }
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}
