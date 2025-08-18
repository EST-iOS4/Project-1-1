//
//  ChartViewComponent.swift
//  Review
//
//  Created by 송영민 on 8/18/25.
//

import SwiftUI

struct ListView: View {
  @EnvironmentObject var tagStore: TagStore
  @State private var selectedTab: Screen = .memoList
  @AppStorage("fontSize") var fontSize: Double = 20

  @State private var memos: [Memo] = {
    let random480 = DummyData.generateRandomInYears(startYear: 2022, endYear: 2025, total: 480)
    let last7days20 = DummyData.generateFromYesterday(days: 6, total: 20)
    return DummyData.composeDemoArrays(random480 + last7days20)
  }()

  @State private var isSearching: Bool = false
  @State private var searchText: String = ""

  private var memoDates: Set<Date> {
    let cal = Calendar.current
    return Set(memos.map { cal.startOfDay(for: $0.day) })
  }

  private var memoTags: [String: Int] {
    let tags = memos.flatMap { $0.tags }.filter { !$0.isEmpty }
    var counts: [String: Int] = [:]
    for tag in tags { counts[tag, default: 0] += 1 }
    return counts
  }

  private var memoCountsByDay: [Date: Int] {
    let cal = Calendar.current
    return Dictionary(grouping: memos, by: { cal.startOfDay(for: $0.day) })
      .mapValues { $0.count }
  }

  private var filteredMemos: [Memo] {
    if searchText.isEmpty {
      return sortedMemos(memos)
    } else {
      return sortedMemos(memos).filter { memo in
        let keyword = searchText.lowercased()
        return memo.title.lowercased().contains(keyword)
        || memo.content.lowercased().contains(keyword)
        || memo.tags.contains { $0.lowercased().contains(keyword) }
      }
    }
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      memoListTab
        .tabItem { Label("회고목록", systemImage: "list.bullet") }
        .tag(Screen.memoList)

      statisticsTab
        .tabItem { Label("통계", systemImage: "chart.bar") }
        .tag(Screen.statistics)

      settingsTab
        .tabItem { Label("설정", systemImage: "gearshape") }
        .tag(Screen.settings)
    }
    .onReceive(NotificationCenter.default.publisher(for: .memosDidChange)) { note in
      if let latest = note.userInfo?["memos"] as? [Memo] {
        self.memos = sortedMemos(latest)
      }
    }
    .onChange(of: memos) { latest in
      postMemosDidChange(sortedMemos(latest))
    }
    .onAppear {
      postMemosDidChange(sortedMemos(memos))
    }
  }

  private var memoListTab: some View {
    NavigationStack {
      List {
        ForEach(filteredMemos) { memo in
          NavigationLink {
            TexteditView(memos: $memos, memoToEdit: memo)
          } label: {
            MemoRowView(memo: memo, fontSize: fontSize)
          }
        }
        .onDelete(perform: deleteMemo)
      }
      .listStyle(.plain)
      .navigationTitle("회고")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          HStack {
            Button {
              withAnimation {
                isSearching.toggle()
                if !isSearching { searchText = "" }
              }
            } label: {
              Image(systemName: "magnifyingglass")
                .font(.title2)
            }
            NavigationLink {
              TexteditView(memos: $memos)
            } label: {
              Image(systemName: "plus").font(.title2)
            }
          }
        }
      }
      .searchable(text: $searchText, isPresented: $isSearching, prompt: "회고를 검색해보세요.")
    }
  }

  private var statisticsTab: some View {
    NavigationStack {
      ChartView(
        markedDates: memoDates,
        countTags: memoTags,
        dayCounts: memoCountsByDay,
        memos: memos
      )
      .navigationTitle("통계")
    }
  }

  private var settingsTab: some View {
    NavigationStack {
      SettingView()
        .navigationTitle("설정")
    }
  }

  private func deleteMemo(at offsets: IndexSet) {
    memos.remove(atOffsets: offsets)
  }

  private func sortedMemos(_ arr: [Memo]) -> [Memo] {
    arr.sorted { l, r in
      if l.day != r.day { return l.day > r.day }
      return l.id.uuidString < r.id.uuidString
    }
  }

  private func postMemosDidChange(_ payload: [Memo]) {
    NotificationCenter.default.post(
      name: .memosDidChange,
      object: nil,
      userInfo: ["memos": payload]
    )
  }
}

struct MemoRowView: View {
  let memo: Memo
  let fontSize: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      let visibleTags = memo.tags.filter { !$0.isEmpty }
      if !visibleTags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 6) {
            ForEach(visibleTags, id: \.self) { tag in
              Text(tag)
                .font(.system(size: max(fontSize - 7, 10), weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.blue))
            }
          }
        }
      }
      Text(memo.title)
        .font(.system(size: fontSize + 2, weight: .bold))
        .foregroundStyle(.primary)
        .lineLimit(1)
      Text(memo.content)
        .font(.system(size: max(fontSize - 5, 10)))
        .foregroundStyle(.primary)
        .lineLimit(1)
      HStack {
        Spacer()
        Text(memo.day.toYYYYMMDD())
          .font(.system(size: max(fontSize - 7, 9)))
          .foregroundStyle(.gray)
      }
    }
    .padding(.vertical, 6)
  }
}

#Preview {
  ListView()
    .environmentObject(TagStore())
}
