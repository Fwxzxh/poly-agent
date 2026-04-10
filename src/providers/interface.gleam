//// This module defines the common interface for AI providers.
//// Any new LLM integration (like OpenAI, Claude, or local models) must
//// adhere to the `Provider` type defined here.

import common/types.{type FunctionDeclaration, type Message, type Part}
import gleam/option.{type Option}

/// A `Provider` represents an integration with a specific AI model API.
pub type Provider {
  Provider(
    /// The unique name of the provider (e.g., "gemini", "openai").
    name: String,
    /// The main execution function for the provider.
    /// It takes the conversation history, an optional system instruction,
    /// credentials, model identifier, tool declarations, and a debug flag.
    /// It returns a list of message parts representing the model's response.
    call: fn(
      List(Message),
      Option(String),
      String,
      String,
      List(FunctionDeclaration),
      Bool,
      Bool,
      fn(Part) -> Nil,
    ) ->
      Result(List(Part), Nil),
  )
}
