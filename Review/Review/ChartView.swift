//
//  ChartView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

class ChartViewModel: ObservableObject {
  @AppStorage("isDarkMode") var isDarkMode = false
  
  let markedDates: Set<Date>
  let countTags: [String: Int]
  
  @Published private var currentMonth: Date = Date()
  
  private let calendar: Calendar = .current
  
  init(markedDates: Set<Date>, countTags: [String: Int] = [:] ) {
    self.markedDates = markedDates
    self.countTags = countTags
  }
  
  // 달 년도 표시
  var monthTitle: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년   M월"
    return formatter.string(from: currentMonth)
  }
  
  // 요일 표시
  var dayWeeks: [String] {
    ["일", "월", "화", "수", "목", "금", "토"]
  }
  
  //
  var arrayMonthDays: [Date?] {
    guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
      let firstDay = calendar.date(
        from: calendar.dateComponents([.year, .month], from: currentMonth)
      )
    else { return [] }

    let firstWeek = calendar.component(.weekday, from: firstDay)
    var days: [Date?] = Array(repeating: nil, count: firstWeek - 1)

    for day in range {
      if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)
      {
        days.append(date)
      }
    }

    //6주로 만들기 (UI변경 없애기 위해 UI위치 고정)
    while days.count < 42 {
      days.append(nil)
    }

    return days
  }
  
  // 달 바꾸기
  func changeMonth(by value: Int) {
    if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
      currentMonth = newMonth
    }
  }
  
  // 작성한 날짜
  func isDateMarked(_ date: Date?) -> Bool {
    guard let date else { return false }
    return markedDates.contains(calendar.startOfDay(for: date))
  }
  
}


struct ChartView: View {
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @StateObject private var viewModel: ChartViewModel
  @State private var selectedDate: Date? = nil
  @State private var showSheet = false

  
  init(markedDates: Set<Date>, countTags: [String: Int]) {
    _viewModel = StateObject(wrappedValue: ChartViewModel(markedDates: markedDates, countTags: countTags))
  }

  var body: some View {
    let isPad = horizontalSizeClass == .regular
    
    ScrollView {
      VStack {
        Divider()
          .background(viewModel.isDarkMode ? Color.white.opacity(1) : Color.gray)
        
        Text("활동 내역")
       .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: isPad ? 40 : 20))
          .padding(10)
         
        HStack(spacing: isPad ? 60 : 20) {
          Button { viewModel.changeMonth(by: -1)
          } label: {
            Image(systemName: "chevron.left")
              .bold()
              .font(.system(size: isPad ? 50 : 20))
          }
          
          
          Text(viewModel.monthTitle)
            .font(.system(size: isPad ? 50 : 20))
            .bold()
          
          
          Button{ viewModel.changeMonth(by: 1) } label: {
            Image(systemName: "chevron.right")
              .bold()
              .font(.system(size: isPad ? 50 : 20))
          }
        }

        // 요일 날짜 넣기
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
          ForEach(viewModel.dayWeeks, id: \.self) { day in
            Text(day)
              .font(.system(size: isPad ? 40 : 14))
              .foregroundColor(
                day == "일" ? .red : (day == "토" ? .blue : .primary)
              )
          }
        }
        //    .padding(.horizontal)

        // 달력 날짜 생성
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
          ForEach(Array(viewModel.arrayMonthDays.enumerated()), id: \.offset) { index, date in
            if let date {
              DayCell(
                date: date,
                isMarked: viewModel.isDateMarked(date),
                size: isPad ? 80 : 40
              )
              .onTapGesture {
                selectedDate = date
                showSheet = true
              }
            } else {
              Color.clear.frame(height: isPad ? 60 : 40)
            }
          }
        }
        .padding(.bottom, 20)
        Divider()
          .background(viewModel.isDarkMode ? Color.white.opacity(1) : Color.gray)

        Text("키워드 통계")
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: isPad ? 40 : 20))
          .padding(10)
          
        HStack(spacing: isPad ? 60 : 20) {
          Circle()
            .frame(width: 200, height: 200)
            .foregroundColor(.blue)
          
          VStack {
            ForEach(0..<4, id: \.self) { index in
              HStack{
                RoundedRectangle(cornerRadius: 4)
                  .foregroundColor(.red)
                  .frame(width: 20, height: 20)
                
                  Text("빨강 : \(Int(index)) 건")
                    .font(.system(size: isPad ? 40 : 20))

              }
            }
          }
          .padding(.leading, 10)
        }
        .frame(height: 200)
      }
      .padding(.horizontal)
    }
    .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
    .sheet(isPresented: $showSheet) {
      
    }
  }
}

struct DayCell: View {
  let date: Date
  let isMarked: Bool
  var size: CGFloat = 40

  var body: some View {
    Text("\(Calendar.current.component(.day, from: date))")
      .frame(width: size, height: size)
      .background(isMarked ? Color.blue : Color.clear)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(isMarked ? Color.blue : Color.gray, lineWidth: 1)
      )

      .foregroundColor(isMarked ? .white : .primary)
      .font(.system(size: size * 0.5))
  }
}

#Preview {
  ChartView(markedDates: Set<Date>(),
            countTags: [:])
}
