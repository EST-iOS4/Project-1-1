//
// TexteditView.swift
// Review
//
//  Created by 남병수 on 8/11/25.
//
//

import SwiftUI

struct TexteditView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var memos: [Memo]
    var memoToEdit: Memo?
    
    @State private var reviewText: String
    @State private var lastSavedText: String
    
    private var isEditMode: Bool
    
    @FocusState private var isKeyboardFocused: Bool

    init(memos: Binding<[Memo]>, memoToEdit: Memo? = nil) {
        self._memos = memos
        self.memoToEdit = memoToEdit
        self.isEditMode = (memoToEdit != nil)
        
        if let memo = memoToEdit {
            let initialText = memo.content
            self._reviewText = State(initialValue: initialText)
            self._lastSavedText = State(initialValue: initialText)
        } else {
            self._reviewText = State(initialValue: "")
            self._lastSavedText = State(initialValue: "")
        }
    }
    
    var body: some View {
        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        VStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $reviewText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal)
                    .focused($isKeyboardFocused)
                
                if reviewText.isEmpty {
                    Text("회고를 작성하세요...")
                        .font(.body)
                        .foregroundStyle(.gray.opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 24)
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle(isEditMode ? "회고 수정" : "회고 작성")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    saveAndDismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    saveAndStay()
                }
                .disabled(trimmedText.isEmpty || trimmedText == lastSavedText)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            isKeyboardFocused = true
        }
    }
    
    private func saveMemo() {
        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let memoToEdit = memoToEdit,
           let index = memos.firstIndex(where: { $0.id == memoToEdit.id }) {
            memos[index].day = Date()
            memos[index].content = trimmedText
        } else {
            let newMemo = Memo(day: Date(), content: trimmedText)
            memos.append(newMemo)
        }
    }
    
    private func saveAndDismiss() {
        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty && trimmedText != lastSavedText {
            saveMemo()
        }
        dismiss()
    }
    
    private func saveAndStay() {
        saveMemo()
        isKeyboardFocused = false
        lastSavedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
struct TexteditView_Previews: PreviewProvider {
    @State static var sampleMemos = [Memo(day: Date(), content: "미리보기 텍스트")]
    
    static var previews: some View {
        NavigationStack {
            TexteditView(memos: $sampleMemos)
                .navigationTitle("생성 모드")
            
            TexteditView(memos: $sampleMemos, memoToEdit: sampleMemos[0])
                .navigationTitle("수정 모드")
        }
    }
}
