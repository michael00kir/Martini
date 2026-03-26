# **Martini** 🍸

**Martini** is a professional Command Line Interface (CLI) orchestrator built in **Swift**. It acts as an intelligent assistant that researches, explains, and safely executes shell commands based on user intent.

## **Features**

* **Intelligent Documentation Lookup**: Automatically retrieves and cleans manual pages for CLI tools to ensure correct syntax.
* **Safe Command Execution**: Proposes commands with detailed breakdowns of flags and logic before running them.
* **High-Risk Detection**: Includes a safety engine that flags dangerous operations like `sudo`, `rm`, or recursive permission changes.
* **Session History**: Maintains a context of the last five commands and user intents to allow for informed follow-up requests.
* **Interactive UI**: Provides a color-coded terminal interface for reviewing and confirming actions.

## **How It Works**

**Martini** follows a structured workflow to ensure accuracy and safety:

1.  **Analyze**: Identifies the necessary CLI tools based on your request.
2.  **Research**: Uses the **ManualLookup** tool to read the official "man" pages or help documentation.
3.  **Propose**: Presents a formal proposal via the **ExecuteCommand** tool, including the goal, a detailed definition of the command, and its specific flags.
4.  **Confirm**: Waits for explicit user confirmation (`y/n`) before any execution takes place.

## **Built-In Tools**

### **ManualLookup**
Retrieves clean documentation for any CLI tool (e.g., `brew`, `git`). It strips formatting artifacts from standard manual pages to provide highly readable text for the orchestration engine.

### **ExecuteCommand**
Handles the final interaction with the system. It uses `/bin/zsh` to execute confirmed commands and records the results in the session history. It specifically monitors for "red flag" commands such as:
* `sudo`
* `rm`
* `chmod -R 777`
* `format`
* `dd`
* `> /dev/`

## **Technical Details**

* **Language**: **Swift 5.0**.
* **Platform**: **macOS 26.2+**.
* **Architecture**: Built as an Apple **PBXNativeTarget** tool.
* **Shell**: Utilizes `/bin/zsh` for command execution.

## **Installation & Usage**

To start a **Martini** session, run the executable and type your request at the prompt:

```bash
./Martini
