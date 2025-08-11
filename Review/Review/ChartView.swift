//
//  ChartView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

struct ChartView: View {
  let markedDates: Set<Date>

  @State private var currentMonth: Date = Date()
  @State private var showFullJandiblock: Bool = false

  private let calendar = Calendar.current

  var body: some View {
    VStack {
      VStack {
        Divider()
        Text("활동 내역")
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(10)

        HStack {
          Button(action: { changeMonth(by: -1) }) {
            Image(systemName: "chevron.left")
          }
          Spacer()
          Text(monthTitle(for: currentMonth))
            .font(.title3)
            .bold()
          Spacer()
          Button(action: { changeMonth(by: 1) }) {
            Image(systemName: "chevron.right")
          }
        }
        .padding(.horizontal)

        let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
          ForEach(daysOfWeek, id: \.self) { day in
            Text(day)
              .font(.subheadline)
              .foregroundColor(
                day == "일" ? .red : (day == "토" ? .blue : .primary)
              )
          }
        }
        .padding(.horizontal)

        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible()), count: 7),
          spacing: 8
        ) {
          ForEach(generateMonthDays(for: currentMonth), id: \.self) { date in
            if let date = date {
              let normalizedDate = calendar.startOfDay(for: date)
              DayCell(
                date: date,
                isMarked: markedDates.contains(normalizedDate)
              )
              .onTapGesture {
                showFullJandiblock = true
              }

            } else {
              Color.clear.frame(height: 40)
            }
          }
        }
        .padding(.horizontal)
      }

      Divider()
      Text("키워드 통계")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
      HStack {

      }

    }
    .frame(maxHeight: .infinity, alignment: .top)  // 여기 수정된 부분
    .sheet(isPresented: $showFullJandiblock) {
      let now = Date()
       let calendar = Calendar.current
      let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
      let startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: yearStart))!
      JandiFullView(
         totalweeks: 53,
         days: 7,
         startDate: startDate,
         markedDates: markedDates
       )

    }
  }

  func changeMonth(by value: Int) {
    if let newMonth = calendar.date(
      byAdding: .month,
      value: value,
      to: currentMonth
    ) {
      currentMonth = newMonth
    }
  }

  func monthTitle(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월"
    return formatter.string(from: date)
  }

  func generateMonthDays(for month: Date) -> [Date?] {
    guard let range = calendar.range(of: .day, in: .month, for: month),
      let firstDay = calendar.date(
        from: calendar.dateComponents([.year, .month], from: month)
      )
    else { return [] }

    let firstWeekday = calendar.component(.weekday, from: firstDay)

    var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

    for day in range {
      if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)
      {
        days.append(date)
      }
    }

    while days.count < 42 {
      days.append(nil)
    }

    return days
  }
}

struct DayCell: View {
  let date: Date
  let isMarked: Bool

  var body: some View {
    Text("\(Calendar.current.component(.day, from: date))")
      .frame(width: 40, height: 40)
      .background(isMarked ? Color.blue : Color.clear)
      .cornerRadius(6)
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(isMarked ? Color.blue : Color.gray, lineWidth: 1)
      )
      .foregroundColor(isMarked ? .white : .primary)
  }
}

struct JandiBlock: View {
  var isMarked: Bool = false
  
  var body: some View {
    Rectangle()
      .fill(isMarked ? Color.blue : Color.gray.opacity(0.3))
      .frame(width: 15, height: 15)
      .cornerRadius(4)
      .padding(.vertical, 1)
  }
}

struct JandiFullView: View {
  let totalweeks: Int
  let days: Int
  let startDate: Date
  let markedDates: Set<Date>

  private let calendar = Calendar.current
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 2) {
        VStack(spacing: 2) {
          Text("일").foregroundColor(.red).font(.system(size: 14)).frame(
            height: 17
          )
          Text("월").font(.system(size: 14)).frame(height: 17)
          Text("화").font(.system(size: 14)).frame(height: 17)
          Text("수").font(.system(size: 14)).frame(height: 17)
          Text("목").font(.system(size: 14)).frame(height: 17)
          Text("금").font(.system(size: 14)).frame(height: 17)
          Text("토").foregroundColor(.blue).font(.system(size: 14)).frame(
            height: 17)
        }

        ForEach(0..<totalweeks, id: \.self) { week in
          VStack(spacing: 2) {
            ForEach(0..<days, id: \.self) { day in
              let currentDate = calendar.date(byAdding: .day, value: week * days + day, to: startDate)!
                            JandiBlock(isMarked: markedDates.contains(calendar.startOfDay(for: currentDate)))
            }
          }
        }
      }
      .padding()
    }
    .presentationDetents([.medium, .large])
  }
}

#Preview {
  ChartView(markedDates: [])
}
