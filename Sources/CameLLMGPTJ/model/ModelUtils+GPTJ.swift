//
//  ModelUtils+GPTJ.swift
//  
//
//  Created by Alex Rozanski on 10/05/2023.
//

import Foundation
import CameLLM
import CameLLMPluginHarness
import CameLLMGPTJObjCxx

public extension ModelUtils {
  static let gptJ = GPTJModelUtils()
}

public class GPTJModelUtils: ModelTypeScopedValidationUtils {
  fileprivate init() {}

  public func validateModel(at fileURL: URL) throws {
    do {
      try _GPTJModelUtils.validateModel(at: fileURL)
    } catch {
      throw NSError(
        domain: CameLLMError.Domain,
        code: CameLLMError.Code.failedToValidateModel.rawValue,
        userInfo: [
          NSLocalizedDescriptionKey: "Model is invalid",
          NSUnderlyingErrorKey: error
        ]
      )
    }
  }
}
