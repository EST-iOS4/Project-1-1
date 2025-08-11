//
//  MainListView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//
// 1

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

struct ListView: View {
  let memos: [Memo] = [
    Memo(day: Date(), title: "할 일", content: "SwiftUI 공부하기"),
    Memo(day: Date(), title: "장보기", content: "내일 할일"),
    Memo(day: Date(), title: "아이디어", content: "프로젝트 만들기"),
  ] // 텍스트 에딧 뷰에서 입력 받은걸 <

  @State private var showMenu = false

  var body: some View {
    NavigationView {
      ZStack(alignment: .leading) {
        List(memos) { memo in
          VStack(alignment: .leading) {
            HStack {
              Text(memo.title)
                .font(.headline)
              Spacer()
              Text(formatDate(memo.day))
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            Text(memo.content)
              .font(.subheadline)
              .foregroundColor(.gray)
          }
          .padding(.vertical, 5)
        }
        .listStyle(PlainListStyle())
        .navigationTitle("회고")
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            if !showMenu {        // 메뉴가 안 뜰 때만 버튼 보이게
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

          SidebarView()
            .frame(width: UIScreen.main.bounds.width * 2 / 3)
            .background(Color.white)
            .offset(x: showMenu ? 0 : -UIScreen.main.bounds.width * 2 / 3)
            .animation(.easeInOut, value: showMenu)
        }
      }
    }
  }
}

#Preview {
  ListView()
}
