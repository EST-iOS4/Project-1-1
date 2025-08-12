import SwiftUI

struct SettingView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("fontSize") var fontSize: Double = 16
    @AppStorage("userName") var userName: String = ""
    
    var isPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var fixedFontSize: Double {
        isPad ? 30 : 20
    }

    var rowHeight: Double {
        isPad ? 60 : 44
    }
    
    func resetSettings() {
        isDarkMode = false
        fontSize = isPad ? 30 : 20
    }
    
    var body: some View {
        Form {
            Section(header: Text("화면 설정").font(.system(size: isPad ? 30 : 20))) {
                
                HStack {
                    Label("이름: ", systemImage: "person.fill")
                        .font(.system(size: fixedFontSize))
                    TextField("이름을 입력하세요", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: fixedFontSize))
                }
                .frame(height: rowHeight)
                .padding(.top, isPad ? 20 : 5)
                
                Toggle(isOn: $isDarkMode) {
                    Label("다크 모드", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: fixedFontSize))
                }
                .frame(height: rowHeight)
                
                HStack {
                    Label("글꼴 크기", systemImage: "textformat.size")
                        .font(.system(size: fixedFontSize))
                    Slider(value: $fontSize, in: isPad ? 20...50 : 15...30, step: 1)
                        .frame(height: isPad ? 40 : 20)
                    Text("\(Int(fontSize))pt")
                        .frame(width: horizontalSizeClass == .regular ? 100 : 60)
                        .font(.system(size: fixedFontSize))  // 고정 크기 유지
                }
                .frame(height: rowHeight)
                .padding(.vertical, isPad ? 10 : 5)
                
                Text("텍스트 크기입니다.")
                    .font(.system(size: fontSize))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
            
            Section(header: Text("앱 정보").font(.system(size: isPad ? 30 : 20))) {
                Button(action: resetSettings) {
                    Label("설정 초기화", systemImage: "arrow.counterclockwise")
                        .font(.system(size: fixedFontSize))
                }
                .foregroundStyle(.red)
                .frame(height: rowHeight)
            }
        }
    }
}

#Preview {
    SettingView()
}
