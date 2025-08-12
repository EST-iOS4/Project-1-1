//
//  ListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//
//

import SwiftUI
// 원래 [Memo]에 day, title, content가 아닌 text 프로퍼티 하나만 남기려고 했는데, 다시 생각해보니 일단 day는 남기는게 좋겠다는 생각이 들었습니다. 그런데 회고에 title이 굳이 필요할까? 라는 생각이 들어서 이 부분은 의견을 나누면 좋을 것 같아요. -> "title" x / -> 카테고리or태그 ,
struct Memo: Identifiable {
    let id = UUID()
    let day: Date
    let content: String
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

    let memos: [Memo] = [
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
//                  ToolbarItem(placement: .navigationBarTrailing) {
//                                      NavigationLink {
//                                          TexteditView(reviews: $memos)
//                                      } label: {
//                                          Image(systemName: "plus")
//                                      }
//                                  }
// 이 부분은 플러스 버튼입니다. TexteditView에 변수를 전달하는 코드가 있어서, 위에서 의견을 나누고자 한 부분을 해결한 후 TexteditView를 활성할 때 같이 활성화하면 될 듯합니다.
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


