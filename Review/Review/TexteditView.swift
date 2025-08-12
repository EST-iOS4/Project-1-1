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
    
    @State private var selectedDate: Date
    @State private var reviewText: String
    
    private var isEditMode: Bool
    
    @FocusState private var isKeyboardFocused: Bool

    init(memos: Binding<[Memo]>, memoToEdit: Memo? = nil) {
        self._memos = memos
        self.memoToEdit = memoToEdit
        self.isEditMode = (memoToEdit != nil)
        
        if let memo = memoToEdit {
            self._selectedDate = State(initialValue: memo.day)
            self._reviewText = State(initialValue: memo.content)
        } else {
            self._selectedDate = State(initialValue: Date())
            self._reviewText = State(initialValue: "")
        }
    }
    
    var body: some View {
        VStack {
            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $reviewText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal)
                    .focused($isKeyboardFocused)
                
                if reviewText.isEmpty {
                    Text("회고를 작성하세요...")
                        .font(.body)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding([.top, .leading], 20)
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
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    saveAndDismiss()
                }
                .disabled(reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            isKeyboardFocused = true
        }
    }
    
    private func saveMemo() {
        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let memoToEdit = memoToEdit,
           let index = memos.firstIndex(where: { $0.id == memoToEdit.id }) {
            memos[index].day = selectedDate
            memos[index].content = trimmedText
        } else {
            let newMemo = Memo(day: selectedDate, content: trimmedText)
            memos.append(newMemo)
        }
    }
    
    private func saveAndDismiss() {
        saveMemo()
        dismiss()
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
