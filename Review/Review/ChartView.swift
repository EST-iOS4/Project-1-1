//
//  ChartView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import Charts
import SwiftUI

// 탭 선택하는거
private enum ChartSegment: String, CaseIterable, Identifiable {
  case history = "회고 이력"
  case memoStats = "회고 통계"
  case keywordStats = "키워드 통계"
  var id: String { rawValue }
}

// 시트에 쓰는 날짜
private struct SheetDate: Identifiable, Equatable {
  let date: Date
  var id: Double {
    Calendar.current.startOfDay(for: date).timeIntervalSince1970
  }
}

// 메모 바뀔때 알림
extension Notification.Name {
  static let memosDidChange = Notification.Name("memosDidChange")
}

// 차트 메인 뷰
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
        // 위에 있는 탭
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
        
        // 탭 눌렀을때 화면 바뀌는거
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
    // 배경 색
    .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
    // 알림 받으면 메모 최신으로 바꿈
    .onReceive(NotificationCenter.default.publisher(for: .memosDidChange)) {
      note in
      if let latest = note.userInfo?["memos"] as? [Memo] {
        self.workingMemos = latest
      }
    }
  }
}

// 회고 이력 화면
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
    let content =
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 16) {
        Text("회고 이력")
          .font(.title3.weight(.semibold))
        
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
            onDoubleTap: { date in
              sheetItem = SheetDate(date: date)
            }
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
    if let newDate = Calendar.current.date(
      byAdding: .month,
      value: value,
      to: baseDate
    ),
       let start = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: newDate)
       )
    {
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
        Image(systemName: "chevron.left").bold()
          .frame(width: 44, height: 44)
      }
      Spacer(minLength: 0)
      
      if showToday {
        Button(action: onTapToday) {
          Text("오늘")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오늘로 이동")
        .accessibilityHint("현재 달과 오늘 날짜로 이동합니다.")
      }
      
      Button(action: onNext) {
        Image(systemName: "chevron.right").bold()
          .frame(width: 44, height: 44)
      }
    }
    .overlay {
      Button(action: onTitleTap) {
        Text(title)
          .font(.title3.bold())
      }
      .buttonStyle(.plain)
    }
    .padding(.top, 4)
  }
}

// 달력 그리드
private struct MonthCalendarGrid: View {
  let baseDate: Date
  @Binding var selectedDate: Date?
  let countsByDay: [Date: Int]
  let onDoubleTap: (Date) -> Void
  
  private let cal = Calendar.current
  
  private var days: [Date?] {
    guard
      let firstDay = cal.date(
        from: cal.dateComponents([.year, .month], from: baseDate)
      ),
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
      // 요일 표시
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
      
      // 날짜 칸
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
        spacing: 6
      ) {
        ForEach(Array(days.indices), id: \.self) { i in
          if let date = days[i] {
            let isInCurrentMonth = cal.isDate(
              date,
              equalTo: baseDate,
              toGranularity: .month
            )
            let isToday = cal.isDateInToday(date)
            let isSelected =
            selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false
            
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

// 날짜 하나 셀
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
          Circle()
            .frame(width: 4, height: 4)
            .foregroundColor(.red)
        }
        if count >= 2 {
          Text("+\(min(count, 99))")
            .font(.caption2)
            .foregroundColor(.red)
        }
      }
      .padding(.bottom, 2)
    }
    .frame(height: 40)
    .overlay(
      Group {
        if let borderColor {
          RoundedRectangle(cornerRadius: 6)
            .stroke(borderColor, lineWidth: lineWidth)
        }
      }
    )
  }
}
// 연간 전체맵 카드 (연도랑 버튼만 보여줌)
private struct YearHeatmapCard: View {
  @Binding var year: Int
  let countsByDay: [Date: Int]
  let onOpenPicker: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("연간 작성맵").font(.headline)
        Spacer()
        // 연도 선택 버튼
        Button(action: onOpenPicker) {
          HStack(spacing: 4) {
            Text(verbatim: "\(year)년")
              .font(.subheadline.weight(.semibold))
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption.bold())
              .opacity(0.7)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Capsule().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
      }
      
      // 실제 히트맵 그리는 뷰
      YearHeatmapCanvas(year: year, countsByDay: countsByDay)
        .frame(height: 140)
    }
  }
}

// 연간 전체맵을 캔버스로 그림
private struct YearHeatmapCanvas: View {
  let year: Int
  let countsByDay: [Date: Int]
  
  private let cal = Calendar.current
  private let cell: CGFloat = 14
  private let gap: CGFloat = 4
  private let corner: CGFloat = 3
  private let strokeWidth: CGFloat = 0.5
  
  // 주 시작 구하기
  private func startOfWeek(for date: Date) -> Date {
    let weekday = cal.component(.weekday, from: date)
    return cal.date(
      byAdding: .day,
      value: -(weekday - 1),
      to: cal.startOfDay(for: date)
    )!
  }
  
  // 주 끝 구하기
  private func endOfWeek(for date: Date) -> Date {
    let weekday = cal.component(.weekday, from: date)
    return cal.date(
      byAdding: .day,
      value: (7 - weekday),
      to: cal.startOfDay(for: date)
    )!
  }
  
  // 연도 시작/끝
  private var startOfYear: Date {
    cal.date(from: DateComponents(year: year, month: 1, day: 1))!
  }
  private var endOfYearExclusive: Date {
    cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
  }
  
  // 한 해의 모든 주 시작일
  private var weekStarts: [Date] {
    let gridStart = startOfWeek(for: startOfYear)
    let gridEnd = endOfWeek(
      for: cal.date(byAdding: .day, value: -1, to: endOfYearExclusive)!
    )
    let weekInterval: TimeInterval = 60 * 60 * 24 * 7
    return stride(from: gridStart, through: gridEnd, by: weekInterval).map { $0 }
  }
  
  // 전체 그리드 크기
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

        // iPad 가로 모드이고, 콘텐츠 폭이 컨테이너보다 작을 때만 가운데 정렬
        let shouldCenter = isPad && isLandscape && contentWidth <= availW

        Group {
          if shouldCenter {
            // 가운데 정렬(스크롤 불필요)
            HStack {
              Canvas { ctx, _ in
                drawHeatmap(ctx: ctx)
              }
              .frame(width: contentWidth, height: contentHeight)
              .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
          } else {
            // 기존처럼 가로 스크롤
            ScrollView(.horizontal, showsIndicators: false) {
              Canvas { ctx, _ in
                drawHeatmap(ctx: ctx)
              }
              .frame(width: contentWidth, height: contentHeight)
              .accessibilityHidden(true)
            }
          }
        }
        .frame(height: contentHeight)
      }
      .frame(height: contentHeight)
    }

    // 🔽 기존 for 루프를 함수로 뺀 것뿐 (내용은 동일)
    private func drawHeatmap(ctx: GraphicsContext) {
      for (col, weekStart) in weekStarts.enumerated() {
        let x = CGFloat(col) * (cell + gap)

        if containsFirstOfMonth(weekStart) {
          let lineRect = CGRect(x: x - gap * 0.5, y: 0, width: 1, height: contentHeight)
          ctx.fill(Path(roundedRect: lineRect, cornerRadius: 0.5),
                   with: .color(.gray.opacity(0.25)))
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
  
  // 해당 주에 1일이 포함돼있는지 체크
  private func containsFirstOfMonth(_ weekStart: Date) -> Bool {
    for d in 0..<7 {
      guard let day = cal.date(byAdding: .day, value: d, to: weekStart) else {
        continue
      }
      if cal.component(.day, from: day) == 1 { return true }
    }
    return false
  }
}

// 바텀시트처럼 연도 고르는 뷰
private struct YearBottomPickerOverlay: View {
  let years: [Int]            // 선택 가능한 연도 목록
  @Binding var selection: Int // 지금 선택된 연도
  @Binding var isPresented: Bool // 보여지는지 여부
  
  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .bottom) {
        // 뒤 배경 (검은 반투명) - 탭하면 닫힘
        Color.black.opacity(0.25)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) { isPresented = false }
          }
        
        // 바텀시트 본체
        VStack(spacing: 12) {
          // 상단 버튼 영역
          HStack {
            Button("취소") {
              withAnimation(.snappy(duration: 0.2)) { isPresented = false }
            }
            .font(.body)
            
            Spacer()
            Text("연도 선택").font(.headline)
            Spacer()
            Color.clear.frame(width: 44, height: 1) // 균형 맞추기용
          }
          .padding(.horizontal, 20)
          .padding(.top, 16)
          
          // 연도 리스트
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
            .contentMargins(
              .bottom,
              geo.safeAreaInsets.bottom + 24,
              for: .scrollContent
            )
          }
          Spacer(minLength: 0)
        }
        .frame(height: geo.size.height / 1.5) // 높이 절반 정도
        .frame(maxWidth: .infinity)
        .contentMargins(
          .bottom,
          geo.safeAreaInsets.bottom + 24,
          for: .scrollContent
        )
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

// 메모 통계 보여주는 뷰 (카드 형태)
private struct MemoStatsSectionView: View {
  let dayCounts: [Date: Int] // 날짜별 메모 수
  
  // 전체 메모 개수
  private var totalMemoCount: Int {
    dayCounts.values.reduce(0, +)
  }
  
  // 이번달 메모 개수
  private var thisMonthMemoCount: Int {
    let cal = Calendar.current
    let now = Date()
    return dayCounts.reduce(0) { acc, pair in
      let (day, count) = pair
      return cal.isDate(day, equalTo: now, toGranularity: .month)
      ? acc + count : acc
    }
  }
  
  // 최근 7일 날짜 리스트
  private var last7Days: [Date] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    return (0..<7).reversed().compactMap { offset in
      cal.date(byAdding: .day, value: -offset, to: today)
    }
  }
  
  // 최근 7일 데이터용 모델
  struct DailyCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
  }
  
  // 최근 7일 실제 데이터
  private var last7Data: [DailyCount] {
    let cal = Calendar.current
    return last7Days.map { d in
      let key = cal.startOfDay(for: d)
      let count = dayCounts[key] ?? 0
      return DailyCount(date: key, count: count)
    }
  }
  
  // y축 눈금
  private let yTicks: [Double] = [5, 10, 15, 20].map(Double.init)
  
  // 월별 데이터용 모델
  struct MonthCount: Identifiable {
    let month: Int
    let count: Int
    var id: Int { month }
  }
  
  // 현재 연도
  private var currentYear: Int {
    Calendar.current.component(.year, from: Date())
  }
  
  // 연도 문자열 (쉼표 안 붙게)
  private var currentYearString: String { String(currentYear) }
  
  // 현재 월
  private var currentMonth: Int {
    Calendar.current.component(.month, from: Date())
  }
  
  // 1월 ~ 이번달까지 배열
  private var monthsUpToNow: [Int] { Array(1...currentMonth) }
  
  // 올해 월별 데이터
  private var thisYearMonthlyData: [MonthCount] {
    let cal = Calendar.current
    var map: [Int: Int] = [:]
    for (day, c) in dayCounts {
      let comps = cal.dateComponents([.year, .month], from: day)
      if comps.year == currentYear, let m = comps.month {
        map[m, default: 0] += c
      }
    }
    return monthsUpToNow.map { m in MonthCount(month: m, count: map[m] ?? 0) }
  }
  
  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 16) {
        Text("회고 통계")
          .font(.title3.weight(.semibold))
        
        // 총 메모수 / 이번달 메모수
        SettingsCard {
          HStack(spacing: 12) {
            StatCard(title: "총 메모수", value: "\(totalMemoCount)")
            StatCard(title: "이번달 작성한 횟수", value: "\(thisMonthMemoCount)")
          }
        }
        
        // 최근 1주 막대 차트
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            Text("최근 1주 추이")
              .font(.headline)
            Last7BarChartAlwaysLabeled(
              data: last7Data,
              tickValues: yTicks
            )
            .frame(height: 180)
          }
        }
        
        // 올해 월별 라인 차트
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            Text("\(currentYearString)년 월별 추이")
              .font(.headline)
            
            YearMonthlyLineChartAlwaysLabeled(
              data: thisYearMonthlyData,
              monthsUpToNow: monthsUpToNow,
              currentMonth: currentMonth
            )
            .frame(height: 200)
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 16)
    }
  }
}

// 최근 1주 막대 차트
private struct Last7BarChartAlwaysLabeled: View {
  let data: [MemoStatsSectionView.DailyCount]
  let tickValues: [Double]
  
  var body: some View {
    Chart(data) { item in
      BarMark(
        x: .value("날짜", item.date, unit: .day),
        y: .value("횟수", item.count)
      )
      // 막대 위에 숫자 표시 (0은 안 보이게)
      .annotation(position: .top, alignment: .center) {
        if item.count > 0 {
          Text(item.count, format: .number)
            .font(.caption.bold())
            .foregroundStyle(.primary)
            .padding(.bottom, 2)
        }
      }
    }
    .chartYScale(domain: 0...20)
    .chartYTicks([5, 10, 15, 20])
    
    .chartXAxis {
      let xs: [Date] = data.map { $0.date }
      AxisMarks(values: xs) { value in
        AxisGridLine().foregroundStyle(.clear)
        AxisTick()
        AxisValueLabel(format: .dateTime.day()) // x축 날짜
      }
    }
  }
}

// 올해 월별 라인 차트
private struct YearMonthlyLineChartAlwaysLabeled: View {
  let data: [MemoStatsSectionView.MonthCount]
  let monthsUpToNow: [Int]
  let currentMonth: Int
  
  var body: some View {
    Chart {
      ForEach(data) { item in
        LineMark(
          x: .value("월", item.month),
          y: .value("횟수", item.count)
        )
        PointMark(
          x: .value("월", item.month),
          y: .value("횟수", item.count)
        )
        // 점 위에 숫자 표시 (0은 안 보임)
        .annotation(position: .top, alignment: .center) {
          if item.count > 0 {
            Text(item.count, format: .number)
              .font(.caption.bold())
              .foregroundStyle(.primary)
              .padding(.bottom, 2)
          }
        }
      }
      
      // 현재 달이 0일 때 라벨만 보이게 처리
      if let last = data.last, last.month == currentMonth, last.count == 0 {
        PointMark(x: .value("월", currentMonth), y: .value("횟수", 0))
          .foregroundStyle(.clear)
          .annotation(position: .bottom) { Text("\(currentMonth)월") }
      }
    }
    .chartXScale(domain: 0.5...Double(currentMonth) + 1.0) // x축 여유
    .chartPlotStyle { plot in
      plot.padding(.trailing, 40)
    }
    .chartXAxis {
      let xs: [Int] = Array(1...currentMonth)
      AxisMarks(values: xs) { v in
        AxisGridLine().foregroundStyle(.clear)
        AxisTick()
        if let m = v.as(Int.self) {
          AxisValueLabel {
            if m == currentMonth {
              Text("\(m)월").font(.caption.bold()).foregroundStyle(.primary)
            } else {
              Text("\(m)월").font(.caption).foregroundStyle(.secondary)
            }
          }
        }
      }
    }
    .chartYScale(domain: 0...20)
    .chartYTicks([5, 10, 15, 20])
  }
}

// 작은 통계 카드 (제목 + 값)
private struct StatCard: View {
  let title: String
  let value: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
      Text(value)
        .font(.title2.weight(.bold))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(14)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(0.06))
    )
  }
}

// 키워드 통계 카드 (도넛, 막대)
private struct KeywordStatsSectionView: View {
  // 누적(막대용)
  let countTags: [String: Int]
  // 기간 필터 집계(도넛용)
  let memos: [Memo]
  
  // 도넛 기간 필터
  private enum Period: String, CaseIterable, Identifiable {
    case year = "이번 년도"
    case month = "이번 달"
    case week = "1주일"
    var id: String { rawValue }
  }
  @State private var selectedPeriod: Period = .year
  
  // 막대 전체보기 토글
  @State private var showAllBars: Bool = false
  
  // 색상 규칙
  private let rankColors: [Color] = [.red, .yellow, .green, .blue]
  private let othersColor: Color = .gray
  
  // 전체 키워드 총합
  private var totalKeywordAllTime: Int {
    countTags.values.reduce(0, +)
  }
  
  // 도넛: 선택한 기간의 태그 집계
  private var filteredCountTags: [String: Int] {
    let cal = Calendar.current
    let now = Date()
    let start: Date = {
      switch selectedPeriod {
      case .year:
        return cal.date(from: DateComponents(year: cal.component(.year, from: now), month: 1, day: 1)) ?? cal.startOfDay(for: now)
      case .month:
        return cal.date(from: DateComponents(year: cal.component(.year, from: now), month: cal.component(.month, from: now), day: 1)) ?? cal.startOfDay(for: now)
      case .week:
        let today = cal.startOfDay(for: now)
        return cal.date(byAdding: .day, value: -6, to: today) ?? today
      }
    }()
    let end = now
    
    var map: [String: Int] = [:]
    for memo in memos where memo.day >= start && memo.day <= end {
      for t in memo.tags where !t.isEmpty {
        map[t, default: 0] += 1
      }
    }
    return map
  }
  
  // 도넛 데이터 정렬
  private var donutSortedAll: [(String, Int)] {
    filteredCountTags.sorted { l, r in
      if l.value == r.value { return l.key < r.key }
      return l.value > r.value
    }
  }
  private var donutTop4: [(String, Int)] { Array(donutSortedAll.prefix(4)) }
  private var donutSumTop4: Int { donutTop4.reduce(0) { $0 + $1.1 } }
  private var donutTotal: Int { filteredCountTags.values.reduce(0, +) }
  private var donutOthers: Int { max(donutTotal - donutSumTop4, 0) }
  
  // 차트 슬라이스
  private struct Slice: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
  }
  
  // 도넛에 표시할 데이터
  private var donutSlices: [Slice] {
    var arr: [Slice] = []
    for (idx, p) in donutTop4.enumerated() {
      arr.append(Slice(name: p.0, count: p.1, color: rankColors[min(idx, rankColors.count - 1)]))
    }
    if donutOthers > 0 {
      arr.append(Slice(name: "기타", count: donutOthers, color: othersColor))
    }
    return arr
  }
  
  // 퍼센트 문자열
  private func percentString(_ count: Int) -> String {
    guard donutTotal > 0 else { return "0%" }
    let p = Double(count) / Double(donutTotal) * 100
    return String(format: "%.0f%%", p.rounded())
  }
  
  // 막대: 전체 데이터 정렬
  private var barSortedAll: [(String, Int)] {
    countTags.sorted { l, r in
      if l.value == r.value { return l.key < r.key }
      return l.value > r.value
    }
  }
  private var barTop4: [(String, Int)] { Array(barSortedAll.prefix(4)) }
  private var barOthers: Int { barSortedAll.dropFirst(4).reduce(0) { $0 + $1.1 } }
  
  // 상위 5 데이터
  private var barDataTop5: [Slice] {
    if barSortedAll.count < 5 {
      return barSortedAll.enumerated().map { idx, e in
        Slice(name: e.0, count: e.1, color: rankColors[min(idx, rankColors.count - 1)])
      }
    }
    
    var slices = barTop4.enumerated().map { idx, e in
      Slice(name: e.0, count: e.1, color: rankColors[min(idx, rankColors.count - 1)])
    }
    if barOthers > 0 {
      slices.append(Slice(name: "기타", count: barOthers, color: othersColor))
    }
    return slices
  }
  
  // 전체보기 데이터
  private var barDataAll: [Slice] {
    barSortedAll.enumerated().map { idx, e in
      let color = (idx < 4) ? rankColors[idx] : othersColor
      return Slice(name: e.0, count: e.1, color: color)
    }
  }
  
  // 실제 표시 데이터
  private var barDataEffective: [Slice] {
    showAllBars ? barDataAll : barDataTop5
  }
  
  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 16) {
        Text("키워드 통계")
          .font(.title3.weight(.semibold))
        
        // 도넛 차트 카드
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("키워드 비중")
                .font(.headline)
              Spacer()
              Picker("기간", selection: $selectedPeriod) {
                ForEach(Period.allCases) { p in
                  Text(p.rawValue).tag(p)
                }
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
                Chart(donutSlices) { item in
                  SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.6))
                    .foregroundStyle(item.color)
                    .cornerRadius(2)
                }
                .frame(height: 220)
              }
              .overlay(alignment: .center) {
                if donutTotal > 0 {
                  VStack(spacing: 2) {
                    Text(selectedPeriod.rawValue)
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                    Text("총 \(donutTotal)")
                      .font(.title3.weight(.bold))
                  }
                }
              }
              
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
        
        // 막대 차트 카드
        SettingsCard {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
              Text("상위 4 키워드 (전체)")
                .font(.headline)
              Text("총 \(totalKeywordAllTime)")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
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
              Chart(barDataEffective) { item in
                BarMark(x: .value("횟수", item.count), y: .value("태그", item.name))
                  .foregroundStyle(item.color)
                  .annotation(position: .trailing) {
                    Text("\(item.count)")
                      .font(.caption.weight(.semibold))
                  }
              }
              .chartXAxis { AxisMarks(position: .bottom) }
              .chartYAxis { AxisMarks(position: .leading) }
              .chartPlotStyle { $0.padding(.trailing, 8) }
              .frame(height: max(44 * Double(max(barDataEffective.count, 1)), 140))
              
              HStack(spacing: 12) {
                legendDot(.red, "1위")
                legendDot(.yellow, "2위")
                legendDot(.green, "3위")
                legendDot(.blue, "4위")
                legendDot(.gray, showAllBars ? "그 외(개별)" : "기타")
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
  
  // 범례 dot
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
  
  // 초기화
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
  
  // 화면
  var body: some View {
    VStack(spacing: 12) {
      // 상단 버튼
      HStack {
        Button("취소", action: onCancel)
        Spacer()
        Text("년/월 선택").font(.headline)
        Spacer()
        Button("완료") {
          onConfirm(yearSelection, tempMonth)
        }
      }
      .padding(.horizontal)
      
      // 년/월 휠
      HStack {
        Picker("년도", selection: $yearSelection) {
          ForEach(years, id: \.self) { y in
            Text(String(y) + "년").tag(y)
          }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        
        Picker("월", selection: $tempMonth) {
          ForEach(months, id: \.self) { m in
            Text(String(format: "%02d월", m)).tag(m)
          }
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


private struct DayMemoListSheet: View {
  let date: Date
  @Binding var memos: [Memo]
  
  // 날짜 키
  private var dateKey: Date { Calendar.current.startOfDay(for: date) }
  
  // 해당 날짜 메모 필터링
  private var filteredMemos: [Memo] {
    let cal = Calendar.current
    return memos.filter { cal.startOfDay(for: $0.day) == dateKey }
  }
  
  // 화면
  var body: some View {
    NavigationStack {
      List {
        if filteredMemos.isEmpty {
          Text("이 날짜의 회고가 없습니다.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(filteredMemos) { memo in
            NavigationLink {
              TexteditView(memos: $memos, memoToEdit: memo)
            } label: {
              VStack(alignment: .leading, spacing: 6) {
                // 태그 표시
                let tags = memo.tags.filter { !$0.isEmpty }
                if !tags.isEmpty {
                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                      ForEach(tags, id: \.self) { t in
                        Text(t)
                          .font(.footnote.weight(.semibold))
                          .padding(.horizontal, 10)
                          .padding(.vertical, 6)
                          .foregroundStyle(.white)
                          .background(Capsule().fill(Color.accentColor))
                      }
                    }
                  }
                }
                // 제목
                Text(memo.title)
                  .font(.headline)
                  .foregroundStyle(.primary)
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
    // 메모 변경 감지
    .onChange(of: memos) { latest in
      NotificationCenter.default.post(
        name: .memosDidChange,
        object: nil,
        userInfo: ["memos": latest]
      )
    }
  }
  
  // 날짜 포맷
  private func formattedTitle(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyy. MM. dd"
    return f.string(from: d)
  }
}


struct SettingsCard<Content: View>: View {
  @ViewBuilder var content: Content
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      content
        .environment(\.colorScheme, .light)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Color.white, lineWidth: 1)
    )
  }
}


#Preview {
  ChartView(markedDates: [], countTags: [:], dayCounts: [:], memos: [])
    .environment(\.locale, Locale(identifier: "ko_KR"))
}
