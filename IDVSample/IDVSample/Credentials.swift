//
//  Credentials.swift
//  IDVSample
//
//  Created by Serge Rylko on 26.03.25.
//


struct Credentials {
  let userName: String
  let password: String
  let host: String
  let workflowId: String

  func isValid() -> Bool {
    [userName, password, host, workflowId].allSatisfy { $0.isEmpty == false }
  }
}
