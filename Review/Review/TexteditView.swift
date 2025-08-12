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
    
    @Binding var reviews: [Memo]
    
    @State private var selectedDate: Date = Date()
    @State private var reviewText: String = ""
    
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        VStack {
            DatePicker(
                "날짜 선택",
                selection: $selectedDate,
                displayedComponents: .date
            )
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
                        .padding()
                        .padding(.top, 8)
                        .padding(.leading, 5)
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
                    saveAndDismissKeyboard()
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
        if !trimmedText.isEmpty {
            let newMemo = Memo(day: selectedDate, content: trimmedText)
            reviews.append(newMemo)
        }
    }
    
    private func handleBackAction() {
        saveMemo()
        dismiss()
    }
    
    private func saveAndDismissKeyboard() {
        saveMemo()
        isKeyboardFocused = false
        dismiss()
    }
}

struct TexteditView_Previews: PreviewProvider {
    @State static var sampleReviews = [
        Memo(day: Date(), content: "미리보기 텍스트")
    ]
    
    static var previews: some View {
        NavigationStack {
            TexteditView(reviews: $sampleReviews)
        }
    }
}
