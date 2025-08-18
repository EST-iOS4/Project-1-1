import SwiftUI

struct SettingView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage("fontSize") var fontSize: Double = 20
    @AppStorage("userName") var userName: String = ""
    @AppStorage("profileImageData") var profileImageData: Data?
    
    @State private var showImagePicker = false
    @State private var isEditingName = false
    @State private var inputImage: UIImage?
    @State private var showResetAlert = false
    @FocusState private var isNameFocused: Bool
    
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
        fontSize = isPad ? 30 : 20
        userName = ""
        profileImageData = nil
    }
    
    var body: some View {
        Form {
            Section(header: Text("프로필").font(.system(size: isPad ? 30 : 20))) {
                VStack(spacing: 12) {
                    // 프로필 이미지 영역
                    Button {
                        showImagePicker = true
                    } label: {
                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(.plain) //반짝이는 애니메이션 제거

                    // 닉네임 영역
                    HStack {
                        if isEditingName {
                            TextField("닉네임 입력", text: $userName, onCommit: {
                                isEditingName = false
                            })
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: fixedFontSize))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .focused($isNameFocused)
                        } else {
                            Text(userName.isEmpty ? "닉네임을 설정하세요" : userName)
                                .font(.system(size: fixedFontSize, weight: .bold))
                                .foregroundStyle(userName.isEmpty ? .secondary : .primary)
                                .onTapGesture {
                                    isEditingName = true
                                    isNameFocused = true
                                }
                        }

                        if !isEditingName {
                            Button {
                                isEditingName = true
                                isNameFocused = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            
            Section(header: Text("화면 설정").font(.system(size: isPad ? 30 : 20))) {
                HStack {
                    Label("글꼴 크기", systemImage: "textformat.size")
                        .font(.system(size: fixedFontSize))
                    Slider(value: $fontSize, in: isPad ? 20...50 : 15...30, step: 1)
                        .frame(height: isPad ? 40 : 20)
                    Text("\(Int(fontSize))pt")
                        .frame(width: horizontalSizeClass == .regular ? 100 : 60)
                        .font(.system(size: fixedFontSize))
                }
                .frame(height: rowHeight)
                .padding(.vertical, isPad ? 10 : 5)
                
                Text("텍스트 크기입니다.")
                    .font(.system(size: fontSize))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
            
            Section(header: Text("앱 정보").font(.system(size: isPad ? 30 : 20))) {
                            Button {
                                showResetAlert = true
                            } label: {
                                Label("프로필 및 화면 설정 초기화", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: fixedFontSize))
                            }
                            .foregroundStyle(.red)
                            .frame(height: rowHeight)
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $inputImage)
                            .onDisappear {
                                if let inputImage = inputImage {
                                    profileImageData = inputImage.jpegData(compressionQuality: 0.8)
                                }
                            }
                    }
                    .alert("설정을 초기화하시겠습니까?", isPresented: $showResetAlert) {
                        Button("취소", role: .cancel) {}
                        Button("확인", role: .destructive) {
                            resetSettings()
                        }
                    } message: {
                        Text("폰트 크기, 닉네임, 프로필 이미지가 초기값으로 돌아갑니다.")
                    }
                }
            }


#Preview {
    SettingView()
}
