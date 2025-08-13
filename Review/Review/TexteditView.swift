//
// TexteditView.swift
// Review
//
//  Created by 남병수 on 8/11/25.
//
//

import SwiftUI

struct TexteditView: View {
  // MARK: - Properties
  @EnvironmentObject var tagStore: TagStore
  @Environment(\.dismiss) var dismiss
  
  @Binding var memos: [Memo]
  
  @State var memoToEdit: Memo?
  @State private var addedTags: [String]
  @State private var currentTagInput: String = ""
  @State private var reviewText: String
  @State private var isEditMode: Bool
  @FocusState private var isTagInputFocused: Bool
  @State private var savedReviewText: String
  @State private var savedAddedTags: [String]
  
  private var tagSuggestions: [String] {
    if currentTagInput.isEmpty {
      return tagStore.allTags.filter { !addedTags.contains($0) }
    } else {
      return tagStore.allTags.filter {
        $0.lowercased().contains(currentTagInput.lowercased()) && !addedTags.contains($0)
      }
    }
  }
  
  private var isContentChanged: Bool {
    return reviewText != savedReviewText || addedTags != savedAddedTags
  }
  
  // MARK: - Initializer
  init(memos: Binding<[Memo]>, memoToEdit: Memo? = nil) {
    self._memos = memos
    self._memoToEdit = State(initialValue: memoToEdit)
    self._isEditMode = State(initialValue: (memoToEdit != nil))
    
    if let memo = memoToEdit {
      let initialTags = memo.tags.filter { !$0.isEmpty }
      self._addedTags = State(initialValue: initialTags)
      self._reviewText = State(initialValue: memo.content)
      
      self._savedAddedTags = State(initialValue: initialTags)
      self._savedReviewText = State(initialValue: memo.content)
    } else {
      self._addedTags = State(initialValue: [])
      self._reviewText = State(initialValue: "")
      
      self._savedAddedTags = State(initialValue: [])
      self._savedReviewText = State(initialValue: "")
    }
  }
  
  // MARK: - Body
  var body: some View {
    ZStack {
      if isTagInputFocused {
        Color.black.opacity(0.001)
          .ignoresSafeArea()
          .onTapGesture {
            isTagInputFocused = false
          }
          .zIndex(0)
      }
      
      VStack(spacing: 15) {
        tagInputSection
        memoContentSection
        Spacer()
      }
      .padding(.top)
      .zIndex(1)
      
    }
    .navigationTitle(isEditMode ? "회고 수정" : "회고 작성")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button { saveAndDismiss() } label: { Image(systemName: "chevron.backward") }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("완료") { saveMemoAndDismissFocus() }
          .disabled((reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && addedTags.isEmpty) || !isContentChanged)
      }
    }
    .navigationBarBackButtonHidden(true)
    .animation(.default, value: isTagInputFocused)
  }
  
  // MARK: - Child Views
  private var tagInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !addedTags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ForEach(addedTags, id: \.self) { tag in
              TagPill(label: tag) {
                addedTags.removeAll { $0 == tag }
              }
            }
          }
        }
        .frame(maxHeight: 32)
      }
      
      TextField("태그 추가 (쉼표 또는 Return으로 입력)", text: $currentTagInput)
        .textFieldStyle(.roundedBorder)
        .focused($isTagInputFocused)
        .onSubmit(addTagFromSubmit)
        .onChange(of: currentTagInput) { _, newValue in
          if newValue.contains(",") {
            addTag(fromString: newValue.replacingOccurrences(of: ",", with: ""))
          }
        }
      
      if isTagInputFocused {
        tagSuggestionView
      }
    }
    .padding(.horizontal)
  }
  
  private var memoContentSection: some View {
    TextEditor(text: $reviewText)
      .font(.body)
      .scrollContentBackground(.hidden)
      .padding(8)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.5), lineWidth: 1)
      )
      .overlay(alignment: .topLeading) {
        if reviewText.isEmpty {
          Text("회고를 작성하세요...")
            .foregroundColor(.gray.opacity(0.7))
            .padding(16)
            .allowsHitTesting(false)
        }
      }
      .padding(.horizontal)
  }
  
  private var tagSuggestionView: some View {
    ScrollView {
      if tagSuggestions.isEmpty {
        Text("일치하는 태그가 없습니다.")
          .font(.callout)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 20)
      } else {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(tagSuggestions, id: \.self) { suggestion in
            HStack {
              Text(suggestion).padding(.vertical, 4)
              Spacer()
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray.opacity(0.4))
                .onTapGesture {
                  if let indexSet = indexSet(for: suggestion) {
                    tagStore.deleteTag(at: indexSet)
                  }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
              addTag(fromString: suggestion)
            }
            
            if suggestion != tagSuggestions.last {
              Divider().padding(.leading, 15)
            }
          }
        }
      }
    }
    .frame(height: 200)
    .background(Color(uiColor: .systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    )
  }
  
  // MARK: - Functions
  private func addTagFromSubmit() { addTag(fromString: currentTagInput) }
  private func addTag(fromString tag: String) {
    let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedTag.isEmpty && !addedTags.contains(trimmedTag) {
      addedTags.append(trimmedTag)
      tagStore.addTag(trimmedTag)
    }
    currentTagInput = ""
  }
  private func indexSet(for tag: String) -> IndexSet? {
    if let index = tagStore.allTags.firstIndex(of: tag) { return IndexSet(integer: index) }
    return nil
  }
  
  private func saveMemo() {
    let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
    tagStore.addTags(addedTags)
    
    if isEditMode {
      if let memoToEdit = memoToEdit, let index = memos.firstIndex(where: { $0.id == memoToEdit.id }) {
        memos[index].content = trimmedText
        memos[index].tags = addedTags
      }
    } else {
      if !trimmedText.isEmpty || !addedTags.isEmpty {
        let newMemo = Memo(day: Date(), tags: addedTags, content: trimmedText)
        memos.append(newMemo)
        
        self.memoToEdit = newMemo
        self.isEditMode = true
      }
    }
    savedReviewText = trimmedText
    savedAddedTags = addedTags
  }
  
  private func saveAndDismiss() {
    saveMemo()
    dismiss()
  }
  
  private func saveMemoAndDismissFocus() {
    saveMemo()
    isTagInputFocused = false
  }
}

// MARK: - Reusable TagPill View
struct TagPill: View {
  let label: String
  let onDelete: () -> Void
  var body: some View {
    HStack(spacing: 4) {
      Text(label); Image(systemName: "xmark").font(.caption.weight(.bold))
    }
    .font(.caption).padding(.horizontal, 10).padding(.vertical, 5)
    .background(Capsule().fill(Color.accentColor)).foregroundStyle(.white)
    .onTapGesture(perform: onDelete)
  }
}
