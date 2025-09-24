//
//  ApiKeyConfiguration.swift
//  IDVSample
//
//  Created by Антон Потапчик on 29.08.25.
//

struct ApiKeyConfiguration {
  let apiKey: String
  let host: String
  let workflowId: String

  func isValid() -> Bool {
    [apiKey, host, workflowId].allSatisfy { $0.isEmpty == false }
  }
}
