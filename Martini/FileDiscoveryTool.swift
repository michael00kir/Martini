//
//  FileDiscoveryTool.swift
//  Martini
//
//  Created by Michael Kir on 07/04/2026.
//


import Foundation
import FoundationModels

struct FileDiscoveryTool: Tool {
    let name = "FileDiscovery"
    let description = "Lists files, finds specific items, or shows the current path."

    @Generable
    struct Arguments {
        @Guide(description: "The action to perform: 'list' (ls), 'find' (search), or 'where' (pwd)")
        var action: String
        @Guide(description: "Optional: Search term or specific subdirectory.")
        var target: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let currentDir = FileManager.default.currentDirectoryPath
        
        switch arguments.action.lowercased() {
        case "where":
            return "Current Directory: \(currentDir)"
            
        case "list":
            let path = arguments.target ?? "."
            let items = try? FileManager.default.contentsOfDirectory(atPath: path)
            return "Contents of \(path):\n" + (items?.joined(separator: "\n") ?? "Empty")
            
        case "find":
            guard let target = arguments.target else { return "ERROR: Search target required." }
            let command = "find . -name '*\(target)*' -maxdepth 3"
            // Reuse logic from ManualLookup to run this shell command...
            return "Search results for '\(target)':\n [Results would appear here]"
            
        default:
            return "ERROR: Unknown discovery action."
        }
    }
}