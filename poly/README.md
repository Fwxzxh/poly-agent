# Poly

Poly is a flexible and extensible AI Agent framework built with **Gleam**, leveraging the **OTP/Actor pattern** to create robust, stateful reasoning loops. It is designed to allow AI models (starting with Google Gemini) to interact with the real world through a system of "Skills" and "Tools".

## Features

- 🤖 **Actor-Based Agent**: Built on Gleam's `otp/actor`, providing a clean, concurrent interface for conversation state management.
- 🛠️ **Extensible Tooling**: Easily define new tools with a type-safe `ToolBuilder`.
- 🧠 **Recursive Reasoning**: Automatically handles the "Think-Act-Observe" loop, allowing the agent to call multiple tools in sequence to solve complex tasks.
- 💎 **Gemini Integration**: Native support for Google Gemini models, including support for "Thinking" (reasoning) parts.
- 🛠️ **Developer Skills**: Built-in capabilities for filesystem access, shell command execution, and HTTP requests.

## Getting Started

### Prerequisites

- [Gleam](https://gleam.run/) installed.
- A Google AI (Gemini) API Key. [Get one here](https://aistudio.google.com/app/apikey).

### Installation

```sh
gleam add poly
```

### Configuration

Create a `.env` file in your project root:

```env
GOOGLE_API_KEY=your_api_key_here
DEBUG=false
```

## Basic Usage

Poly comes with a CLI interface in its `main` module, but you can also use it as a library.

```gleam
import agent
import providers/gemini
import skills/developer
import gleam/option.{Some}
import gleam/erlang/process

pub fn main() {
  let api_key = "your-api-key"
  
  // 1. Define available tools
  let tools = developer.get_tools()

  // 2. Start the Agent actor
  let assert Ok(started) = agent.start(
    api_key: api_key,
    provider: gemini.gemini_provider(),
    initial_tools: tools,
    system_instruction: Some("You are a helpful assistant."),
    on_event: fn(event) { 
      // Handle events like ThoughtEvent or ToolStartEvent here
      Nil 
    },
    debug: False,
  )

  let agent_subject = started.data

  // 3. Send a message and wait for the response
  let reply_subject = process.new_subject()
  process.send(agent_subject, agent.UserMessage("List the files in the current directory", reply_subject))
  
  let response = process.receive_forever(reply_subject)
  // response will contain the agent's final answer after running the tools
}
```

## Project Structure

- `src/agent.gleam`: The core reasoning loop and Actor implementation.
- `src/providers/`: Integration with LLM providers (e.g., Gemini).
- `src/tools/`: Low-level tool definitions (fs, shell, net).
- `src/skills/`: Collections of tools grouped by capability (e.g., `developer`).
- `src/common/types.gleam`: Shared types for messages, parts, and events.

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