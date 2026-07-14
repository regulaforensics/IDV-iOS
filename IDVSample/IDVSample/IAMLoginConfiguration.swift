//
//  IAMLoginConfiguration.swift
//  IDVSample
//
//  Created by Антон Потапчик on 18.06.26.
//

struct IAMLoginConfiguration {
  let applicationId: String
  let baseURL: String

  func isValid() -> Bool {
    [applicationId, baseURL].allSatisfy { $0.isEmpty == false }
  }
}
