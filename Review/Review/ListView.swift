//
//  ListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//
//

import SwiftUI
// day와 content를 let에서 var로 변경
// 메모부터 스크린까지 따로 파일을 생성해서 옮기는 것을 제미나이가 추천함...
struct Memo: Identifiable {
    let id = UUID()
    var day: Date
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
// let -> @State private var
    @State private var memos: [Memo] = [
      Memo(day: makeDate(year: 2025, month: 7, day: 1), content: "책 이름 : UI/UX 시작하기"),
      Memo(day: makeDate(year: 2025, month: 7, day: 12), content: "수박, 복숭아, 양파, 아보카도"),
      Memo(day: makeDate(year: 2025, month: 7, day: 31), content: "프로젝트 UI 생각하기"),
      Memo(day: makeDate(year: 2025, month: 8, day: 5), content: "SwiftUI 공부하기"),
      Memo(day: makeDate(year: 2025, month: 8, day: 10), content: "백준 알고리즘 풀기"),
      Memo(day: makeDate(year: 2025, month: 8, day: 12), content: "프로젝트 만들기")
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                Group {
                  switch selectedScreen {
                  case .memoList:
                    List(memos) { memo in
                      NavigationLink {
                        TexteditView(memos: $memos, memoToEdit: memo)
                      } label: {
                        VStack(alignment: .leading) {
                          HStack {
                            Spacer()
                            Text(formatDate(memo.day))
                              .font(.system(size: fontSize - 4))
                              .foregroundStyle(.gray)
                          }
                          Text(memo.content)
                            .font(.system(size: fontSize - 2))
                            .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 5)
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !showMenu {
                            Button(action: {
                                withAnimation {
                                    showMenu.toggle()
                                }
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
                            withAnimation {
                                showMenu = false
                            }
                        }

                    SidebarView(selectedScreen: $selectedScreen, showMenu: $showMenu)
                        .frame(width: UIScreen.main.bounds.width * 7 / 9)
                        .background(Color.white)
                        .offset(x: showMenu ? 0 : -UIScreen.main.bounds.width * 7 / 9)
                        .animation(.easeInOut, value: showMenu)
                }
            }
        }
        // 다크모드 실시간 반영
        .preferredColorScheme(isDarkMode ? .dark : .light)
      
      
    }
}

#Preview {
    ListView()
}


