//
//  SessionConfig+Defaults.swift
//  
//
//  Created by Alex Rozanski on 09/06/2023.
//

import Foundation

public extension SessionConfig {
  static var defaults: SessionConfig {
    return configurableDefaults().build()
  }

  static func configurableDefaults() -> SessionConfigBuilder {
    return SessionConfigBuilder(defaults: defaultSessionConfig)
  }
}
