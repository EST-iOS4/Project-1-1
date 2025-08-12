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
    @AppStorage("fontSize") var fontSize: Double = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(userName.isEmpty ? "안녕하세요!" : "안녕하세요 \(userName) 님!") // 사용자 이름
                .font(.system(size: fontSize))
                .bold()
                .padding(.top, 30)
                .padding(.bottom, 10)
                .foregroundStyle(.primary)
            
            Divider()
                .background(Color.primary.opacity(0.3))
            
            SidebarButton(title: "회고 목록", systemImage: "list.bullet", fontSize: fontSize, isSelected: selectedScreen == .memoList) {
                selectedScreen = .memoList
                showMenu = false
            }
            
            SidebarButton(title: "통계", systemImage: "chart.bar", fontSize: fontSize, isSelected: selectedScreen == .statistics) {
                selectedScreen = .statistics
                showMenu = false
            }
            
            SidebarButton(title: "설정", systemImage: "gearshape", fontSize: fontSize, isSelected: selectedScreen == .settings) {
                selectedScreen = .settings
                showMenu = false
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
    }
}
    
struct SidebarButton: View {
    let title: String
    let systemImage: String
    let fontSize: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: fontSize))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(size: fontSize))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(nil, value: isSelected)
    }
}
#Preview {
    SidebarView(selectedScreen: .constant(.memoList), showMenu: .constant(true))
}
