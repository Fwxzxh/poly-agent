# Poly

Poly is a flexible and extensible AI Agent framework built with **Gleam**, leveraging the **OTP/Actor pattern** to create robust, stateful reasoning loops. It is designed to allow AI models (starting with Google Gemini) to interact with the real world through a system of "Skills" and "Tools".

## Features

- 🤖 **Actor-Based Agent**: Built on Gleam's `otp/actor`, providing a clean, concurrent interface for conversation state management.
- ⚡ **Parallel Execution**: Automatically executes multiple tool calls in parallel using Erlang processes to minimize latency.
- 🔒 **Safety First**: Integrated manual approval mechanism for sensitive tools (like writing files or executing shell commands).
- 🌊 **Real-time Streaming**: Supports streaming of both model reasoning ("Thinking") and final text responses.
- 🧠 **Recursive Reasoning**: Automatically handles the "Think-Act-Observe" loop, allowing the agent to call multiple tools in sequence.
- 🛠️ **Developer Skills**: Advanced built-in capabilities for filesystem access (`grep`, `find`, `write`), shell execution, and HTTP requests.
- 💎 **Gemini Integration**: Native support for Google Gemini v1beta API.

## Getting Started

### Prerequisites

- [Gleam](https://gleam.run/) installed.
- A Google AI (Gemini) API Key. [Get one here](https://aistudio.google.com/app/apikey).

### Installation

```sh
gleam add poly
```

### Configuration

Poly uses environment variables for configuration. Create a `.env` file (see `.env.example`):

```env
GOOGLE_API_KEY=your_api_key_here
GOOGLE_MODEL=gemini-3.1-flash-lite-preview
STREAMING=true
VERBOSE=false
DEBUG=false
```

## Basic Usage

Poly comes with a CLI interface, but it's designed to be used as a library.

```gleam
import agent
import common/config
import providers/gemini
import skills/developer
import gleam/option.{Some}
import gleam/erlang/process

pub fn main() {
  // 1. Load configuration
  let assert Ok(cfg) = config.load()
  
  // 2. Define available tools
  let tools = developer.get_tools()

  // 3. Start the Agent actor
  let assert Ok(started) = agent.start(
    config: cfg,
    provider: gemini.gemini_provider(),
    initial_tools: tools,
    system_instruction: Some("You are a helpful assistant."),
    on_event: fn(event) { 
      // Handle events like ThoughtEvent, ToolStartEvent, or StreamTextEvent
      Nil 
    }
  )

  let agent_subject = started.data

  // 4. Send a message
  let reply_subject = process.new_subject()
  process.send(agent_subject, agent.UserMessage("Analyze this project", reply_subject))
  
  // 5. Handle responses (including potential approval requests)
  handle_responses(reply_subject)
}

fn handle_responses(reply_subject) {
  case process.receive_forever(reply_subject) {
    agent.FinalResponse(text) -> {
      // Final result is ready
    }
    agent.ApprovalRequest(name, args, approval_reply) -> {
      // User must approve sensitive tools
      process.send(approval_reply, True)
      handle_responses(reply_subject)
    }
  }
}
```

## Project Structure

- `src/agent.gleam`: The core reasoning loop and Actor implementation.
- `src/providers/`: Integration with LLM providers (e.g., Gemini).
- `src/tools/`: Low-level tool definitions (fs, shell, net).
- `src/skills/`: Collections of tools grouped by capability (e.g., `developer`).
- `src/common/types.gleam`: Shared types for messages, parts, and events.

## Architecture

Poly is built on a "Think-Act-Observe" recursive loop:

1.  **Think**: The Agent sends the conversation history and available tool declarations to the LLM (e.g., Gemini). The LLM returns its reasoning and/or a request to call one or more tools.
2.  **Act**: If the LLM requests tool usage, the Agent executes the corresponding Gleam functions (Executors) defined in the tools.
3.  **Observe**: The results of the tool executions are added to the conversation history as `function` messages.
4.  **Repeat**: The loop recurses, sending the updated history back to the LLM so it can analyze the results and provide a final answer or request further actions.

This entire process is managed by a Gleam **Actor**, which maintains the conversation state safely and concurrently.

## Creating Your Own Tools

You can create custom tools using the `utils.new` builder:

```gleam
import tools/utils
import gleam/json

pub fn my_custom_tool() {
  utils.new("get_secret", "Returns a secret code")
  |> utils.with_string_param("user_id", "The ID of the user", required: True)
  |> utils.build_tool(fn(args) {
    // Logic to get the secret
    json.object([#("secret", json.string("12345"))])
  })
}
```

## Development

```sh
gleam run   # Start the interactive chat agent
gleam test  # Run the test suite
```

## License

Apache-2.0