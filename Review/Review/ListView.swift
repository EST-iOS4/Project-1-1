//
//  ListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

extension Date {
    static let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy. MM. dd"
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
    
    // title추가 필요
    @State private var memos: [Memo] = [
        Memo(
            day: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            tags: ["독서", "UI/UX"], content: "책 이름 : UI/UX 시작하기"
        ),
        Memo(
            day: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            tags: ["과일", ""], content: "수박, 복숭아, 양파, 아보카도"
        ),
        Memo(
            day: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            tags: ["할 일", ""], content: "프로젝트 UI 생각하기"
        ),
        Memo(
            day: Calendar.current.date(byAdding: .day, value: -9, to: Date())!,
            tags: ["할 일", ""], content: "SwiftUI 공부하기"
        ),
        Memo(
            day: Calendar.current.date(byAdding: .day, value: -16, to: Date())!,
            tags: ["할 일", ""], content: "백준 알고리즘 풀기"
        ),
        Memo(
            day: Calendar.current.date(byAdding: .day, value: -18, to: Date())!,
            tags: ["할 일", ""], content: "프로젝트 만들기"
        ),
    ]
    
    var memoDates: Set<Date> {
        let calendar = Calendar.current
        return Set(memos.map { calendar.startOfDay(for: $0.day) })
    }
    
    var memoTags: [String: Int] {
        let tags = memos.flatMap { $0.tags }.filter { !$0.isEmpty }
        var counts: [String: Int] = [:]
        for tag in tags {
            counts[tag, default: 0] += 1
        }
        return counts
    }
    
    private var memoListTab: some View {
        NavigationStack {
            List {
                ForEach(memos) { memo in
                    NavigationLink {
                        TexteditView(memos: $memos, memoToEdit: memo)
                    } label: {
                        MemoRowView(memo: memo, fontSize: fontSize)
                    }
                }
                .onDelete(perform: deleteMemo)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("회고")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        TexteditView(memos: $memos)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                    }
                }
            }
        }
    }
    
    private var statisticsTab: some View {
        NavigationStack {
            ChartView(markedDates: memoDates, countTags: memoTags)
                .navigationTitle("통계")
        }
    }
    
    private var settingsTab: some View {
        NavigationStack {
            SettingView()
                .navigationTitle("설정")
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            memoListTab
                .tabItem {
                    Label("회고목록", systemImage: "list.bullet")
                }
                .tag(Screen.memoList)
            
            statisticsTab
                .tabItem {
                    Label("통계", systemImage: "chart.bar")
                }
                .tag(Screen.statistics)
            
            settingsTab
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
                .tag(Screen.settings)
        }
        .preferredColorScheme(nil)
    }
    
    private func deleteMemo(at offsets: IndexSet) {
        memos.remove(atOffsets: offsets)
    }
}

struct MemoRowView: View {
    let memo: Memo
    let fontSize: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !memo.tags.allSatisfy({ $0.isEmpty }) {
                HStack {
                    ForEach(memo.tags.filter { !$0.isEmpty }, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: fontSize - 7)
                                .weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Capsule().fill(Color.blue))
                    }
                }
            }
            Text(memo.content) //제목
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            HStack {
                Spacer()
              Text(memo.day.toYYYYMMDD())
                    .font(.system(size: fontSize - 7))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    ListView()
        .environmentObject(TagStore())
}
