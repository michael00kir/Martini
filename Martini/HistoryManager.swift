//
//  HistoryManager.swift
//  Martini
//
//  Created by Michael Kir on 26/03/2026.
//


import Foundation

struct HistoryEntry {
    let timestamp: Date
    let userIntent: String
    let commandExecuted: String
    let result: String
}

class HistoryManager {
    static let shared = HistoryManager()
    private var entries: [HistoryEntry] = []
    
    func add(intent: String, command: String, result: String) {
        let entry = HistoryEntry(timestamp: Date(), userIntent: intent, commandExecuted: command, result: result)
        entries.append(entry)
        
        // Keep only the last 5 entries to avoid overwhelming the AI context
        if entries.count > 5 { entries.removeFirst() }
    }
    
    func getHistorySummary() -> String {
        if entries.isEmpty { return "No commands have been executed yet in this session." }
        
        return entries.map { entry in
            "- [\(entry.timestamp.formatted(date: .omitted, time: .shortened))] User wanted: \(entry.userIntent) -> Executed: `\(entry.commandExecuted)` (Result: \(entry.result))"
        }.joined(separator: "\n")
    }
}
