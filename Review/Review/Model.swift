//
//  Model.swift
//  Review
//
//  Created by 남병수 on 8/13/25.
//

import SwiftUI
import Foundation

struct Memo: Identifiable {
    let id: UUID
    var day: Date
    var title: String
    var tags: [String]
    var content: String

  init(id: UUID = UUID(), day: Date, title: String, tags: [String], content: String) {
        self.id = id
        self.day = day
        self.title = title
        self.tags = tags
        self.content = content
    }
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd a hh:mm"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: date)
}

enum Screen {
    case memoList
    case statistics
    case settings
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
