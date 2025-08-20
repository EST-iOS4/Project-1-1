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
    case title, tag, content
  }
  
  @EnvironmentObject var tagStore: TagStore
  @Environment(\.dismiss) var dismiss
  
  @Binding var memos: [Memo]
  
  @State private var titleText: String = ""
  @State private var addedTags: [String]
  @State private var currentTagInput: String = ""
  @State private var reviewText: String
  
  @State private var isEditMode: Bool
  @State var memoToEdit: Memo?
  @FocusState private var focusedField: FocusField?
  
  @State private var savedTitleText: String
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
          return titleText != savedTitleText || reviewText != savedReviewText || addedTags != savedAddedTags
      }
  
  // MARK: - Initializer

  init(memos: Binding<[Memo]>, memoToEdit: Memo? = nil) {
    self._memos = memos
    self._memoToEdit = State(initialValue: memoToEdit)
    self._isEditMode = State(initialValue: (memoToEdit != nil))
    
    if let memo = memoToEdit {
      // --- 수정 모드일 때 ---
      // 누락된 변수 초기화
      self._titleText = State(initialValue: memo.title)
      self._savedTitleText = State(initialValue: memo.title)
      
      let initialTags = memo.tags.filter { !$0.isEmpty }
      self._addedTags = State(initialValue: initialTags)
      self._reviewText = State(initialValue: memo.content)
      
      self._savedAddedTags = State(initialValue: initialTags)
      self._savedReviewText = State(initialValue: memo.content)
    } else {
      // --- 새 메모 작성 모드일 때 ---
      // 누락된 변수 초기화
      self._titleText = State(initialValue: "")
      self._savedTitleText = State(initialValue: "")
      
      self._addedTags = State(initialValue: [])
      self._reviewText = State(initialValue: "")
      
      self._savedAddedTags = State(initialValue: [])
      self._savedReviewText = State(initialValue: "")
    }
  }
  
  // MARK: - Body

  var body: some View {
    VStack(spacing: 15) {
      titleInputSection
      tagInputSection
        .zIndex(1)
      memoContentSection
    }
    .padding(.top)
    .scrollDismissesKeyboard(.interactively) // VStack으로 이동
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
  
  private var titleInputSection: some View {
    TextField("제목", text: $titleText)
      .font(.system(size: fontSize + 2, weight: .bold))
      .padding(10)
      .background(Color(uiColor: .systemGray6))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.2), lineWidth: 1)
      )
      .focused($focusedField, equals: .title)
      .padding(.horizontal)
  }
  
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
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .focused($focusedField, equals: .tag)
        .onSubmit(addTagFromSubmit)
        .onChange(of: currentTagInput) { _, newValue in
          if newValue.contains(",") {
            addTag(fromString: newValue.replacingOccurrences(of: ",", with: ""))
          }
        }
        .overlay(alignment: .topLeading) {
          if focusedField == .tag {
            tagSuggestionView
              .offset(y: 50)
          }
        }
    }
    .padding(.horizontal)
  }
  
  private var memoContentSection: some View {
    TextEditor(text: $reviewText)
      .font(.system(size: fontSize))
      .scrollContentBackground(.hidden)
      .focused($focusedField, equals: .content)
      .padding(8)
      .background(Color(uiColor: .systemGray6))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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
        Button(action: {
          addTag(fromString: currentTagInput)
        }) {
          HStack {
            Text("눌러서 태그 생성:")
              .foregroundStyle(.secondary)
            Text(currentTagInput)
              .fontWeight(.semibold)
              .foregroundStyle(Color.accentColor)
            Spacer()
          }
          .padding(.horizontal, 15)
          .padding(.vertical, 10)
          .background(Color(uiColor: .secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.gray.opacity(0.2), lineWidth: 1)
          )
          .contentShape(Rectangle())
          .padding(10)
        }
        .disabled(currentTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        
      } else {
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(tagSuggestions, id: \.self) { suggestion in
            HStack {
              Text(suggestion)
                .font(.system(size: fontSize - 2))
              Spacer()
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray.opacity(0.4))
                .onTapGesture {
                  if let indexSet = indexSet(for: suggestion) {
                    tagStore.deleteTag(at: indexSet)
                  }
                }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
              addTag(fromString: suggestion)
            }
          }
        }
        .padding(.horizontal)
        .padding(.top, 10)
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
    let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
    tagStore.addTags(addedTags)
    
    if isEditMode, let memoToEditID = memoToEdit?.id, let index = memos.firstIndex(where: { $0.id == memoToEditID }) {
      memos[index].title = trimmedTitle
      memos[index].content = trimmedText
      memos[index].tags = addedTags
      memos[index].day = Date()
    } else {
      if !trimmedTitle.isEmpty {
        let newMemo = Memo(id: UUID(), day: Date(), title: trimmedTitle, tags: addedTags, content: trimmedText)
        memos.insert(newMemo, at: 0)
        
        self.memoToEdit = newMemo
        self.isEditMode = true
      }
    }
    
    savedTitleText = trimmedTitle
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
