//
//  ListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//
//

import SwiftUI

struct Memo: Identifiable {
  let id = UUID()
  var day: Date
  var tags: [String]
  var content: String
}

func formatDate(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter.string(from: date)
}

enum Screen {
  case memoList
  case statistics
  case settings
}

struct ListView: View {
  @EnvironmentObject var tagStore: TagStore
  @State private var selectedScreen: Screen = .memoList
  @State private var showMenu = false
  
  @AppStorage("isDarkMode") var isDarkMode = false
  @AppStorage("fontSize") var fontSize: Double = 16
  
  static func makeDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
  }
  @State private var memos: [Memo] = [
    Memo(
      day: Self.makeDate(year: 2025, month: 7, day: 1),
      tags: ["독서", "UI/UX"], content: "책 이름 : UI/UX 시작하기"
    ),
    Memo(
      day: Self.makeDate(year: 2025, month: 7, day: 12),
      tags: ["과일", ""], content: "수박, 복숭아, 양파, 아보카도"
    ),
    Memo(
      day: Self.makeDate(year: 2025, month: 7, day: 31),
      tags: ["할 일", ""], content: "프로젝트 UI 생각하기"
    ),
    Memo(
      day: Self.makeDate(year: 2025, month: 8, day: 5),
      tags: ["할 일", ""], content: "SwiftUI 공부하기"
    ),
    Memo(
      day: Self.makeDate(year: 2025, month: 8, day: 10),
      tags: ["할 일", ""], content: "백준 알고리즘 풀기"
    ),
    Memo(
      day: Self.makeDate(year: 2025, month: 8, day: 12),
      tags: ["할 일", ""], content: "프로젝트 만들기"
    ),
  ]
  
  var body: some View {
    NavigationStack {  //Na
      ZStack(alignment: .leading) {  //ZS
        mainContentView
          .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
              if !showMenu {
                Button(action: {
                    showMenu.toggle()
                }) {
                  Image(systemName: "line.horizontal.3")
                    .imageScale(.large)
                }
              }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
              NavigationLink {
                TexteditView(memos: $memos)
              } label: {
                Image(systemName: "plus")
              }
            }
          }
        if showMenu {
          Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                showMenu = false
            }
          
          SidebarView(selectedScreen: $selectedScreen, showMenu: $showMenu)
            .frame(width: UIScreen.main.bounds.width * 7 / 9)
            .background(Color.white)
            .offset(x: showMenu ? 0 : -UIScreen.main.bounds.width * 7 / 9)
        }
      }
      .preferredColorScheme(isDarkMode ? .dark : .light)
    }
  }
  @ViewBuilder
  private var mainContentView: some View {
    Group {
      switch selectedScreen {
      case .memoList:
        List(memos) { memo in
          NavigationLink {
            TexteditView(memos: $memos, memoToEdit: memo)
          } label: {
            VStack(alignment: .leading, spacing: 8) {
              if !memo.tags.allSatisfy({ $0.isEmpty }) {
                HStack {
                  ForEach(memo.tags.filter { !$0.isEmpty }, id: \.self) { tag in
                    Text(tag)
                      .font(.caption).fontWeight(.bold)
                      .padding(.horizontal, 10).padding(.vertical, 4)
                      .foregroundStyle(.white)
                      .background(Capsule().fill(Color.blue))
                  }
                }
              }
              Text(memo.content)
                .font(.system(size: fontSize - 2))
                .foregroundStyle(.primary)
              HStack {
                Spacer()
                Text(formatDate(memo.day))
                  .font(.system(size: fontSize - 4))
                  .foregroundStyle(.gray)
              }
            }
            .padding(.vertical, 5)
          }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("회고")
        
      case .statistics:
        ChartView(
          markedDates: Set(
            memos.map { Calendar.current.startOfDay(for: $0.day) }
          )
        )
        //                      ChartView(markedDates: Set(memos.map { Calendar.current.startOfDay(for: $0.day) }))
        .navigationTitle("통계")
        
      case .settings:
        SettingView()
          .navigationTitle("설정")
      }
    }
  }
}

#Preview {
    ListView()
        .environmentObject(TagStore())
}
