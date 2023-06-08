//
//  ObjCxxParamsBuilder.swift
//
//
//  Created by Alex Rozanski on 08/06/2023.
//

import Foundation
import CameLLMGPTJObjCxx

protocol ObjCxxParamsBuilder {
  func build(for modelURL: URL) -> _GPTJSessionParams
}
