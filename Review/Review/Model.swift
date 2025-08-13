//
//  Model.swift
//  Review
//
//  Created by 남병수 on 8/13/25.
//

import Foundation

struct Memo: Identifiable {
    let id: UUID
    var day: Date
    var tags: [String]
    var content: String

    init(id: UUID = UUID(), day: Date, tags: [String], content: String) {
        self.id = id
        self.day = day
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
