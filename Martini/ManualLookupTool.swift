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
    let description = "Retrieves clean manual pages for any CLI tool. Use this to find correct syntax."

    @Generable
    struct Arguments {
        @Guide(description: "The CLI tool to research (e.g., 'brew', 'git')")
        var toolName: String
    }

    func call(arguments: Arguments) async throws -> String {
        print("\n🔍 \u{1B}[33m[Martini is researching '\(arguments.toolName)'...]\u{1B}[0m")
        
        // '| col -b' strips the bold/underline stuttering (NNAAMMEE -> NAME)
        let command = "/usr/bin/man -P cat \(arguments.toolName) | /usr/bin/col -b || \(arguments.toolName) --help"
        
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                return "CLEAN DOCS FOR \(arguments.toolName):\n\(output.prefix(4500))"
            }
        } catch {
            return "ERROR: Lookup failed."
        }
        
        return "ERROR: No documentation found."
    }
}
