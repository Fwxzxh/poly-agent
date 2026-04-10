//// Poly: A modular AI Agent framework for Gleam.
////
//// This module provides the main entry point for the interactive CLI tool.
//// It initializes the environment, starts the agent actor, and handles
//// the user input loop.

import agent
import common/types
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/option.{Some}
import providers/gemini
import skills/developer
import tools/system

/// The entry point for the Poly AI Agent CLI.
///
/// It performs the following steps:
/// 1. Loads environment variables from a `.env` file.
/// 2. Retrieves the `GOOGLE_API_KEY`.
/// 3. Initializes the reasoning tools (Developer skills).
/// 4. Starts the Agent actor using the Gemini provider.
/// 5. Enters an interactive chat loop.
pub fn main() {
  // Load the .env file if it exists
  dot_env.load_default()

  let api_key = get_api_key()
  let model = get_model()
  let debug = is_debug_enabled()
  let available_tools = developer.get_tools()

  // Prepare system context with host information
  let system_info = system.get_info()
  let system_prompt =
    "You are Poly Agent, a helpful AI assistant.\n"
    <> system.format_as_context(system_info)

  // Start the agent actor
  let assert Ok(started) =
    agent.start(
      api_key,
      model,
      gemini.gemini_provider(),
      available_tools,
      Some(system_prompt),
      handle_event,
      debug,
    )

  let agent_subject = started.data

  io.println("--- Poly AI Agent (Gemini) ---")
  io.println("Configuración cargada correctamente.")
  io.println("Escribe tu mensaje y presiona Enter. Escribe 'exit' para salir.")

  chat_loop(agent_subject)
}

fn get_api_key() -> String {
  case env.get_string("GOOGLE_API_KEY") {
    Ok(key) -> key
    Error(_) -> {
      io.println("Error: GOOGLE_API_KEY no encontrada.")
      io.println(
        "Asegúrate de tener un archivo .env o la variable configurada.",
      )
      panic as "Missing API key"
    }
  }
}

fn get_model() -> String {
  case env.get_string("GOOGLE_MODEL") {
    Ok(model) -> model
    Error(_) -> "gemini-3.1-flash-lite-preview"
  }
}

fn is_debug_enabled() -> Bool {
  case env.get_string("DEBUG") {
    Ok("true") -> True
    _ -> False
  }
}

fn is_verbose_enabled() -> Bool {
  case env.get_string("VERBOSE") {
    Ok("true") -> True
    _ -> False
  }
}

/// Handles events emitted by the agent during its reasoning process.
/// This implementation prints thoughts and tool calls to the console with ANSI colors.
fn handle_event(event: types.AgentEvent) {
  case event {
    types.ThoughtEvent(text) -> {
      // Print model reasoning in italics/dimmed
      io.println("\u{1b}[2m\u{1b}[3m> Thinking: " <> text <> "\u{1b}[0m")
    }
    types.ToolStartEvent(name, args) -> {
      let args_str = json.to_string(args)
      // Print tool execution in bold blue
      io.println(
        "\u{1b}[34m\u{1b}[1m> Tool Call: "
        <> name
        <> "("
        <> args_str
        <> ")\u{1b}[0m",
      )
    }
    types.ToolResultEvent(name, result) -> {
      case is_verbose_enabled() {
        True -> {
          let result_str = json.to_string(result)
          io.println(
            "\u{1b}[32m> Tool Result ["
            <> name
            <> "]: "
            <> result_str
            <> "\u{1b}[0m",
          )
        }
        False -> {
          io.println("\u{1b}[32m> Tool [" <> name <> "] completed.\u{1b}[0m")
        }
      }
    }
  }
}

/// Enters an interactive chat loop that reads user input and prints agent responses.
///
/// It uses a synchronous `process.receive_forever` to wait for the agent's
/// full reasoning process to complete before prompting for the next input.
fn chat_loop(agent_subject) {
  io.print("> ")
  let input = read_line()

  case input {
    "exit\n" -> io.println("¡Adiós!")
    _ -> {
      let reply_subject = process.new_subject()
      process.send(agent_subject, agent.UserMessage(input, reply_subject))

      // Block until the agent finishes its reasoning loop and responds.
      // The reasoning loop might involve multiple tool calls and approval requests.
      wait_for_response(reply_subject)
      chat_loop(agent_subject)
    }
  }
}

fn wait_for_response(reply_subject) {
  let response = process.receive_forever(reply_subject)
  case response {
    agent.FinalResponse(text) -> io.println("Agent: " <> text)
    agent.ApprovalRequest(name, args, reply_to) -> {
      let args_str = json.to_string(args)
      io.println(
        "\u{1b}[33m\u{1b}[1m> Approval Required: "
        <> name
        <> "("
        <> args_str
        <> ")\u{1b}[0m",
      )
      io.print("Allow execution? [y/N]: ")
      let input = read_line()
      let approved = case input {
        "y\n" | "Y\n" | "yes\n" -> True
        _ -> False
      }
      process.send(reply_to, approved)
      // Wait for the next part of the response (could be another tool call or final text)
      wait_for_response(reply_subject)
    }
  }
}

/// Reads a line from standard input using an Erlang NIF.
@external(erlang, "poly_ffi", "read_line")
fn read_line() -> String
