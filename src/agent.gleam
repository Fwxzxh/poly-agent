//// This module implements the AI Agent using the Gleam Actor (OTP) pattern.
//// It manages conversation state and the reasoning loop for tool usage.

import common/types
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/string
import providers/interface as provider
import tools/utils

/// Internal state of the agent.
pub type State {
  State(
    /// History of messages in the current conversation.
    history: List(types.Message),
    /// System context or instructions.
    system_instruction: Option(String),
    /// API Key for the provider.
    api_key: String,
    /// The model identifier.
    model: String,
    /// The provider implementation.
    provider: provider.Provider,
    /// List of tools available to the agent.
    tools: List(utils.Tool),
    /// Callback for agent events.
    on_event: fn(types.AgentEvent) -> Nil,
    /// Whether to print raw requests and responses.
    debug: Bool,
  )
}

/// Messages that the Agent actor can handle.
pub type AgentResponse {
  /// The final text response from the agent.
  FinalResponse(String)
  /// A request for the user to approve a tool execution.
  ApprovalRequest(name: String, args: json.Json, reply_to: Subject(Bool))
}

pub type AgentMessage {
  /// A message from the user. Includes a reply subject for responses and requests.
  UserMessage(content: String, reply_to: Subject(AgentResponse))
}

/// Starts the agent actor with an initial configuration.
pub fn start(
  api_key: String,
  model: String,
  provider: provider.Provider,
  initial_tools: List(utils.Tool),
  system_instruction: Option(String),
  on_event: fn(types.AgentEvent) -> Nil,
  debug: Bool,
) {
  let initial_state =
    State(
      history: [],
      system_instruction: system_instruction,
      api_key: api_key,
      model: model,
      provider: provider,
      tools: initial_tools,
      on_event: on_event,
      debug: debug,
    )

  actor.new(initial_state)
  |> actor.on_message(loop)
  |> actor.start
}

/// The main actor loop. Handles incoming messages and updates state.
fn loop(state: State, message: AgentMessage) -> actor.Next(State, AgentMessage) {
  case message {
    UserMessage(content, reply_to) -> {
      let user_msg = types.Message("user", [types.Text(content, None)])
      let new_history = list.append(state.history, [user_msg])

      let #(response_text, final_history) =
        run_reasoning_loop(
          new_history,
          state.system_instruction,
          state.api_key,
          state.model,
          state.provider,
          state.tools,
          state.on_event,
          10,
          state.debug,
          reply_to,
        )

      process.send(reply_to, FinalResponse(response_text))
      actor.continue(State(..state, history: final_history))
    }
  }
}

/// Orchestrates the conversation with the AI provider using a recursive loop.
///
/// This function:
/// 1. Sends the current history and tool declarations to the provider.
/// 2. Processes the model's response (text and/or function calls).
/// 3. If there are function calls:
///    - Executes the corresponding tools.
///    - Adds the results to the history as `function` messages.
///    - Recurses to let the model "observe" the results and continue its reasoning.
/// 4. If there are no function calls, it returns the final text response.
fn run_reasoning_loop(
  history: List(types.Message),
  system_instruction: Option(String),
  api_key: String,
  model: String,
  provider: provider.Provider,
  available_tools: List(utils.Tool),
  on_event: fn(types.AgentEvent) -> Nil,
  max_steps: Int,
  debug: Bool,
  reply_to: Subject(AgentResponse),
) -> #(String, List(types.Message)) {
  case max_steps {
    0 -> #("I've reached the maximum number of reasoning steps.", history)
    _ -> {
      let tool_declarations = list.map(available_tools, fn(t) { t.declaration })
      let response =
        provider.call(
          history,
          system_instruction,
          api_key,
          model,
          tool_declarations,
          debug,
        )

      case response {
        Error(_) -> {
          #(
            "I'm sorry, I encountered an error processing your request.",
            history,
          )
        }
        Ok(parts) -> {
          list.each(parts, fn(p) { handle_part_events(p, on_event) })
          let model_msg = types.Message("model", parts)
          let updated_history = list.append(history, [model_msg])

          let function_calls = get_function_calls(parts)

          case function_calls {
            [] -> #(extract_text(parts), updated_history)
            calls -> {
              let tool_responses =
                execute_tools(calls, available_tools, on_event, reply_to)
              let tool_msg = types.Message("function", tool_responses)
              run_reasoning_loop(
                list.append(updated_history, [tool_msg]),
                system_instruction,
                api_key,
                model,
                provider,
                available_tools,
                on_event,
                max_steps - 1,
                debug,
                reply_to,
              )
            }
          }
        }
      }
    }
  }
}

/// The accumulated messages in the conversation.
/// Optional system instructions to guide the model's behavior.
/// API Key for the provider.
/// The model ID to use (e.g., "gemini-1.5-flash").
/// The provider implementation (e.g., Gemini).
/// The set of tools the model is allowed to use.
/// A callback to emit events during the loop.
/// Maximum number of tool-execution cycles to prevent infinite loops.
/// Whether to log internal requests/responses.
fn handle_part_events(part: types.Part, on_event: fn(types.AgentEvent) -> Nil) {
  case part {
    types.Thought(text, _) -> on_event(types.ThoughtEvent(text))
    types.FunctionCall(name, args, _) ->
      on_event(types.ToolStartEvent(name, types.dynamic_to_json(args)))
    _ -> Nil
  }
}

/// Executes the tools requested by the model and returns the responses as message parts.
/// This implementation executes tools in parallel using Erlang processes.
/// If a tool requires approval, it pauses and waits for user input via the `reply_to` subject.
pub fn execute_tools(
  calls: List(#(String, decode.Dynamic)),
  available_tools: List(utils.Tool),
  on_event: fn(types.AgentEvent) -> Nil,
  reply_to: Subject(AgentResponse),
) -> List(types.Part) {
  calls
  |> list.map(fn(call) {
    let call_reply_subject = process.new_subject()
    process.spawn(fn() {
      let #(name, args) = call
      let tool =
        list.find(available_tools, fn(t) { t.declaration.name == name })

      let result = case tool {
        Ok(t) -> {
          let should_execute = case t.requires_approval {
            True -> {
              let approval_reply_subject = process.new_subject()
              process.send(
                reply_to,
                ApprovalRequest(
                  name,
                  types.dynamic_to_json(args),
                  approval_reply_subject,
                ),
              )
              process.receive_forever(approval_reply_subject)
            }
            False -> True
          }

          case should_execute {
            True -> {
              let response = t.executor(cast_to_json(args))
              on_event(types.ToolResultEvent(name, response))
              types.FunctionResponse(name, response)
            }
            False -> {
              let err =
                json.object([#("error", json.string("User denied execution"))])
              on_event(types.ToolResultEvent(name, err))
              types.FunctionResponse(name, err)
            }
          }
        }
        Error(_) -> {
          let err = json.object([#("error", json.string("Tool not found"))])
          on_event(types.ToolResultEvent(name, err))
          types.FunctionResponse(name, err)
        }
      }
      process.send(call_reply_subject, result)
    })
    call_reply_subject
  })
  |> list.map(fn(sub) { process.receive_forever(sub) })
}

/// Helper to filter out and identify function calls from a list of parts.
pub fn get_function_calls(
  parts: List(types.Part),
) -> List(#(String, decode.Dynamic)) {
  list.filter_map(parts, fn(p) {
    case p {
      types.FunctionCall(name, args, _sig) -> Ok(#(name, args))
      _ -> Error(Nil)
    }
  })
}

/// Helper to extract the first text part from a list of message parts.
pub fn extract_text(parts: List(types.Part)) -> String {
  let texts =
    list.filter_map(parts, fn(p) {
      case p {
        types.Text(t, _sig) -> Ok(t)
        _ -> Error(Nil)
      }
    })

  case texts {
    [] ->
      list.filter_map(parts, fn(p) {
        case p {
          types.Thought(t, _sig) -> Ok(t)
          _ -> Error(Nil)
        }
      })
      |> string.join("\n")
    _ -> string.join(texts, "\n")
  }
}

@external(erlang, "poly_ffi", "identity")
fn cast_to_json(a: any) -> json.Json
