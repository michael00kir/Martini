# Martini 🍸

**Martini** is not just a terminal wrapper—it is a professional-grade Zsh orchestrator and autonomous agent built in **Swift**. By leveraging Apple Intelligence, Martini moves beyond static aliases to research, reason, and act within your macOS environment to fulfill complex intents.

## **The Vision: Your Computer, Automated**
Martini is the new way to have a dedicated agent on your computer. We are building toward a world where your intent translates directly into system-level action:
* **Agentic Automation**: You no longer write scripts; you describe a goal. Martini will synthesize the logic, verify the requirements, and build the automation for you.
* **Native Mac Integration**: Martini bridges the gap between the shell and macOS. You can command Martini to create a specific automation, and it will generate the native macOS automations or Shortcuts for you.
* **The CLI App Store**: We are evolving into a platform for agent-ready CLI applications, allowing users to deploy specialized agentic behaviors for any professional workflow.

## **Agentic Features**

* **Autonomous Research**: When faced with an unknown tool or complex syntax, Martini proactively uses the **ManualLookup** tool to ingest official documentation and self-correct.
* **Persistent Contextual Awareness**: Unlike standard shells, Martini maintains a memory of your intent and history, allowing it to execute multi-step plans across different sessions.
* **Stateful Navigation**: The agent understands where it is and where it needs to go, using `FileDiscovery` and `ChangeDirectory` tools to explore your filesystem intelligently.
* **Safety-First Reasoning**: Before any high-risk action (like `rm` or `sudo`), Martini’s safety engine evaluates the command, flags it, and presents a formal proposal for your approval.

## **How the Agent Operates**

Martini follows a cognitive loop to ensure accuracy and sovereignty:

1.  **Deconstruct**: It analyzes your natural language intent to identify the necessary system tools.
2.  **Synthesize**: It researches official "man" pages to ensure the proposed logic is perfect.
3.  **Propose**: It presents a detailed breakdown of flags and side effects, acting as a transparent collaborator.
4.  **Execute & Learn**: Upon confirmation, it executes the task via `/bin/zsh` and updates its internal history to inform future actions.

## **Technical Foundation**

* **Intelligence**: Powered by **Apple Intelligence** (SystemLanguageModel).
* **OS Requirements**: Optimized for **macOS 26.2+**.
* **Language**: Built with **Swift 5.0** for native performance and safety.

## **Installation & Deployment**

Currently, Martini is available as an Xcode project. To deploy your agent:
1. Download the latest release and unzip.
2. Open the project in Xcode.
3. Use the **Product > Archive** flow to build and install the binary to your local environment.

*Note: Homebrew formula integration is currently in development to streamline the agent's deployment.*

## **License**
Proprietary / Non-Commercial Private Use [cite: 2].
