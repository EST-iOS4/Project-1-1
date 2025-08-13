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
  
  enum FocusField {
    case tag, content
  }
  
  @EnvironmentObject var tagStore: TagStore
  @Environment(\.dismiss) var dismiss
  
  @Binding var memos: [Memo]
  
  @State private var addedTags: [String]
  @State private var currentTagInput: String = ""
  @State private var reviewText: String
  
  @State private var isEditMode: Bool
  @State var memoToEdit: Memo?
  @FocusState private var focusedField: FocusField?
  
  @State private var savedReviewText: String
  @State private var savedAddedTags: [String]
  
  @AppStorage("fontSize") var fontSize: Double = 16
  
  // MARK: - Computed Properties
  
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
    // 복잡한 ZStack을 제거하고 ScrollView와 VStack의 단순한 구조로 변경
    ScrollView {
      VStack(spacing: 15) {
        tagInputSection
        memoContentSection
      }
      .padding(.top)
    }
    .scrollDismissesKeyboard(.interactively)
    .navigationTitle(isEditMode ? "회고 수정" : "회고 작성")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button { dismiss() } label: { Image(systemName: "chevron.backward") }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("저장") { saveMemoAndDismissFocus() }
          .disabled((reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && addedTags.isEmpty) || !isContentChanged)
      }
      // 키보드 위에 '완료' 버튼을 추가
      ToolbarItem(placement: .keyboard) {
        HStack {
          Spacer()
          Button("완료") {
            focusedField = nil
          }
        }
      }
    }
    .navigationBarBackButtonHidden(true)
    .animation(.default, value: focusedField)
  }
  
  // MARK: - Child Views
  
  private var tagInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !addedTags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ForEach(addedTags, id: \.self) { tag in
              TagPill(label: tag, onDelete: {
                addedTags.removeAll { $0 == tag }
              }, fontSize: fontSize)
            }
          }
        }
        .frame(maxHeight: 32)
      }
      
      TextField("태그 추가 (쉼표 또는 Return으로 입력)", text: $currentTagInput)
        .font(.system(size: fontSize))
        .padding(10)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .focused($focusedField, equals: .tag)
        .onSubmit(addTagFromSubmit)
        .onChange(of: currentTagInput) { _, newValue in
          if newValue.contains(",") {
            addTag(fromString: newValue.replacingOccurrences(of: ",", with: ""))
          }
        }
      
      if focusedField == .tag {
        tagSuggestionView
      }
    }
    .padding(.horizontal)
  }
  
  private var memoContentSection: some View {
    TextEditor(text: $reviewText)
      .font(.system(size: fontSize))
      .scrollContentBackground(.hidden)
      .frame(minHeight: 300)
      .focused($focusedField, equals: .content)
      .padding(8)
      .background(Color(uiColor: .systemGray6))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.5), lineWidth: 1)
      )
      .overlay(alignment: .topLeading) {
        if reviewText.isEmpty {
          Text("회고를 작성하세요...")
            .font(.system(size: fontSize))
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
          .font(.system(size: fontSize))
          .font(.callout)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 20)
      } else {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(tagSuggestions, id: \.self) { suggestion in
            HStack {
              Text(suggestion)
                .font(.system(size: fontSize))
                .padding(.vertical, 4)
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
    
    if isEditMode, let memoToEditID = memoToEdit?.id, let index = memos.firstIndex(where: { $0.id == memoToEditID }) {
      memos[index].content = trimmedText
      memos[index].tags = addedTags
      memos[index].day = Date()
    } else {
      if !trimmedText.isEmpty || !addedTags.isEmpty {
        let newMemo = Memo(id: UUID(), day: Date(), tags: addedTags, content: trimmedText)
        memos.insert(newMemo, at: 0)
        
        self.memoToEdit = newMemo
        self.isEditMode = true
      }
    }
    
    savedReviewText = trimmedText
    savedAddedTags = addedTags
  }
  
  private func saveMemoAndDismissFocus() {
    saveMemo()
    focusedField = nil
  }
}

// MARK: - Reusable TagPill View

struct TagPill: View {
  let label: String
  let onDelete: () -> Void
  let fontSize: Double
  
  var body: some View {
    HStack(spacing: 4) {
      Text(label)
        .font(.system(size: fontSize * 0.8))
      Image(systemName: "xmark")
        .font(.system(size: fontSize * 0.6).weight(.bold))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Capsule().fill(Color.accentColor))
    .foregroundStyle(.white)
    .onTapGesture(perform: onDelete)
  }
}
