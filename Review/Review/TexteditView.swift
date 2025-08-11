//
//  TexteditView.swift
//  Review
//
//  Created by 남병수 on 8/11/25.
//

import SwiftUI

struct TexteditView: View {
    @Environment(\.dismiss) var dismiss

    // ListView의 memos 배열과 연결할 바인딩 변수
    @Binding var reviews: [Memo]

    @State private var reviewText: String = ""
    @FocusState private var isKeyboardFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $reviewText)
                .scrollContentBackground(.hidden)
                .padding()
                .focused($isKeyboardFocused)

            if reviewText.isEmpty {
                Text("회고 작성.")
                    .font(.body)
                    .foregroundColor(.gray.opacity(0.7))
                    .padding()
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .navigationTitle("회고 작성")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    handleBackAction()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    isKeyboardFocused = false
                }
                .disabled(reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func handleBackAction() {
        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            // 수정된 Memo 구조체에 맞게 text만 전달하여 객체 생성
            reviews.append(Memo(text: trimmedText))
        }
        dismiss()
    }
}

// 기존 #Preview { ... } 전체 삭제하고 아래로 교체
struct TexteditView_Previews: PreviewProvider {
    @State static var sampleReviews = [Memo(text: "미리보기 텍스트")]

    static var previews: some View {
        NavigationStack {
            TexteditView(reviews: $sampleReviews)
        }
    }
}
