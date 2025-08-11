//
//  Sidebar.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

struct SidebarView: View {
    var body: some View {
      VStack(alignment: .leading) {
            Text("이름") // 이름 넣기
              .font(.title2)
              .padding(.top, 40)
              .padding(.bottom, 20)
            Divider()
            Button("회고 목록") {}
              .padding(.vertical, 10)
            Button("통계") {}
              .padding(.vertical, 10)
            Button("설정") {}
              .padding(.vertical, 10)
            Spacer()
          }
          .padding(.horizontal, 20)
        }
}

#Preview {
    SidebarView()
}
