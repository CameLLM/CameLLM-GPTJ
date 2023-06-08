//
//  GPTJSession.swift
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

import Foundation
import CameLLM
import CameLLMCommon
import CameLLMCommonObjCxx
import CameLLMGPTJObjCxx
import CameLLMPluginHarnessObjCxx

public enum GPTJSessionState {
  case notStarted
  case loadingModel
  case readyToPredict
  case predicting
  case error(Error)
}

public enum GPTJPredictionState {
  case notStarted
  case predicting
  case cancelled
  case finished
  case error(Error)
}

public class GPTJSession: NSObject, Session {
  public typealias SessionState = GPTJSessionState
  public typealias PredictionState = GPTJPredictionState

  public typealias StateChangeHandler = (SessionState) -> Void
  public typealias TokenHandler = (String) -> Void
  public typealias PredictionStateChangeHandler = (PredictionState) -> Void
  public typealias UpdatedContextHandler = (SessionContext) -> Void

  let modelURL: URL
  let paramsBuilder: ObjCxxParamsBuilder

  private lazy var params: _GPTJSessionParams = paramsBuilder.build(for: modelURL)
  private lazy var operationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 1
    operationQueue.qualityOfService = .userInitiated
    return operationQueue
  }()

  private var queuedPredictions = [PredictionPayload]()
  private var _context: GPTJContext?

  // Synchronize state on the main queue.
  public private(set) var state: SessionState = .notStarted {
    didSet {
      stateChangeHandler?(state)
    }
  }

  public var stateChangeHandler: StateChangeHandler? {
    didSet {
      stateChangeHandler?(state)
    }
  }

  public var sessionContextProviding: SessionContextProviding {
    return .none
  }

  init(modelURL: URL, paramsBuilder: ObjCxxParamsBuilder) {
    self.modelURL = modelURL
    self.paramsBuilder = paramsBuilder
  }

  // MARK: - Prediction

  @MainActor
  public func predict(with prompt: String) -> AsyncStream<String> {
    return AsyncStream<String> { continuation in
      runPrediction(
        with: prompt,
        startHandler: {},
        tokenHandler: { token in
          continuation.yield(token)
        },
        completionHandler: { [weak self] in
          self?.state = .readyToPredict
          continuation.finish()
        },
        cancelHandler: { [weak self] in
          self?.state = .readyToPredict
          continuation.finish()
        },
        failureHandler: { [weak self] error in
          self?.state = .error(error)
        },
        handlerQueue: .main
      )
    }
  }

  @MainActor
  public func predict(
    with prompt: String,
    stateChangeHandler: @escaping PredictionStateChangeHandler,
    handlerQueue: DispatchQueue?
  ) -> AsyncStream<String> {
    let handlerQueue = handlerQueue ?? .main
    return AsyncStream<String> { continuation in
      handlerQueue.async {
        stateChangeHandler(.notStarted)
      }
      runPrediction(
        with: prompt,
        startHandler: {
          handlerQueue.async {
            stateChangeHandler(.predicting)
          }
        },
        tokenHandler: { token in
          continuation.yield(token)
        },
        completionHandler: {
          handlerQueue.async {
            stateChangeHandler(.finished)
          }
          continuation.finish()
        },
        cancelHandler: {
          handlerQueue.async {
            stateChangeHandler(.cancelled)
          }
          continuation.finish()
        },
        failureHandler: { error in
          handlerQueue.async {
            stateChangeHandler(.error(error))
          }
          continuation.finish()
        },
        handlerQueue: .main
      )
    }
  }

  @MainActor
  public func predict(
    with prompt: String,
    tokenHandler: @escaping TokenHandler,
    stateChangeHandler: @escaping PredictionStateChangeHandler,
    handlerQueue: DispatchQueue?
  ) -> PredictionCancellable {
    let handlerQueue = handlerQueue ?? .main
    handlerQueue.async {
      stateChangeHandler(.notStarted)
    }
    return runPrediction(
      with: prompt,
      startHandler: {
        handlerQueue.async {
          stateChangeHandler(.predicting)
        }
      },
      tokenHandler: { token in
        handlerQueue.async {
          tokenHandler(token)
        }
      },
      completionHandler: {
        handlerQueue.async {
          stateChangeHandler(.finished)
        }
      },
      cancelHandler: {
        handlerQueue.async {
          stateChangeHandler(.cancelled)
        }
      },
      failureHandler: { error in
        handlerQueue.async {
          stateChangeHandler(.error(error))
        }
      },
      handlerQueue: .main
    )
  }

  @MainActor
  private func loadModelIfNeeded() {
    guard _context == nil && state.needsModelLoad else { return }

    state = .loadingModel

    let operation = GPTJSetupOperation(params: params) { event in
      DispatchQueue.main.async { [weak self] in
        self?.handleSetupOperationEvent(event)
      }
    }
    operationQueue.addOperation(operation)
  }

  @MainActor
  @discardableResult private func runPrediction(
    with prompt: String,
    startHandler: @escaping () -> Void,
    tokenHandler: @escaping (String) -> Void,
    completionHandler: @escaping () -> Void,
    cancelHandler: @escaping () -> Void,
    failureHandler: @escaping (Error) -> Void,
    handlerQueue: DispatchQueue
  ) -> PredictionCancellable {
    let identifier = UUID().uuidString
    let payload = PredictionPayload(
      identifier: identifier,
      prompt: prompt,
      startHandler: startHandler,
      tokenHandler: tokenHandler,
      completionHandler: completionHandler,
      cancelHandler: cancelHandler,
      failureHandler: failureHandler,
      handlerQueue: handlerQueue
    )

    if state.needsModelLoad {
      queuedPredictions.append(payload)
      loadModelIfNeeded()
    } else {
      runPrediction(payload: payload)
    }

    return ClosurePredictionCancellable { [weak self] in
      DispatchQueue.main.async {
        self?.cancelPrediction(with: identifier)
      }
    }
  }

  @MainActor
  private func runPrediction(payload: PredictionPayload) {
    guard !state.isErrorState else {
      let error = makeFailedToPredictErrorWithUnderlyingError(makeCameLLMError(.generalInternalPredictionFailure, "Couldn't run prediction as session is in error state"))
      payload.handlerQueue.async {
        payload.failureHandler(error)
      }
      return
    }

    guard let context = _context else {
      let error = makeFailedToPredictErrorWithUnderlyingError(makeCameLLMError(.generalInternalPredictionFailure, "Couldn't run prediction as context is not set"))
      payload.handlerQueue.async {
        payload.failureHandler(error)
      }
      return
    }

    let predictOperation = GPTJPredictOperation(
      identifier: payload.identifier,
      context: context,
      prompt: payload.prompt,
      eventHandler: { event in
        DispatchQueue.main.async { [weak self] in
          self?.handlePredictOperationEvent(event, with: payload)
        }
      }
    )

    operationQueue.addOperation(predictOperation)
  }

  @MainActor
  private func handleSetupOperationEvent(_ event: _CameLLMSetupEvent<GPTJContext>) {
    event.matchSucceeded { context in
      _context = context
      state = .readyToPredict

      for payload in queuedPredictions {
        runPrediction(payload: payload)
      }

      queuedPredictions = []
    } failed: { error in
      state = .error(error)

      for payload in queuedPredictions {
        payload.handlerQueue.async {
          payload.failureHandler(error)
        }
      }

      queuedPredictions = []
    }
  }

  @MainActor
  private func handlePredictOperationEvent(_ event: _CameLLMPredictionEvent, with payload: PredictionPayload) {
    event.matchStarted {
      state = .predicting
      payload.handlerQueue.async {
        payload.startHandler()
      }
    } outputToken: { token in
      payload.handlerQueue.async {
        payload.tokenHandler(token)
      }
    } updatedSessionContext: { newContext in
      // Not supported yet.
    } completed: {
      state = .readyToPredict
      payload.handlerQueue.async {
        payload.completionHandler()
      }
    } cancelled: {
      state = .readyToPredict
      payload.handlerQueue.async {
        payload.cancelHandler()
      }
    } failed: { error in
      state = .error(error ?? NSError())
      payload.handlerQueue.async {
        payload.failureHandler(error ?? NSError())
      }
    }
  }

  @MainActor
  private func cancelPrediction(with identifier: String) {
    if cancelQueuedPrediction(with: identifier) {
      return
    }

    for operation in operationQueue.operations {
      if let predictOperation = operation as? GPTJPredictOperation, predictOperation.identifier == identifier, predictOperation.isExecuting {
        predictOperation.cancel()
      }
    }
  }

  @MainActor
  private func cancelQueuedPrediction(with identifier: String) -> Bool {
    guard let payloadIndex = queuedPredictions.firstIndex(where: { $0.identifier == identifier }) else {
      return false
    }

    queuedPredictions.remove(at: payloadIndex)
    return true
  }
}

fileprivate extension GPTJSessionState {
  var needsModelLoad: Bool {
    switch self {
    case .notStarted: return true
    case .loadingModel, .readyToPredict, .predicting, .error: return false
    }
  }

  var isErrorState: Bool {
    switch self {
    case .notStarted, .loadingModel, .readyToPredict, .predicting: return false
    case .error: return true
    }
  }
}
