//
//  DateFormat.swift
//  Review
//
//  Created by 송영민 on 8/18/25.
//

import Foundation

extension Date {
  static let yyyyMMddFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyy. MM. dd"
    return f
  }()

  func toYYYYMMDD() -> String { Self.yyyyMMddFormatter.string(from: self) }
}
