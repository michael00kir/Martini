//  main.swift
//  Martini
//
//  Created by Michael Kir on 13/03/2026.

import Foundation
import FoundationModels
import ArgumentParser
import System

// 1. Structure the response for Apple Intelligence
@Generable(description: "A structured response from the Martini orchestrator.")
struct MartiniResponse {
    enum TaskStatus: String, Codable {
        case researching, proposing, executing, finished, error
    }
    
    @Guide(description: "A friendly, concise acknowledgment of the user's request.")
    var message: String

    @Guide(description: "A step-by-step breakdown of what the AI is about to do.")
    var plan: [String]

    @Guide(description: "Set to true if the task is finished or cannot be completed.")
    var isTaskComplete: Bool
    
    @Guide(description: "An optional suggestion for the user's next command.")
    var suggestion: String?
}

@main
struct Martini: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A professional TTY-integrated CLI orchestrator.",
        version: "1.1.0"
    )

    func run() async throws {
        // --- TTY REFURBISHMENT: SIGNAL HANDLING ---
        // We ignore SIGINT (Ctrl+C) in the main process so that it can be
        // forwarded to child processes in ExecuteCommandTool instead of
        // killing the Martini session.
        signal(SIGINT, SIG_IGN)

        print("\u{1B}[1;35m🍸 Martini High-Fidelity TTY Mode Active.\u{1B}[0m")
        print("------------------------------------------------------------")

        let status = checkModelStatus()
        print(status.message)

        if !status.isReady {
            print("Martini requires Apple Intelligence to function. Exiting...")
            throw ExitCode.failure
        }

        // 2. Initial Session Setup
        let options = GenerationOptions(sampling: .greedy)
        let toolset: [any Tool] = [
            ManualLookupTool(),
            ExecuteCommandTool(), // Now uses PTY/forkpty
            FileSystemManager()
        ]

        var session = LanguageModelSession(
            tools: toolset,
            instructions: Martini.generateInstructions(history: "Session Started")
        )

        // 3. The REPL Loop
        while true {
            // --- TTY REFURBISHMENT: DYNAMIC PROMPT ---
            // Show the current working directory (CWD) in the prompt.
            let rawCwd = FileManager.default.currentDirectoryPath
            let displayPath = rawCwd.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            
            print("\n\u{1B}[1;34m\(displayPath)\u{1B}[0m Martini> ", terminator: "")
            
            guard let input = readLine(), !input.isEmpty else { continue }
            if ["exit", "quit"].contains(input.lowercased()) { break }

            do {
                // 4. Respond using the session
                let response = try await session.respond(to: input, generating: MartiniResponse.self, options: options)
                let data = response.content

                print("\n💬 \(data.message)")
                if !data.plan.isEmpty {
                    print("📋 Plan:")
                    data.plan.forEach { print("  • \($0)") }
                }
                
                if let suggestion = data.suggestion {
                    print("\n💡 Tip: Try '\(suggestion)'")
                }

                // 5. Update History Context
                let transcriptSummary = session.transcript.map { entry in
                    return "- \(entry.description)"
                }.joined(separator: "\n")

                // Refresh instructions with new history
                session = LanguageModelSession(
                    tools: toolset,
                    instructions: Martini.generateInstructions(history: transcriptSummary)
                )
                session.prewarm()
                
            } catch {
                print("\n❌ System Error: \(error.localizedDescription)")
            }
        }
    }

    static func generateInstructions(history: String) -> String {
        return """
        You are the 'Martini' CLI Orchestrator. 
        
        CURRENT CONTEXT:
        \(history)
        
        OPERATIONAL CONSTRAINTS:
        1. Always check 'FileSystemManager' if the user refers to files you haven't seen.
        2. Use 'ManualLookup' for unfamiliar commands to ensure syntax is 100% correct.
        3. If 'ExecuteCommand' returns 'TASK_CANCELLED', the user rejected the plan. Acknowledge and stop.
        4. You are running in a full TTY; you can propose interactive commands (sudo, vim, etc).
        """
    }

    private func checkModelStatus() -> (isReady: Bool, message: String) {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return (true, "✅ Apple Intelligence ready.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return (false, "⚠️  Please enable Apple Intelligence in Settings.")
        default:
            return (false, "❌ Apple Intelligence is unavailable (\(model.availability)).")
        }
    }
}
