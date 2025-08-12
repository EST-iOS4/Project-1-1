//
//  TagManagementView.swift
//  Review
//
//  Created by 남병수 on 8/12/25.
//

import SwiftUI

struct TagManagementView: View {
    // ✅ EnvironmentObject로 공유된 TagStore를 가져옵니다.
    @EnvironmentObject var tagStore: TagStore
    @State private var newTagName = ""
    @State private var showingRenameAlertFor: String?

    var body: some View {
        List {
            ForEach(tagStore.allTags, id: \.self) { tag in
                Text(tag)
                    .onTapGesture {
                        showingRenameAlertFor = tag
                    }
            }
            .onDelete(perform: deleteTag)
        }
        .navigationTitle("태그 관리")
        .toolbar {
            EditButton() // 편집(삭제) 모드를 활성화하는 버튼
        }
        .alert("태그 이름 변경", isPresented: Binding(
            get: { showingRenameAlertFor != nil },
            set: { if !$0 { showingRenameAlertFor = nil } }
        )) {
            TextField("새 태그 이름", text: $newTagName)
            Button("변경", action: rename)
            Button("취소", role: .cancel) { newTagName = "" }
        } message: {
            Text("'\(showingRenameAlertFor ?? "")'의 새 이름을 입력하세요.")
        }
        .onChange(of: showingRenameAlertFor) { _, newValue in
            if let tag = newValue {
                newTagName = tag
            }
        }
    }
    
    private func deleteTag(at offsets: IndexSet) {
        tagStore.deleteTag(at: offsets)
    }
    
    private func rename() {
        if let oldName = showingRenameAlertFor {
            tagStore.renameTag(from: oldName, to: newTagName)
        }
        newTagName = ""
        showingRenameAlertFor = nil
    }
}
