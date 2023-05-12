//
//  SessionManager+GPTJ.swift
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

import Foundation
import CameLLM
import CameLLMPluginHarness

public extension SessionManager {
  static let gpt4AllJ = GPTJSessionManager()
}

public class GPTJSessionManager {
  public func makeSession(
    with modelURL: URL
  ) -> any Session<GPTJSessionState, GPTJPredictionState> {
    return GPTJSession(modelURL: modelURL)
  }
}
