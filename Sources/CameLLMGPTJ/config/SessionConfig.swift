//
//  SessionConfig.swift
//  CameLLM-GPTJ
//
//  Created by Alex Rozanski on 08/06/2023.
//

import Foundation
import CameLLMGPTJObjCxx

public struct Hyperparameters {
  public fileprivate(set) var batchSize: UInt
  public fileprivate(set) var topK: UInt
  // Should be between 0 and 1
  public fileprivate(set) var topP: Double
  public fileprivate(set) var temperature: Double
  public fileprivate(set) var repeatPenalty: Double

  public init(
    batchSize: UInt,
    topK: UInt,
    topP: Double,
    temperature: Double,
    repeatPenalty: Double
  ) {
    self.batchSize = batchSize
    self.topK = topK
    self.topP = topP
    self.temperature = temperature
    self.repeatPenalty = repeatPenalty
  }
}

// MARK: -

public final class SessionConfig: ObjCxxParamsBuilder {
  // Number of tokens to predict for each run.
  public private(set) var numTokens: UInt

  // Model configuration
  public private(set) var hyperparameters: Hyperparameters

  init(numTokens: UInt, hyperparameters: Hyperparameters) {
    self.numTokens = numTokens
    self.hyperparameters = hyperparameters
  }

  func build(for modelURL: URL) -> _GPTJSessionParams {
    let params = _GPTJSessionParams.defaultParams(withModelPath: modelURL.path)
    params.numberOfTokens = Int32(numTokens)

    params.batchSize = Int32(hyperparameters.batchSize)
    params.topP = Float(hyperparameters.topP)
    params.topK = Int32(hyperparameters.topK)
    params.repeatPenalty = Float(hyperparameters.repeatPenalty)

    return params
  }
}

// MARK: - Config Builders

public class HyperparametersBuilder {
  public private(set) var batchSize: UInt?
  public private(set) var topK: UInt?
  public private(set) var topP: Double?
  public private(set) var temperature: Double?
  public private(set) var repeatPenalty: Double?

  private let defaults: Hyperparameters

  init(defaults: Hyperparameters) {
    self.defaults = defaults
  }

  public func withBatchSize(_ batchSize: UInt?) -> Self {
    self.batchSize = batchSize
    return self
  }

  public func withTopK(_ topK: UInt?) -> Self {
    self.topK = topK
    return self
  }

  public func withTopP(_ topP: Double?) -> Self {
    self.topP = topP
    return self
  }

  public func withTemperature(_ temperature: Double?) -> Self {
    self.temperature = temperature
    return self
  }

  public func withRepeatPenalty(_ repeatPenalty: Double?) -> Self {
    self.repeatPenalty = repeatPenalty
    return self
  }

  func build() -> Hyperparameters {
    return Hyperparameters(
      batchSize: batchSize ?? defaults.batchSize,
      topK: topK ?? defaults.topK,
      topP: topP ?? defaults.topP,
      temperature: temperature ?? defaults.temperature,
      repeatPenalty: repeatPenalty ?? defaults.repeatPenalty
    )
  }
}

// MARK: -

public class SessionConfigBuilder {
  public private(set) var numTokens: UInt?
  public private(set) var hyperparameters: HyperparametersBuilder

  private let defaults: SessionConfig

  init(defaults: SessionConfig) {
    self.hyperparameters = HyperparametersBuilder(defaults: defaults.hyperparameters)
    self.defaults = defaults
  }

  public func withNumTokens(_ numTokens: UInt?) -> Self {
    self.numTokens = numTokens
    return self
  }

  public func withHyperparameters(_ hyperParametersConfig: (HyperparametersBuilder) -> HyperparametersBuilder) -> Self {
    self.hyperparameters = hyperParametersConfig(hyperparameters)
    return self
  }

  // MARK: - Build

  public func build() -> SessionConfig {
    return SessionConfig(
      numTokens: numTokens ?? defaults.numTokens,
      hyperparameters: hyperparameters.build()
    )
  }
}

// MARK: - Params Builders

let defaultSessionConfig = {
  let params = _GPTJSessionParams.defaultParams(withModelPath: "")
  return SessionConfig(
    numTokens: UInt(params.numberOfTokens),
    hyperparameters: Hyperparameters(
      batchSize: UInt(params.batchSize),
      topK: UInt(params.topK),
      topP: Double(params.topP),
      temperature: Double(params.temp),
      repeatPenalty: Double(params.repeatPenalty)
    )
  )
}()
