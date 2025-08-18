//
//  ChartView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

private enum ChartSegment: String, CaseIterable, Identifiable {
  case history = "회고 이력"
  case memoStats = "회고 통계"
  case keywordStats = "태그 통계"
  var id: String { rawValue }
}

private struct SheetDate: Identifiable, Equatable {
  let date: Date
  var id: Double { Calendar.current.startOfDay(for: date).timeIntervalSince1970 }
}

extension Notification.Name {
  static let memosDidChange = Notification.Name("memosDidChange")
}

struct ChartView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let markedDatesInput: Set<Date>
  private let countTagsInput: [String: Int]
  private let dayCountsInput: [Date: Int]
  private let memosInput: [Memo]

  @State private var selectedSegment: ChartSegment = .history
  @State private var workingMemos: [Memo]

  init(
    markedDates: Set<Date>,
    countTags: [String: Int],
    dayCounts: [Date: Int],
    memos: [Memo]
  ) {
    self.markedDatesInput = markedDates
    self.countTagsInput = countTags
    self.dayCountsInput = dayCounts
    self.memosInput = memos
    _workingMemos = State(initialValue: memos)
  }

  var body: some View {
    GeometryReader { geo in
      let desiredWidth = geo.size.width * (2.0 / 3.0)
      let containerHeight: CGFloat = 56

      VStack(spacing: 16) {
        // 상단 세그먼트
        HStack {
          Spacer(minLength: 0)
          Picker("", selection: $selectedSegment) {
            ForEach(ChartSegment.allCases) { seg in
              Text(seg.rawValue).tag(seg)
            }
          }
          .pickerStyle(.segmented)
          .environment(\.controlSize, .large)
          .frame(width: desiredWidth, height: containerHeight)
          Spacer(minLength: 0)
        }
        .padding(.top, 8)

        // 섹션 전환
        switch selectedSegment {
        case .history:
          HistorySectionView(memos: $workingMemos)
        case .memoStats:
          MemoStatsSectionView(dayCounts: dayCountsInput)
        case .keywordStats:
          KeywordStatsSectionView(
            countTags: countTagsInput,
            memos: workingMemos
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    // 배경
    .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
    // 알림 수신 → 최신 메모로 교체
    .onReceive(NotificationCenter.default.publisher(for: .memosDidChange)) { note in
      if let latest = note.userInfo?["memos"] as? [Memo] {
        self.workingMemos = latest
      }
    }
  }
}

private struct HistorySectionView: View {
  @Binding var memos: [Memo]

  @State private var baseDate: Date = Calendar.current.startOfDay(for: Date())
  @State private var selectedDate: Date? = nil
  @State private var showYearMonthPicker = false
  @State private var sheetItem: SheetDate? = nil
  @State private var heatmapYear: Int = Calendar.current.component(.year, from: Date())
  @State private var showYearPicker = false

  private var countsFromMemos: [Date: Int] {
    let cal = Calendar.current
    return memos.reduce(into: [Date: Int]()) { acc, memo in
      let key = cal.startOfDay(for: memo.day)
      acc[key, default: 0] += 1
    }
  }

  private var year: Int { Calendar.current.component(.year, from: baseDate) }
  private var month: Int { Calendar.current.component(.month, from: baseDate) }

  private var titleString: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyy년 MM월"
    return f.string(from: baseDate)
  }

  private var recentYears: [Int] {
    let cur = Calendar.current.component(.year, from: Date())
    return (0..<10).map { cur - $0 }
  }

  private var shouldShowTodayButton: Bool {
    let cal = Calendar.current
    return !cal.isDate(baseDate, equalTo: Date(), toGranularity: .month)
  }

  var body: some View {
    let content = ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 16) {
        Text("회고 이력").font(.title3.weight(.semibold))

        SettingsCard {
          MonthHeader(
            title: titleString,
            onPrev: { changeMonth(by: -1) },
            onNext: { changeMonth(by: +1) },
            onTitleTap: { showYearMonthPicker = true },
            showToday: shouldShowTodayButton,
            onTapToday: { goToToday() }
          )
          Divider().padding(.vertical, 4)

          MonthCalendarGrid(
            baseDate: baseDate,
            selectedDate: $selectedDate,
            countsByDay: countsFromMemos,
            onDoubleTap: { date in sheetItem = SheetDate(date: date) }
          )
        }

        SettingsCard {
          YearHeatmapCard(
            year: $heatmapYear,
            countsByDay: countsFromMemos,
            onOpenPicker: { showYearPicker = true }
          )
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 16)
    }
    .sheet(isPresented: $showYearMonthPicker) {
      YearMonthWheelPicker(
        selectedYear: year,
        selectedMonth: month,
        onConfirm: { y, m in
          setYearMonth(y, m)
          showYearMonthPicker = false
        },
        onCancel: { showYearMonthPicker = false }
      )
      .presentationDetents([.fraction(0.4), .medium])
    }
    .sheet(item: $sheetItem) { item in
      DayMemoListSheet(date: item.date, memos: $memos)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    ZStack {
      content
      if showYearPicker {
        YearBottomPickerOverlay(
          years: recentYears,
          selection: $heatmapYear,
          isPresented: $showYearPicker
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
      }
    }
  }

  private func changeMonth(by value: Int) {
    if let newDate = Calendar.current.date(byAdding: .month, value: value, to: baseDate),
       let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: newDate)) {
      baseDate = start
    }
    selectedDate = nil
  }

  private func setYearMonth(_ y: Int, _ m: Int) {
    var comps = DateComponents()
    comps.year = y
    comps.month = m
    comps.day = 1
    if let d = Calendar.current.date(from: comps) {
      baseDate = Calendar.current.startOfDay(for: d)
    }
    selectedDate = nil
  }

  private func goToToday() {
    let cal = Calendar.current
    let now = Date()
    if let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) {
      withAnimation(.easeInOut(duration: 0.28)) {
        baseDate = startOfMonth
        selectedDate = now
      }
      #if canImport(UIKit)
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
      #endif
    }
  }
}

private struct MonthHeader: View {
  let title: String
  let onPrev: () -> Void
  let onNext: () -> Void
  let onTitleTap: () -> Void
  let showToday: Bool
  let onTapToday: () -> Void

  init(
    title: String,
    onPrev: @escaping () -> Void,
    onNext: @escaping () -> Void,
    onTitleTap: @escaping () -> Void,
    showToday: Bool = false,
    onTapToday: @escaping () -> Void = {}
  ) {
    self.title = title
    self.onPrev = onPrev
    self.onNext = onNext
    self.onTitleTap = onTitleTap
    self.showToday = showToday
    self.onTapToday = onTapToday
  }

  var body: some View {
    HStack(spacing: 8) {
      Button(action: onPrev) {
        Image(systemName: "chevron.left").bold().frame(width: 44, height: 44)
      }
      Spacer(minLength: 0)
      if showToday {
        Button(action: onTapToday) {
          Text("오늘").font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오늘로 이동")
        .accessibilityHint("현재 달과 오늘 날짜로 이동합니다.")
      }
      Button(action: onNext) {
        Image(systemName: "chevron.right").bold().frame(width: 44, height: 44)
      }
    }
    .overlay {
      Button(action: onTitleTap) { Text(title).font(.title3.bold()) }
        .buttonStyle(.plain)
    }
    .padding(.top, 4)
  }
}

// MARK: - MonthCalendarGrid
private struct MonthCalendarGrid: View {
  let baseDate: Date
  @Binding var selectedDate: Date?
  let countsByDay: [Date: Int]
  let onDoubleTap: (Date) -> Void
  private let cal = Calendar.current

  private var days: [Date?] {
    guard
      let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: baseDate)),
      let range = cal.range(of: .day, in: .month, for: firstDay)
    else { return [] }

    let firstWeekday = cal.component(.weekday, from: firstDay)
    var arr: [Date?] = Array(repeating: nil, count: max(firstWeekday - 1, 0))
    for d in range {
      if let date = cal.date(byAdding: .day, value: d - 1, to: firstDay) {
        arr.append(date)
      }
    }
    while arr.count < 42 { arr.append(nil) }
    return arr
  }

  private let dayWeeks: [String] = ["일", "월", "화", "수", "목", "금", "토"]

  var body: some View {
    VStack(spacing: 8) {
      // 요일 헤더
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
        spacing: 0
      ) {
        ForEach(0..<7, id: \.self) { idx in
          Text(dayWeeks[idx])
            .font(.system(size: 14))
            .foregroundColor(idx == 0 ? .red : (idx == 6 ? .blue : .primary))
            .frame(maxWidth: .infinity)
        }
      }

      // 날짜 그리드
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
        spacing: 6
      ) {
        ForEach(Array(days.indices), id: \.self) { i in
          if let date = days[i] {
            let isInCurrentMonth = cal.isDate(date, equalTo: baseDate, toGranularity: .month)
            let isToday = cal.isDateInToday(date)
            let isSelected = selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false
            let key = cal.startOfDay(for: date)
            let count = countsByDay[key] ?? 0

            DayCell(
              date: date,
              isInCurrentMonth: isInCurrentMonth,
              isToday: isToday,
              isSelected: isSelected,
              count: count
            )
            .contentShape(Rectangle())
            .onTapGesture { selectedDate = date }
            .onTapGesture(count: 2) { onDoubleTap(date) }
          } else {
            Color.clear.frame(height: 40)
          }
        }
      }
      .padding(.bottom, 4)
    }
  }
}

private struct DayCell: View {
  let date: Date
  let isInCurrentMonth: Bool
  let isToday: Bool
  let isSelected: Bool
  let count: Int
  private let cal = Calendar.current

  var body: some View {
    let dayNum = cal.component(.day, from: date)
    let borderColor: Color? = {
      if isSelected { return .blue }
      if isToday { return .red }
      return nil
    }()
    let lineWidth: CGFloat = (borderColor != nil) ? 2 : 0

    ZStack(alignment: .bottom) {
      Text("\(dayNum)")
        .foregroundStyle(isInCurrentMonth ? .primary : .secondary)
        .font(.system(size: 16, weight: isSelected ? .bold : .regular))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

      HStack(spacing: 4) {
        if count >= 1 {
          Circle().frame(width: 4, height: 4).foregroundColor(.red)
        }
        if count >= 2 {
          Text("+\(min(count, 99))").font(.caption2).foregroundColor(.red)
        }
      }
      .padding(.bottom, 2)
    }
    .frame(height: 40)
    .overlay(
      Group {
        if let borderColor {
          RoundedRectangle(cornerRadius: 6).stroke(borderColor, lineWidth: lineWidth)
        }
      }
    )
  }
}

private struct YearHeatmapCard: View {
  @Binding var year: Int
  let countsByDay: [Date: Int]
  let onOpenPicker: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("연간 히트맵").font(.headline)
        Spacer()
        Button(action: onOpenPicker) {
          HStack(spacing: 4) {
            Text(verbatim: "\(year)년").font(.subheadline.weight(.semibold))
            Image(systemName: "chevron.up.chevron.down").font(.caption.bold())
              .opacity(0.7)
          }
          .padding(.horizontal, 10).padding(.vertical, 6)
          .background(Capsule().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
      }
      YearHeatmapCanvas(year: year, countsByDay: countsByDay).frame(height: 140)
    }
  }
}

private struct YearHeatmapCanvas: View {
  let year: Int
  let countsByDay: [Date: Int]
  private let cal = Calendar.current
  private let cell: CGFloat = 14
  private let gap: CGFloat = 4
  private let corner: CGFloat = 3
  private let strokeWidth: CGFloat = 0.5

  private func startOfWeek(for date: Date) -> Date {
    let weekday = cal.component(.weekday, from: date)
    return cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: date))!
  }
  private func endOfWeek(for date: Date) -> Date {
    let weekday = cal.component(.weekday, from: date)
    return cal.date(byAdding: .day, value: (7 - weekday), to: cal.startOfDay(for: date))!
  }
  private var startOfYear: Date {
    cal.date(from: DateComponents(year: year, month: 1, day: 1))!
  }
  private var endOfYearExclusive: Date {
    cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
  }
  private var weekStarts: [Date] {
    let gridStart = startOfWeek(for: startOfYear)
    let gridEnd = endOfWeek(for: cal.date(byAdding: .day, value: -1, to: endOfYearExclusive)!)
    let weekInterval: TimeInterval = 60 * 60 * 24 * 7
    return stride(from: gridStart, through: gridEnd, by: weekInterval).map { $0 }
  }
  private var contentWidth: CGFloat {
    let cols = CGFloat(weekStarts.count)
    return cols * cell + (cols - 1) * gap
  }
  private var contentHeight: CGFloat {
    let rows: CGFloat = 7
    return rows * cell + (rows - 1) * gap
  }

  var body: some View {
    GeometryReader { proxy in
      let availW = proxy.size.width
      let availH = proxy.size.height
      #if canImport(UIKit)
      let isPad = UIDevice.current.userInterfaceIdiom == .pad
      #else
      let isPad = false
      #endif
      let isLandscape = availW > availH
      let shouldCenter = isPad && isLandscape && contentWidth <= availW

      Group {
        if shouldCenter {
          HStack {
            Canvas { ctx, _ in drawHeatmap(ctx: ctx) }
              .frame(width: contentWidth, height: contentHeight)
              .accessibilityHidden(true)
          }
          .frame(maxWidth: .infinity, alignment: .center)
        } else {
          ScrollView(.horizontal, showsIndicators: false) {
            Canvas { ctx, _ in drawHeatmap(ctx: ctx) }
              .frame(width: contentWidth, height: contentHeight)
              .accessibilityHidden(true)
          }
        }
      }
      .frame(height: contentHeight)
    }
    .frame(height: contentHeight)
  }

  private func drawHeatmap(ctx: GraphicsContext) {
    for (col, weekStart) in weekStarts.enumerated() {
      let x = CGFloat(col) * (cell + gap)
      if containsFirstOfMonth(weekStart) {
        let lineRect = CGRect(x: x - gap * 0.5, y: 0, width: 1, height: contentHeight)
        ctx.fill(
          Path(roundedRect: lineRect, cornerRadius: 0.5),
          with: .color(.gray.opacity(0.25))
        )
      }
      for row in 0..<7 {
        guard let day = cal.date(byAdding: .day, value: row, to: weekStart) else { continue }
        if !(startOfYear..<endOfYearExclusive).contains(day) { continue }
        let key = cal.startOfDay(for: day)
        let hasMemo = (countsByDay[key] ?? 0) > 0
        let rect = CGRect(
          x: x,
          y: CGFloat(row) * (cell + gap),
          width: cell,
          height: cell
        )
        let path = Path(roundedRect: rect, cornerRadius: corner)
        ctx.fill(path, with: .color(hasMemo ? .accentColor : .gray.opacity(0.15)))
        ctx.stroke(path, with: .color(.black.opacity(0.05)), lineWidth: strokeWidth)
      }
    }
  }

  private func containsFirstOfMonth(_ weekStart: Date) -> Bool {
    for d in 0..<7 {
      if let day = cal.date(byAdding: .day, value: d, to: weekStart),
         cal.component(.day, from: day) == 1 {
        return true
      }
    }
    return false
  }
}

private struct YearBottomPickerOverlay: View {
  let years: [Int]
  @Binding var selection: Int
  @Binding var isPresented: Bool

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .bottom) {
        Color.black.opacity(0.25)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) { isPresented = false }
          }

        VStack(spacing: 12) {
          HStack {
            Button("취소") {
              withAnimation(.snappy(duration: 0.2)) { isPresented = false }
            }
            .font(.body)
            Spacer()
            Text("연도 선택").font(.headline)
            Spacer()
            Color.clear.frame(width: 44, height: 1)
          }
          .padding(.horizontal, 20)
          .padding(.top, 16)

          ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
              ForEach(years, id: \.self) { y in
                Button {
                  selection = y
                  withAnimation(.snappy(duration: 0.2)) { isPresented = false }
                } label: {
                  HStack {
                    Text(verbatim: "\(y)년")
                      .font(.title3.weight(selection == y ? .bold : .regular))
                    Spacer()
                    if selection == y {
                      Image(systemName: "checkmark").font(.headline)
                    }
                  }
                  .padding(.vertical, 10)
                  .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                Divider()
              }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .contentMargins(.bottom, geo.safeAreaInsets.bottom + 24, for: .scrollContent)
          }
          Spacer(minLength: 0)
        }
        .frame(height: geo.size.height / 1.5)
        .frame(maxWidth: .infinity)
        .contentMargins(.bottom, geo.safeAreaInsets.bottom + 24, for: .scrollContent)
        .background(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.systemBackground))
        )
        .shadow(radius: 12)
      }
      .ignoresSafeArea()
    }
  }
}

private struct MemoStatsSectionView: View {
  let dayCounts: [Date: Int]

  private var totalMemoCount: Int { dayCounts.values.reduce(0, +) }
  private var thisMonthMemoCount: Int {
    let cal = Calendar.current
    let now = Date()
    return dayCounts.reduce(0) { acc, pair in
      let (day, count) = pair
      return cal.isDate(day, equalTo: now, toGranularity: .month) ? acc + count : acc
    }
  }

  private var last7Days: [Date] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    return (0..<7).reversed().compactMap {
      cal.date(byAdding: .day, value: -$0, to: today)
    }
  }

  struct DailyCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
  }
  private var last7Data: [DailyCount] {
    let cal = Calendar.current
    return last7Days.map { d in
      let key = cal.startOfDay(for: d)
      return DailyCount(date: key, count: dayCounts[key] ?? 0)
    }
  }
  private let yTicks: [Double] = [5, 10, 15, 20].map(Double.init)

  struct MonthCount: Identifiable {
    let month: Int
    let count: Int
    var id: Int { month }
  }
  private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
  private var currentYearString: String { String(currentYear) }
  private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }
  private var monthsUpToNow: [Int] { Array(1...currentMonth) }
  private var thisYearMonthlyData: [MonthCount] {
    let cal = Calendar.current
    var map: [Int: Int] = [:]
    for (day, c) in dayCounts {
      let comps = cal.dateComponents([.year, .month], from: day)
      if comps.year == currentYear, let m = comps.month {
        map[m, default: 0] += c
      }
    }
    return monthsUpToNow.map { MonthCount(month: $0, count: map[$0] ?? 0) }
  }

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 16) {
        Text("회고 통계").font(.title3.weight(.semibold))

        SettingsCard {
          HStack(spacing: 12) {
            StatCard(title: "총 회고 수", value: "\(totalMemoCount)")
            StatCard(title: "올해 월 평균 회고 수", value: "\(thisMonthMemoCount)")
          }
        }

        // 최근 1주 네이티브 막대
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            Text("최근 1주 추이").font(.headline)
            Last7BarChartNative(
              data: last7Data.map { Last7BarChartNative.Item(date: $0.date, count: $0.count) }
            )
            .padding(.top, 6)
            .frame(height: 180)
          }
        }

        // 월별 네이티브 라인
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            Text("\(currentYearString)년 월별 추이").font(.headline)
            MonthlyLineChartNative(
              data: thisYearMonthlyData.map { MonthlyLineChartNative.Item(month: $0.month, count: $0.count) },
              currentMonth: currentMonth,
              tickValues: yTicks
            )
            .padding(.top, 6)
            .frame(height: 200)
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 16)
    }
  }
}

private struct StatCard: View {
  let title: String
  let value: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.caption).foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
      Text(value).font(.title2.weight(.bold))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(14)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06))
    )
  }
}

private struct KeywordStatsSectionView: View {
  let countTags: [String: Int]
  let memos: [Memo]

  private enum Period: String, CaseIterable, Identifiable {
    case year = "이번 년도"
    case month = "이번 달"
    case week = "1주일"
    var id: String { rawValue }
  }
  @State private var selectedPeriod: Period = .year
  @State private var showAllBars: Bool = false

  private let rankColors: [Color] = [.red, .yellow, .green, .blue]
  private let othersColor: Color = .gray

  private var totalKeywordAllTime: Int { countTags.values.reduce(0, +) }

  private var filteredCountTags: [String: Int] {
    let cal = Calendar.current
    let now = Date()
    let start: Date = {
      switch selectedPeriod {
      case .year:
        return cal.date(
          from: DateComponents(
            year: cal.component(.year, from: now),
            month: 1,
            day: 1
          )
        ) ?? cal.startOfDay(for: now)
      case .month:
        return cal.date(
          from: DateComponents(
            year: cal.component(.year, from: now),
            month: cal.component(.month, from: now),
            day: 1
          )
        ) ?? cal.startOfDay(for: now)
      case .week:
        return cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now))
          ?? cal.startOfDay(for: now)
      }
    }()
    var map: [String: Int] = [:]
    for memo in memos where memo.day >= start && memo.day <= now {
      for t in memo.tags where !t.isEmpty { map[t, default: 0] += 1 }
    }
    return map
  }

  private var donutSortedAll: [(String, Int)] {
    filteredCountTags.sorted { l, r in
      l.value == r.value ? l.key < r.key : l.value > r.value
    }
  }
  private var donutTop4: [(String, Int)] { Array(donutSortedAll.prefix(4)) }
  private var donutSumTop4: Int { donutTop4.reduce(0) { $0 + $1.1 } }
  private var donutTotal: Int { filteredCountTags.values.reduce(0, +) }
  private var donutOthers: Int { max(donutTotal - donutSumTop4, 0) }

  private struct Slice: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
  }
  private var donutSlices: [Slice] {
    var arr: [Slice] = []
    for (idx, p) in donutTop4.enumerated() {
      arr.append(
        Slice(
          name: p.0,
          count: p.1,
          color: rankColors[min(idx, rankColors.count - 1)]
        )
      )
    }
    if donutOthers > 0 {
      arr.append(Slice(name: "기타", count: donutOthers, color: othersColor))
    }
    return arr
  }

  private func percentString(_ count: Int) -> String {
    guard donutTotal > 0 else { return "0%" }
    let p = Double(count) / Double(donutTotal) * 100
    return String(format: "%.0f%%", p.rounded())
  }

  private var barSortedAll: [(String, Int)] {
    countTags.sorted { l, r in
      l.value == r.value ? l.key < r.key : l.value > r.value
    }
  }
  private var barTop4: [(String, Int)] { Array(barSortedAll.prefix(4)) }
  private var barOthers: Int {
    barSortedAll.dropFirst(4).reduce(0) { $0 + $1.1 }
  }
  private var barDataTop5: [Slice] {
    if barSortedAll.count < 5 {
      return barSortedAll.enumerated().map { idx, e in
        Slice(
          name: e.0,
          count: e.1,
          color: rankColors[min(idx, rankColors.count - 1)]
        )
      }
    }
    var slices = barTop4.enumerated().map { idx, e in
      Slice(
        name: e.0,
        count: e.1,
        color: rankColors[min(idx, rankColors.count - 1)]
      )
    }
    if barOthers > 0 {
      slices.append(Slice(name: "기타", count: barOthers, color: othersColor))
    }
    return slices
  }
  private var barDataAll: [Slice] {
    barSortedAll.enumerated().map { idx, e in
      Slice(
        name: e.0,
        count: e.1,
        color: (idx < 4) ? rankColors[idx] : othersColor
      )
    }
  }
  private var barDataEffective: [Slice] {
    showAllBars ? barDataAll : barDataTop5
  }

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 16) {
        Text("태그 통계").font(.title3.weight(.semibold))

        // 도넛 카드
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("태그 비중").font(.headline)
              Spacer()
              Picker("기간", selection: $selectedPeriod) {
                ForEach(Period.allCases) { p in Text(p.rawValue).tag(p) }
              }
              .pickerStyle(.segmented)
              .frame(maxWidth: 280)
            }

            if donutTotal == 0 {
              Text("표시할 태그가 없습니다.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
            } else {
              ZStack {
                DonutChartNative(
                  slices: donutSlices.map {
                    NativeSlice(name: $0.name, count: $0.count, color: $0.color)
                  },
                  innerRatio: 0.6
                )
                .frame(width: 220, height: 220)
              }
              .frame(maxWidth: .infinity, alignment: .center)

              VStack(alignment: .leading, spacing: 8) {
                ForEach(donutSlices) { s in
                  HStack(spacing: 8) {
                    Circle().fill(s.color).frame(width: 10, height: 10)
                    Text(s.name).font(.subheadline)
                    Spacer()
                    Text("\(s.count) · \(percentString(s.count))")
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                  }
                }
              }
            }
          }
        }

        // 가로 막대 카드
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
              Text("상위 4 태그 (전체)").font(.headline)
              Text("총 \(totalKeywordAllTime)")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Color(.systemGray6)))
                .foregroundStyle(.secondary)
              Spacer()
              Button(showAllBars ? "간략히" : "전체보기") {
                withAnimation(.easeInOut(duration: 0.18)) {
                  showAllBars.toggle()
                }
              }
              .font(.subheadline.weight(.semibold))
            }

            if barDataEffective.isEmpty {
              Text("표시할 태그가 없습니다.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
            } else {
              HBarListNative(
                items: barDataEffective.map {
                  NativeSlice(name: $0.name, count: $0.count, color: $0.color)
                }
              )
              .frame(minHeight: 140)

              HStack(spacing: 12) {
                legendDot(.red, "1위")
                legendDot(.yellow, "2위")
                legendDot(.green, "3위")
                legendDot(.blue, "4위")
          //      legendDot(.gray, showAllBars ? "그 외(개별)" : "기타")
              }
              .font(.caption)
              .foregroundStyle(.secondary)
            }
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 16)
    }
  }

  @ViewBuilder
  private func legendDot(_ color: Color, _ label: String) -> some View {
    HStack(spacing: 6) {
      Circle().fill(color).frame(width: 8, height: 8)
      Text(label)
    }
  }
}

private struct YearMonthWheelPicker: View {
  @State private var tempYear: Int
  @State private var tempMonth: Int
  @State private var yearSelection: Int
  let onConfirm: (Int, Int) -> Void
  let onCancel: () -> Void
  private let years: [Int]
  private let months: [Int] = Array(1...12)

  init(
    selectedYear: Int,
    selectedMonth: Int,
    onConfirm: @escaping (Int, Int) -> Void,
    onCancel: @escaping () -> Void
  ) {
    _tempYear = State(initialValue: selectedYear)
    _tempMonth = State(initialValue: selectedMonth)
    _yearSelection = State(initialValue: selectedYear)
    self.onConfirm = onConfirm
    self.onCancel = onCancel
    let current = Calendar.current.component(.year, from: Date())
    self.years = Array((current - 50)...(current + 10))
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Button("취소", action: onCancel)
        Spacer()
        Text("년/월 선택").font(.headline)
        Spacer()
        Button("완료") { onConfirm(yearSelection, tempMonth) }
      }
      .padding(.horizontal)

      HStack {
        Picker("년도", selection: $yearSelection) {
          ForEach(years, id: \.self) { Text(String($0) + "년").tag($0) }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)

        Picker("월", selection: $tempMonth) {
          ForEach(months, id: \.self) { Text(String(format: "%02d월", $0)).tag($0) }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
      }
      .frame(height: 160)
    }
    .padding(.top, 8)
    .presentationDragIndicator(.visible)
  }
}

// MARK: - Donut (Top4 + Others)
struct DonutChartNative: View {
  var slices: [NativeSlice]
  var innerRatio: CGFloat = 0.6

  init(slices: [NativeSlice], innerRatio: CGFloat = 0.6) {
    self.slices = slices
    self.innerRatio = innerRatio
  }

  private var total: Double {
    max(Double(slices.reduce(0) { $0 + $1.count }), 0)
  }

  // 각도 계산을 별도 메서드로 분리 (ViewBuilder 밖)
  private func anglePairs() -> [(start: Angle, end: Angle)] {
    var result: [(start: Angle, end: Angle)] = []
    var cursor = Angle.degrees(-90)
    let sum = max(total, 1)
    for s in slices {
      let frac = Double(s.count) / sum
      let next = cursor + .degrees(frac * 360)
      result.append((start: cursor, end: next))
      cursor = next
    }
    return result
  }

  var body: some View {
    GeometryReader { geo in
      let size = min(geo.size.width, geo.size.height)
      let angles = anglePairs()

      ZStack {
        ForEach(slices.indices, id: \.self) { i in
          let s = slices[i]
          let a = angles[i]
          RingSlice(
            startAngle: a.start,
            endAngle: a.end,
            innerRatio: innerRatio
          )
          .fill(s.color)
        }

        VStack(spacing: 2) {
          Text("총").font(.caption2).foregroundStyle(.secondary)
          Text("\(Int(total))").font(.title3.bold())
        }
      }
      .frame(width: size, height: size)
    }
  }
}

private struct DayMemoListSheet: View {
  let date: Date
  @Binding var memos: [Memo]
  private var dateKey: Date { Calendar.current.startOfDay(for: date) }
  private var filteredMemos: [Memo] {
    let cal = Calendar.current
    return memos.filter { cal.startOfDay(for: $0.day) == dateKey }
  }

  var body: some View {
    NavigationStack {
      List {
        if filteredMemos.isEmpty {
          Text("이 날짜의 회고가 없습니다.").foregroundStyle(.secondary)
        } else {
          ForEach(filteredMemos) { memo in
            NavigationLink {
              TexteditView(memos: $memos, memoToEdit: memo)
            } label: {
              VStack(alignment: .leading, spacing: 6) {
                let tags = memo.tags.filter { !$0.isEmpty }
                if !tags.isEmpty {
                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                      ForEach(tags, id: \.self) { t in
                        Text(t).font(.footnote.weight(.semibold))
                          .padding(.horizontal, 10).padding(.vertical, 6)
                          .foregroundStyle(.white)
                          .background(Capsule().fill(Color.accentColor))
                      }
                    }
                  }
                }
                Text(memo.title).font(.headline).foregroundStyle(.primary)
                  .lineLimit(1)
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle(formattedTitle(date))
      .navigationBarTitleDisplayMode(.inline)
    }
    .onChange(of: memos) { latest in
      NotificationCenter.default.post(
        name: .memosDidChange,
        object: nil,
        userInfo: ["memos": latest]
      )
    }
  }

  private func formattedTitle(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyy. MM. dd"
    return f.string(from: d)
  }
}

struct SettingsCard<Content: View>: View {
  private let content: Content

  // 제네릭 Content 추론용 @ViewBuilder 이니셜라이저
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      content
    }
    .environment(\.colorScheme, .light)  // 내용은 항상 라이트 톤
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(
        Color.white,
        lineWidth: 1
      )
    )
  }
}

#Preview {
  ChartView(markedDates: [], countTags: [:], dayCounts: [:], memos: [])
    .environment(\.locale, Locale(identifier: "ko_KR"))
}
