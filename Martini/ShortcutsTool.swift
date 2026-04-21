//
//  ShortcutsTool.swift
//  Martini
//
//  Created by Michael Kir on 20/04/2026.
//


import Foundation
import FoundationModels

struct ShortcutsTool: Tool {
    let name = "ShortcutsManager"
    let description = "Lists or runs Apple Shortcuts to perform system-level automation."

    @Generable
    struct Arguments {
        @Guide(description: "Action to take: 'list' to see available shortcuts, or 'run' to execute one.")
        var action: String
        
        @Guide(description: "The name of the shortcut (required for 'run').")
        var shortcutName: String?
        
        @Guide(description: "Optional input text to pass to the shortcut.")
        var input: String?
    }

    func call(arguments: Arguments) async throws -> String {
        switch arguments.action.lowercased() {
        case "list":
            return try await executeShell("shortcuts list")
        case "run":
            guard let name = arguments.shortcutName else { return "ERROR: Shortcut name required." }
            let command = arguments.input != nil 
                ? "echo \"\(arguments.input!)\" | shortcuts run \"\(name)\"" 
                : "shortcuts run \"\(name)\""
            return try await executeShell(command)
        default:
            return "ERROR: Unknown action '\(arguments.action)'."
        }
    }

    private func executeShell(_ command: String) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        return String(data: data, encoding: .utf8) ?? "Success (No output)"
    }
}
