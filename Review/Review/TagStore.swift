//
//  TagStore.swift
//  Review
//
//  Created by 남병수 on 8/12/25.
//

import Foundation
import Combine

// ObservableObject: 이 객체의 데이터가 바뀌면 관련된 뷰들이 자동으로 업데이트됩니다.
class TagStore: ObservableObject {
  // @Published: allTags 배열이 변경될 때마다 뷰에 자동으로 알려줍니다.
  @Published var allTags: [String] {
    didSet {
      // 태그 목록이 변경될 때마다 UserDefaults에 저장합니다.
      saveTags()
    }
  }
  
  private let userDefaultsKey = "allSavedTags"
  
  init() {
    // 앱이 시작될 때 UserDefaults에서 저장된 태그를 불러옵니다.
    self.allTags = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
  }
  
  // 태그를 추가하는 함수 (중복은 추가하지 않음)
  func addTag(_ tag: String) {
    guard !tag.isEmpty, !allTags.contains(tag) else { return }
    allTags.append(tag)
    allTags.sort() // 가나다순으로 정렬
  }
  
  // 여러 태그를 한 번에 추가하는 함수
  func addTags(_ tags: [String]) {
    for tag in tags {
      addTag(tag)
    }
  }
  
  // 태그를 삭제하는 함수
  func deleteTag(at offsets: IndexSet) {
    allTags.remove(atOffsets: offsets)
  }
  
  // 태그 이름을 변경하는 함수
  func renameTag(from oldName: String, to newName: String) {
    guard !newName.isEmpty, !allTags.contains(newName), let index = allTags.firstIndex(of: oldName) else { return }
    allTags[index] = newName
    allTags.sort()
  }
  
  // 변경된 태그 목록을 저장하는 내부 함수
  private func saveTags() {
    UserDefaults.standard.set(allTags, forKey: userDefaultsKey)
  }
}
