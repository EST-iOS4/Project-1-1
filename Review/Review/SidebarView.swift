//
//  Sidebar.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedScreen: Screen
    @Binding var showMenu: Bool
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(userName.isEmpty ? "안녕하세요!" : "안녕하세요 \(userName) 님!") // 사용자 이름
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            Divider()
            
            sidebarButton(
                title: "회고 목록",
                systemImage: "list.bullet",
                screen: .memoList
            )
            
            sidebarButton(
                title: "통계",
                systemImage: "chart.bar",
                screen: .statistics
            )
            
            sidebarButton(
                title: "설정",
                systemImage: "gearshape",
                screen: .settings
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private func sidebarButton(title: String, systemImage: String, screen: Screen) -> some View {
        Button(action: {
            selectedScreen = screen
            withAnimation {
                showMenu = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    SidebarView(selectedScreen: .constant(.memoList), showMenu: .constant(true))
}
