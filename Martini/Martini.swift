//
//  main.swift
//  Martini
//
//  Created by Michael Kir on 13/03/2026.
//
//
//  main.swift
//  Martini
//
//  Created by Michael Kir on 13/03/2026.
//

import Foundation
import FoundationModels
import ArgumentParser

//Structures the response
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
        abstract: "A professional CLI orchestrator powered by Apple Intelligence.",
        version: "1.0.0"
    )

    func run() async throws {
        // 1. Initial Setup & Model Verification
        print("🍸 Martini Started. Type 'exit' or 'quit' to end.")
        print("------------------------------------------------------------")

        let status = checkModelStatus()
        print(status.message)

        if !status.isReady {
            print("Martini requires Apple Intelligence to function. Exiting...")
            throw ExitCode.failure
        }

        // 2. Initial Session Setup (Outside the loop)
        let options = GenerationOptions(sampling: .greedy)
        let toolset: [any Tool] = [
            ManualLookupTool(),
            ExecuteCommandTool(),
            FileSystemManager(),
            ShortcutsTool()
        ]

        var session = LanguageModelSession(
            tools: toolset,
            instructions: Martini.generateInstructions(history: "No history so far")
        )

        // 3. The REPL Loop
        while true {
            print("\nMartini> ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { break }
            if ["exit", "quit"].contains(input.lowercased()) { break }

            do {
                // 1. Respond using the current session
                let response = try await session.respond(to: input, generating: MartiniResponse.self, options: options)
                    let data = response.content // This is now an instance of MartiniResponse

                    // Print using the structured data
                    print("\n💬 \(data.message)")
                    if !data.plan.isEmpty {
                        print("📋 Plan:")
                        data.plan.forEach { print("  • \($0)") }
                    }
                    if let suggestion = data.suggestion {
                        print("\n💡 Tip: Try '\(suggestion)'")
                    }

                // 2. Extract history from the session's actual transcript
                // This captures EVERY tool call and AI response automatically.
                let transcriptSummary = session.transcript.map { entry in
                    return "- \(entry.description)"
                }.joined(separator: "\n")

                // 3. Refresh the session with the new transcript data
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

    // Static helper to keep instructions consistent between refreshes
    static func generateInstructions(history: String) -> String {
        return """
        You are the 'Martini' CLI Orchestrator. 
            
            CONTEXT:
            \(history)
            
            OPERATIONAL CONSTRAINTS:
            1. Use 'FileSystemManager' for directory context before execution.
            2. Use 'ManualLookup' to verify CLI flags for 'ExecuteCommand'.
            3. If 'ExecuteCommand' returns 'TASK_CANCELLED', stop immediately.
        """
    }

    private func checkModelStatus() -> (isReady: Bool, message: String) {
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            return (true, "✅ Apple Intelligence is available and ready.")
        case .unavailable(.deviceNotEligible):
            return (false, "❌ Error: This device is not eligible for Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return (false, "⚠️  Apple Intelligence is disabled. Please enable it in System Settings.")
        case .unavailable(.modelNotReady):
            return (false, "⏳ The model is currently downloading or preparing.")
        case .unavailable(_):
            return (false, "❌ Apple Intelligence is unavailable for an unknown reason.")
        }
    }
}
