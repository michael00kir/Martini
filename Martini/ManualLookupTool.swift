//
//  ManualLookupTool.swift
//  Martini
//
//  Created by Michael Kir on 26/03/2026.
//

import Foundation
import FoundationModels

struct ManualLookupTool: Tool {
    let name = "ManualLookup"
    let description = "Research CLI tools to answer questions, compare syntax, or understand flags. Returns documentation for analysis."

    @Generable
    struct Arguments {
        @Guide(description: "The CLI tool(s) to research (e.g., 'git', 'ls vs du')")
        var toolName: String
        
        @Guide(description: "The specific question or comparison the user wants to understand.")
        var query: String?
    }

    func call(arguments: Arguments) async throws -> String {
        // Handle multiple tools if the user is comparing (e.g., "ls vs exa")
        let tools = arguments.toolName.components(separatedBy: " vs ")
        var fullDocumentation = ""

        print("\n🔍 \u{1B}[33m[Martini is researching: \(arguments.toolName)...]\u{1B}[0m")

        for tool in tools {
            let cleanedTool = tool.trimmingCharacters(in: .whitespaces)
            // Fetch the man page or help text
            let command = "/usr/bin/man -P cat \(cleanedTool) | /usr/bin/col -b || \(cleanedTool) --help"
            
            let output = try await executeSearch(command: command)
            fullDocumentation += "--- Documentation for \(cleanedTool) ---\n\(output)\n\n"
        }

        if fullDocumentation.isEmpty || fullDocumentation.contains("No documentation found") {
            return "ERROR: Could not find documentation for \(arguments.toolName)."
        }

        // We return the raw text to the Language Model.
        // The Model will then use its 'Instructions' to synthesize an answer for the user.
        return "RESEARCH_RESULTS:\n\(fullDocumentation)\n\nUSER_QUERY: \(arguments.query ?? "General overview")"
    }

    private func executeSearch(command: String) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        return String(data: data, encoding: .utf8) ?? ""
    }
}
