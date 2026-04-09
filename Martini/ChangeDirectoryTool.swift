//
//  ChangeDirectoryTool.swift
//  Martini
//
//  Created by Michael Kir on 07/04/2026.
//


import Foundation
import FoundationModels

struct ChangeDirectoryTool: Tool {
    let name = "ChangeDirectory"
    let description = "Changes the current working directory for the Martini session."

    @Generable
    struct Arguments {
        @Guide(description: "The absolute or relative path to move to.")
        var path: String
        @Guide(description: "Reason for moving to this directory.")
        var reasoning: String
    }

    func call(arguments: Arguments) async throws -> String {
        let expandedPath = NSString(string: arguments.path).expandingTildeInPath
        var isDirectory: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory), isDirectory.boolValue {
            // Update the process-wide working directory
            FileManager.default.changeCurrentDirectoryPath(expandedPath)
            let newPath = FileManager.default.currentDirectoryPath
            
            return "SUCCESS: Moved to \(newPath). Martini is now operating in this directory."
        } else {
            return "ERROR: Path '\(arguments.path)' does not exist or is not a directory."
        }
    }
}