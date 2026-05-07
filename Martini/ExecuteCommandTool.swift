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
    let description = "Runs commands in a PTY, supporting interactive prompts like sudo or vim."

    @Generable
    struct Arguments {
        @Guide(description: "The exact shell command to run.")
        var command: String
        @Guide(description: "A detailed breakdown of what this command and flags do.")
        var definition: String
        @Guide(description: "Short summary of the overall goal.")
        var reasoning: String
    }

    func call(arguments: Arguments) async throws -> String {
        // --- 1. THE PROPOSAL UI ---
        print("\n\u{1B}[1;35m" + String(repeating: "━", count: 50) + "\u{1B}[0m")
        print("\u{1B}[1m🎯 GOAL:\u{1B}[0m \(arguments.reasoning)")
        print("\u{1B}[1m📝 DEFINITION:\u{1B}[0m")
        print(arguments.definition.components(separatedBy: "\n").map { "   \($0)" }.joined(separator: "\n"))
        print("\n\u{1B}[1m🚀 PROPOSED COMMAND:\u{1B}[0m")
        print("   \u{1B}[1;32m\(arguments.command)\u{1B}[0m")
        print("\u{1B}[1;35m" + String(repeating: "━", count: 50) + "\u{1B}[0m")
        
        print("Execute this command? (y/n): ", terminator: "")
        guard let response = readLine()?.lowercased(), response == "y" else {
            return "TASK_CANCELLED: The user declined."
        }

        // --- 2. PTY EXECUTION ENGINE ---
        return try await runInPseudoTerminal(command: arguments.command)
    }

    private func runInPseudoTerminal(command: String) async throws -> String {
        var masterFd: Int32 = 0
        let shellPath = "/bin/zsh"
        let args = ["-l", "-c", command]
        
        // Convert Swift strings to C-style pointers for execvp
        let cArgs = ([shellPath] + args).map { strdup($0) } + [nil]
        defer { cArgs.forEach { free($0) } }

        // forkpty creates a child process and a virtual terminal bridge (masterFd)
        let pid = forkpty(&masterFd, nil, nil, nil)
        
        if pid == 0 { // CHILD PROCESS
            execvp(shellPath, cArgs.map { UnsafeMutablePointer($0) })
            exit(1)
        } else if pid > 0 { // PARENT PROCESS (Martini)
            // Put Martini's terminal into 'raw' mode to pass keys (like passwords) directly through
            let oldTerm = setRawMode(fd: STDIN_FILENO)
            defer { resetMode(fd: STDIN_FILENO, term: oldTerm) }

            let masterHandle = FileHandle(fileDescriptor: masterFd)
            let group = DispatchGroup()
            group.enter()

            // Thread A: Forward your typing to the PTY (Passwords, Arrows, Ctrl+C)
            Thread.detachNewThread {
                let stdIn = FileHandle.standardInput
                while true {
                    let data = stdIn.availableData
                    if data.isEmpty { break }
                    try? masterHandle.write(contentsOf: data)
                }
            }

            // Thread B: Forward PTY output back to your screen
            Thread.detachNewThread {
                while true {
                    let data = masterHandle.availableData
                    if data.isEmpty { break }
                    FileHandle.standardOutput.write(data)
                }
                group.leave()
            }

            return await withCheckedContinuation { continuation in
                group.notify(queue: .main) {
                    var status: Int32 = 0
                    waitpid(pid, &status, 0)
                    continuation.resume(returning: status == 0 ? "Command completed successfully." : "Command failed.")
                }
            }
        } else {
            return "ERROR: Failed to fork PTY."
        }
    }

    // --- TERMINAL UTILITIES ---
    
    private func setRawMode(fd: Int32) -> termios {
        var old = termios()
        tcgetattr(fd, &old)
        var raw = old
        cfmakeraw(&raw) // Disables echo and line buffering for password entry
        tcsetattr(fd, TCSADRAIN, &raw)
        return old
    }

    private func resetMode(fd: Int32, term: termios) {
        var t = term
        tcsetattr(fd, TCSADRAIN, &t)
    }
}
