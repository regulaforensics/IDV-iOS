//
//  ApiKeyConfiguration.swift
//  IDVSample
//
//  Created by Антон Потапчик on 29.08.25.
//

struct ApiKeyConfiguration {
  let apiKey: String
  let host: String

  func isValid() -> Bool {
    [apiKey, host].allSatisfy { $0.isEmpty == false }
  }
}
