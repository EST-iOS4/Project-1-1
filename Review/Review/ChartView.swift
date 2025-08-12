//
//  ChartView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

struct ChartView: View {
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  @AppStorage("isDarkMode") var isDarkMode = false

  let markedDates: Set<Date>

  @State private var currentMonth: Date = Date()
  private let calendar: Calendar = .current

  var body: some View {
    let isPad = horizontalSizeClass == .regular
    VStack {
      VStack {
        Divider()
        Text("활동 내역")
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(10)
          .font(.system(size: isPad ? 40 : 20))

        HStack(spacing: isPad ? 60 : 20) {
          Button(action: { changeMonth(by: -1) }) {
            Image(systemName: "chevron.left")
              .bold()
              .font(.system(size: isPad ? 50 : 20))
          }
          //        Spacer()
          Text(monthTitle(for: currentMonth))
            .font(.system(size: isPad ? 50 : 20))
            .bold()
          //        Spacer()
          Button(action: { changeMonth(by: 1) }) {
            Image(systemName: "chevron.right")
              .bold()
              .font(.system(size: isPad ? 50 : 20))
          }
        }

        // 요일 날짜 넣기
        let daysWeek = ["일", "월", "화", "수", "목", "금", "토"]

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
          ForEach(daysWeek, id: \.self) { day in
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
          // ForEach(arrayMonthDays(for: currentMonth), id: \.self) { date in
          ForEach(0..<arrayMonthDays(for: currentMonth).count, id: \.self) {
            index in
            if let date = arrayMonthDays(for: currentMonth)[index] {
              //if let date = date {
              let cellDate = calendar.startOfDay(for: date)
              DayCell(
                date: date,
                isMarked: markedDates.contains(cellDate),
                size: isPad ? 80 : 40
              )
              //            .onTapGesture {
              //                   showFullJandiblock = true
              //         Text("\(calendar.component(.day, from: date))")
              //           .frame(width: 40, height: 40)

            } else {
              Color.clear.frame(height: isPad ? 60 : 40)
            }
          }
        }
        Divider()

        Text("키워드 통계")
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(10)
          .font(.system(size: isPad ? 40 : 20))
      }
      .padding(.horizontal)
      .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    .frame(maxHeight: .infinity, alignment: .top)
  }

  // 달 바꾸기
  func changeMonth(by value: Int) {
    if let newMonth = calendar.date(
      byAdding: .month,
      value: value,
      to: currentMonth
    ) {
      currentMonth = newMonth
    }
  }

  // 달 년도 표시
  func monthTitle(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년   M월"
    return formatter.string(from: date)
  }

  // 달력 배열 만들기
  func arrayMonthDays(for month: Date) -> [Date?] {
    guard let range = calendar.range(of: .day, in: .month, for: month),
      let firstDay = calendar.date(
        from: calendar.dateComponents([.year, .month], from: month)
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
  ChartView(
    markedDates: Set([
      Calendar.current.startOfDay(for: Date()),
      Calendar.current.startOfDay(
        for: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
      ),
      Calendar.current.startOfDay(
        for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!
      ),
      Calendar.current.startOfDay(
        for: Calendar.current.date(byAdding: .day, value: -13, to: Date())!
      ),
      Calendar.current.startOfDay(
        for: Calendar.current.date(byAdding: .day, value: -15, to: Date())!
      ),
    ])
  )
}
