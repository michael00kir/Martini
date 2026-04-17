//
//  main.swift
//  Martini
//
//  Created by Michael Kir on 13/03/2026.
//

import Foundation
import FoundationModels

func checkModelStatus() -> (isReady: Bool, message: String) {
    let model = SystemLanguageModel.default
    
    switch model.availability {
    case .available:
        return (true, "✅ Apple Intelligence is available and ready.")
    case .unavailable(.deviceNotEligible):
        return (false, "❌ Error: This device is not eligible for Apple Intelligence.")
    case .unavailable(.appleIntelligenceNotEnabled):
        return (false, "⚠️  Apple Intelligence is disabled. Please enable it in System Settings.")
    case .unavailable(.modelNotReady):
        return (false, "⏳ The model is currently downloading or preparing. Please wait.")
    case .unavailable(_):
        return (false, "❌ Apple Intelligence is unavailable for an unknown reason.")
    }
}

let options = GenerationOptions(sampling: .greedy)

print("🍸 Martini Started. Type 'exit' or 'quit' to end.")
print("------------------------------------------------------------")

// Verify Model Availability
let status = checkModelStatus()
print(status.message)

if !status.isReady {
    print("Martini requires Apple Intelligence to function. Exiting...")
    exit(1)
}
// 2. Initialize session - NOW PASSING THE HISTORY
    var session = LanguageModelSession(
        tools: [ManualLookupTool(), ExecuteCommandTool(), ChangeDirectoryTool(),
                FileDiscoveryTool()],
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
        print(response.content)
        if response.transcriptEntries.last(where: { $0.description.contains("ExecuteCommand") }) != nil {
        }
    } catch {
        print("\n❌ System Error: \(error.localizedDescription)")
    }
    session = LanguageModelSession(
        tools: [ManualLookupTool(), ExecuteCommandTool(), ChangeDirectoryTool(),
                FileDiscoveryTool()],
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
        
        NAVIGATION RULES:
            1. Always use 'FileDiscovery' with 'list' before jumping into a directory you aren't sure of.
            2. Use 'ChangeDirectory' to move your context; do not just run 'cd' inside 'ExecuteCommand' as it won't persist.
            3. If the user asks "where am I?", use FileDiscovery (where).
        """
    )
    session.prewarm()
}
