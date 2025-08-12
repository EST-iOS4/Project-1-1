//
//  SettingView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("fontSize") var fontSize: Double = 16
    @AppStorage("userName") var userName: String = ""
    
    func resetSettings() {
        isDarkMode = false
        fontSize = 16
    }
    
    var body: some View {
        Form {
            Section(header: Text("화면 설정").font(.system(size: 30))) {
                
                HStack {
                    Label("이름: ", systemImage: "person.fill")
                        .font(.system(size: fontSize))
                    TextField("이름을 입력하세요", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: fontSize))
                    }
                    .padding(.top, 5)
                
                Toggle(isOn: $isDarkMode) {
                    Label("다크 모드", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: fontSize))
                }
                
                HStack {
                    Label("글꼴 크기", systemImage: "textformat.size")
                        .font(.system(size: fontSize))
                    Slider(value: $fontSize, in: 15...30, step: 1) {
                        Text("글꼴 크기")
                    }
                    Text("\(Int(fontSize))pt")
                        .frame(width: 40)
                        .font(.system(size: fontSize))
                }
            }
            
            Section(header: Text("앱 정보")) {
                Button(action: resetSettings) {
                    Label("설정 초기화", systemImage: "arrow.counterclockwise")
                }
                .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    SettingView()
}
