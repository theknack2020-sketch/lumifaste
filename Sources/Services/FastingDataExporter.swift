import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Export fasting history as CSV — data stays local until user explicitly shares.
/// Includes mood, notes, water count, and paused duration.
struct FastingDataExporter {
    
    /// Generate CSV content from fasting sessions
    static func generateCSV(sessions: [FastingSession]) -> String {
        var csv = "Date,End Date,Plan,Duration (hours),Duration (minutes),Stage Reached,Completed,Mood,Water Count,Paused (minutes),Note\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let sorted = sessions.sorted { $0.startDate > $1.startDate }
        
        for session in sorted {
            let date = dateFormatter.string(from: session.startDate)
            let endDate = session.endDate.map { dateFormatter.string(from: $0) } ?? ""
            let plan = session.planType
            let hours = String(format: "%.2f", session.actualDuration / 3600)
            let minutes = String(format: "%.0f", session.actualDuration / 60)
            let stage = session.stageReached
            let completed = session.isCompleted ? "Yes" : "No"
            let mood = session.mood ?? ""
            let water = "\(session.waterCount)"
            let paused = String(format: "%.0f", session.totalPausedDuration / 60)
            let note = (session.note ?? "").replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
            
            csv += "\(date),\(endDate),\(plan),\(hours),\(minutes),\(stage),\(completed),\(mood),\(water),\(paused),\"\(note)\"\n"
        }
        
        return csv
    }
    
    /// Write CSV to a temporary file and return the URL for sharing
    static func exportToFile(sessions: [FastingSession]) -> URL? {
        let csv = generateCSV(sessions: sessions)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date.now)
        
        let fileName = "Lumifaste-Export-\(dateString).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
}
