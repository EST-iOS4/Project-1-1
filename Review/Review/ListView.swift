//
//  MainListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//
import SwiftUI

struct Memo: Identifiable {
    let id = UUID()
    let day: Date
    let title: String
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
    
    let memos: [Memo] = [
        Memo(day: Date(), title: "할 일", content: "SwiftUI 공부하기"),
        Memo(day: Date(), title: "장보기", content: "내일 할일"),
        Memo(day: Date(), title: "아이디어", content: "프로젝트 만들기"),
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .leading) {
                Group {
                    switch selectedScreen {
                    case .memoList:
                        List(memos) { memo in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(memo.title)
                                        .font(.system(size: fontSize, weight: .bold))
                                    Spacer()
                                    Text(formatDate(memo.day))
                                        .font(.system(size: fontSize - 4))
                                        .foregroundStyle(.gray)
                                }
                                Text(memo.content)
                                    .font(.system(size: fontSize - 2))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.vertical, 5)
                        }
                        .listStyle(PlainListStyle())
                        .navigationTitle("회고")
                        
                    case .statistics:
                        ChartView()
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
