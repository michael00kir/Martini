//
//  FileSystemManager.swift
//  Martini
//
//  Created by Michael Kir on 21/04/2026.
//


import Foundation
import FoundationModels

struct FileSystemManager: Tool {
    let name = "FileSystemManager"
    let description = "Comprehensive file system orchestrator: list contents with metadata, move between directories, and find files recursively."

    @Generable
    struct Arguments {
        @Guide(description: "Action: 'list' (ls), 'where' (pwd), 'move' (cd), or 'find' (search).")
        var action: String
        
        @Guide(description: "Target path for 'list'/'move', or the filename/pattern for 'find'.")
        var target: String?
        
        @Guide(description: "Reason for the action (required for 'move' or 'find').")
        var reasoning: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        
        switch arguments.action.lowercased() {
        case "where":
            return "Current Directory: \(currentDir)"
            
        case "list":
            let targetPath = arguments.target ?? "."
            let expandedPath = NSString(string: targetPath).expandingTildeInPath
            
            do {
                let items = try fileManager.contentsOfDirectory(atPath: expandedPath)
                if items.isEmpty { return "Contents of \(targetPath): [Empty Directory]" }
                
                var output = "Contents of \(targetPath):\n"
                for item in items {
                    let fullPath = (expandedPath as NSString).appendingPathComponent(item)
                    var isDir: ObjCBool = false
                    fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                    
                    let attributes = try? fileManager.attributesOfItem(atPath: fullPath)
                    let size = attributes?[.size] as? Int64 ?? 0
                    let typeIndicator = isDir.boolValue ? "📁 " : "📄 "
                    
                    output += "\(typeIndicator) \(item.padding(toLength: 30, withPad: " ", startingAt: 0)) (\(size) bytes)\n"
                }
                return output
            } catch {
                return "ERROR: Could not list directory: \(error.localizedDescription)"
            }
            
        case "move":
            guard let path = arguments.target else { return "ERROR: Path required for 'move'." }
            let expandedPath = NSString(string: path).expandingTildeInPath
            
            // Safety Check: Prevent moving into sensitive system root areas
            let restrictedPaths = ["/System", "/private", "/var/db"]
            if restrictedPaths.contains(where: { expandedPath.hasPrefix($0) }) {
                return "ERROR: Access to system-critical path '\(path)' is restricted for safety."
            }

            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: expandedPath, isDirectory: &isDirectory), isDirectory.boolValue {
                fileManager.changeCurrentDirectoryPath(expandedPath)
                return "SUCCESS: Context moved. Martini is now operating in: \(fileManager.currentDirectoryPath)"
            } else {
                return "ERROR: Path '\(path)' does not exist or is not a directory."
            }
            
        case "find":
            guard let pattern = arguments.target else { return "ERROR: Search pattern required." }
            return try await performRecursiveSearch(pattern: pattern, startDir: currentDir)
            
        default:
            return "ERROR: Unknown action '\(arguments.action)'. Use 'list', 'where', 'move', or 'find'."
        }
    }

    private func performRecursiveSearch(pattern: String, startDir: String) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/find")
        // Limits depth to 4 for performance and to avoid infinite recursion in deep trees
        process.arguments = [startDir, "-maxdepth", "4", "-name", "*\(pattern)*"]
        process.standardOutput = pipe
        
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.isEmpty ? "No files matching '\(pattern)' found." : "Search results:\n\(output)"
    }
}