//
//  ListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

// 날짜 표기 유틸 (yyyy. MM. dd)
extension Date {
    static let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter
    }()
    
    func toYYYYMMDD() -> String {
        Date.yyyyMMddFormatter.string(from: self)
    }
}

struct ListView: View {
    @EnvironmentObject var tagStore: TagStore
    @State private var selectedTab: Screen = .memoList
    
    @AppStorage("fontSize") var fontSize: Double = 20
    
    // 실제 앱에선 persistence/Store로 교체
    @State private var memos: [Memo] =
    DummyData.generateRandomInYears(startYear: 2022, endYear: 2025, total: 500)
    
    //검색 상태
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    
    
    // 달력 체크용 날짜 집합 (startOfDay)
    private var memoDates: Set<Date> {
        let cal = Calendar.current
        return Set(memos.map { cal.startOfDay(for: $0.day) })
    }
    
    // 태그 개수 집계
    private var memoTags: [String: Int] {
        let tags = memos.flatMap { $0.tags }.filter { !$0.isEmpty }
        var counts: [String: Int] = [:]
        for tag in tags { counts[tag, default: 0] += 1 }
        return counts
    }
    
    // 날짜별 메모 작성 건수
    private var memoCountsByDay: [Date: Int] {
        let cal = Calendar.current
        return Dictionary(grouping: memos, by: { cal.startOfDay(for: $0.day) })
            .mapValues { $0.count }
    }
    
    // 검색 필터된 메모 목록
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
        // ✅ 외부(ChartView 등) 변경 수신 → 즉시 최신 배열로 교체(정렬 적용)
        .onReceive(NotificationCenter.default.publisher(for: .memosDidChange)) { note in
            if let latest = note.userInfo?["memos"] as? [Memo] {
                self.memos = sortedMemos(latest)
            } else {
                // 필요 시: Store/파일에서 재로딩 후 정렬해서 대입
                // self.memos = sortedMemos(MemoStore.shared.memos)
            }
        }
        // ✅ 이 화면에서 memos가 바뀌면(추가/수정/삭제)
        //  - 화면 표시용 정렬은 ForEach에서 항상 해주므로 상태를 다시 대입하지 않음(무한 루프 방지)
        //  - 공용 브로드캐스트만 보냄(ChartView 등과 동기화)
        .onChange(of: memos) { latest in
            postMemosDidChange(sortedMemos(latest))
        }
        // ✅ 초기 진입 시에도 현재 배열을 먼저 방송 → 통계 탭이 즉시 최신 데이터 수신
        .onAppear {
            postMemosDidChange(sortedMemos(memos))
        }
    }
    
    // MARK: - Tabs
    
    private var memoListTab: some View {
        NavigationStack {
            List {
                // ✅ 항상 filteredMemos 사용
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
                        // ✅ 검색 버튼
                        Button {
                            withAnimation {
                                isSearching.toggle()
                                if !isSearching { searchText = "" } // 닫으면 초기화
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                        }
                        
                        // ✅ 새 메모 버튼
                        NavigationLink {
                            TexteditView(memos: $memos)
                        } label: {
                            Image(systemName: "plus").font(.title2)
                        }
                    }
                }
            }
            // ✅ iOS 15+ search 기능
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
    
    // MARK: - Actions
    
    private func deleteMemo(at offsets: IndexSet) {
        memos.remove(atOffsets: offsets)
    }
    
    // ✅ 날짜 내림차순 정렬(최신이 위). 동일 날짜면 id로 안정 정렬.
    private func sortedMemos(_ arr: [Memo]) -> [Memo] {
        arr.sorted { l, r in
            if l.day != r.day { return l.day > r.day }
            return l.id.uuidString < r.id.uuidString
        }
    }
    
    // ✅ 공용 브로드캐스트 (ChartView.swift의 Notification.Name.memosDidChange 사용)
    private func postMemosDidChange(_ payload: [Memo]) {
        NotificationCenter.default.post(
            name: .memosDidChange,
            object: nil,
            userInfo: ["memos": payload]
        )
    }
}

// MARK: - Row

struct MemoRowView: View {
    let memo: Memo
    let fontSize: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 태그 뱃지
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
            
            // 제목 / 내용 요약
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

// MARK: - Preview

#Preview {
    ListView()
        .environmentObject(TagStore())
}
