//
//  ExecuteCommandTool.swift
//  Martini
//
//  Created by Michael Kir on 26/03/2026.
//

//
//  ExecuteCommandTool.swift
//  Martini CLI
//

import Foundation
import FoundationModels

struct ExecuteCommandTool: Tool {
    let name = "ExecuteCommand"
    let description = "Proposes a command with a full definition of its effects."

    @Generable
    struct Arguments {
        @Guide(description: "The exact shell command to run.")
        var command: String
        
        @Guide(description: "A detailed breakdown of what this command and its specific flags do based on the documentation.")
        var definition: String
        
        @Guide(description: "Short summary of the overall goal.")
        var reasoning: String
    }

    func call(arguments: Arguments) async throws -> String {
        let isDangerous = checkSafety(arguments.command)
        
        // --- THE MARTINI PROPOSAL UI ---
        print("\n\u{1B}[1;35m" + String(repeating: "━", count: 50) + "\u{1B}[0m")
        
        if isDangerous {
            print("\u{1B}[1;31m⚠️  SAFETY WARNING: HIGH-RISK OPERATION DETECTED\u{1B}[0m")
        }
        
        print("\u{1B}[1m🎯 GOAL:\u{1B}[0m \(arguments.reasoning)")
        print("\u{1B}[1m📝 DEFINITION:\u{1B}[0m")
        // Indent the definition for better readability
        print(arguments.definition.components(separatedBy: "\n").map { "   \($0)" }.joined(separator: "\n"))
        
        print("\n\u{1B}[1m🚀 PROPOSED COMMAND:\u{1B}[0m")
        print("   \u{1B}[1;32m\(arguments.command)\u{1B}[0m")
        print("\u{1B}[1;35m" + String(repeating: "━", count: 50) + "\u{1B}[0m")
        
        // --- THE DECISION POINT ---
        print("Execute this command? (y/n): ", terminator: "")
        
        guard let response = readLine()?.lowercased(), response == "y" else {
            return "TASK_CANCELLED: The user explicitly declined this command. Stop your current plan and ask the user for a new request."
        }

        print("\n✨ Running...\n")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", arguments.command]
        
        // No pipe here: let the command output directly to the terminal
        try? process.run()
        process.waitUntilExit()
        
        // Update History
        HistoryManager.shared.add(
            intent: arguments.reasoning,
            command: arguments.command,
            result: "Success"
        )
        
        return "Command completed successfully."
    }

    private func checkSafety(_ command: String) -> Bool {
        let redFlags = ["rm ", "sudo ", "> /dev/", "format ", "dd ", "chmod -R 777"]
        return redFlags.contains { command.lowercased().contains($0) }
    }
}
