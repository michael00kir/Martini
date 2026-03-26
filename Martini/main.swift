//
//  main.swift
//  Martini
//
//  Created by Michael Kir on 13/03/2026.
//

import Foundation
import FoundationModels

let options = GenerationOptions(sampling: .greedy)

print("🍸 Martini Started. Type 'exit' or 'quit' to end.")
print("------------------------------------------------------------")

// 2. Initialize session - NOW PASSING THE HISTORY
    var session = LanguageModelSession(
        tools: [ManualLookupTool(), ExecuteCommandTool()],
        instructions: """
        You are 'Martini', a professional CLI orchestrator.
        
        RULES:
            1. If a tool returns 'TASK_CANCELLED', do not attempt to call any more tools. 
            2. Simply respond to the user with 'Understood. What else can I help with?' 
            3. Never loop the same command twice if the user says no.
        
        WORKFLOW:
        1. If the user refers to a previous command, check the RECENT HISTORY above.
        2. Identify the tool the user needs for new tasks.
        3. Use `ManualLookup` to read its manual.
        4. Use `ExecuteCommand` to propose the final command with a full definition of flags.
        """
    )

while true {
    print("\nMartini> ", terminator: "")
    guard let input = readLine(), !input.isEmpty else { break }
    if ["exit", "quit"].contains(input.lowercased()) { break }

    // 1. Grab the latest history to remind the model
    let historyContext = HistoryManager.shared.getHistorySummary()

    do {
        let response = try await session.respond(to: input, options: options)
        
        // 3. Extract tool calls to save to history
        // In a real-world app, you'd parse the 'transcriptEntries' to find
        // which command was successfully accepted by the user.
        if let lastCall = response.transcriptEntries.last(where: { $0.description.contains("ExecuteCommand") }) {
            // Logic to append to HistoryManager.shared.add(...)
            // is usually handled inside the ExecuteCommandTool's return value.
        }
        
        print("\n\(response)")
    } catch {
        print("\n❌ Error: \(error.localizedDescription)")
    }
    session = LanguageModelSession(
        tools: [ManualLookupTool(), ExecuteCommandTool()],
        instructions: """
        You are 'Martini', a professional CLI orchestrator. 
        
        RECENT HISTORY:
        \(historyContext)
        
        RULES:
            1. If a tool returns 'TASK_CANCELLED', do not attempt to call any more tools. 
            2. Simply respond to the user with 'Understood. What else can I help with?' 
            3. Never loop the same command twice if the user says no.
        
        WORKFLOW:
        1. If the user refers to a previous command, check the RECENT HISTORY above.
        2. Identify the tool the user needs for new tasks.
        3. Use `ManualLookup` to read its manual.
        4. Use `ExecuteCommand` to propose the final command with a full definition of flags.
        """
    )
    session.prewarm()
}
