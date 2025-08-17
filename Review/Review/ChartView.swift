//
//  ChartView.swift
//  Segmented (3 tabs) + Month Calendar + Year Heatmap — iOS 17+
//

import SwiftUI
import Charts

// 탭 구분
private enum ChartSegment: String, CaseIterable, Identifiable {
    case history = "회고 이력"
    case memoStats = "회고 통계"
    case keywordStats = "키워드 통계"
    var id: String { rawValue }
}

// 시트 식별 아이템
private struct SheetDate: Identifiable, Equatable {
    let date: Date
    var id: Double { Calendar.current.startOfDay(for: date).timeIntervalSince1970 }
}

// ✅ Notification.Name 확장 (외부 BroadCast용)
extension Notification.Name {
    static let memosDidChange = Notification.Name("memosDidChange")
}

struct ChartView: View {
    @Environment(\.colorScheme) private var colorScheme

    // 호출부 호환용 시그니처(원본 유지)
    private let markedDatesInput: Set<Date>
    private let countTagsInput: [String: Int]
    private let dayCountsInput: [Date: Int]
    private let memosInput: [Memo]

    @State private var selectedSegment: ChartSegment = .history
    @State private var workingMemos: [Memo]

    init(markedDates: Set<Date>, countTags: [String: Int], dayCounts: [Date: Int], memos: [Memo]) {
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

                // 탭 컨텐츠
                switch selectedSegment {
                case .history:
                    HistorySectionView(memos: $workingMemos)
                case .memoStats:
                    MemoStatsSectionView(dayCounts: dayCountsInput)
                case .keywordStats:
                  KeywordStatsSectionView(countTags: countTagsInput, memos: workingMemos)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // 배경: 다크=완전 블랙, 라이트=systemGray6
        .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
        // 외부에서 최신 memos 페이로드 반영
        .onReceive(NotificationCenter.default.publisher(for: .memosDidChange)) { note in
            if let latest = note.userInfo?["memos"] as? [Memo] {
                self.workingMemos = latest
            }
        }
    }
}

// MARK: - 회고 이력(달력 카드 + 연간 히트맵 카드 + 커스텀 바텀시트)
private struct HistorySectionView: View {
    @Binding var memos: [Memo]

    @State private var baseDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date? = nil
    @State private var showYearMonthPicker = false

    // ✅ 월 캘린더 → Day 리스트 시트 (복구)
    @State private var sheetItem: SheetDate? = nil

    // 히트맵 연도 & 커스텀 오버레이 상태
    @State private var heatmapYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showYearPicker = false

    // 날짜별 개수 (startOfDay 키)
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
        f.dateFormat = "yyyy년 MM월"  // ← 반드시 소문자 yyyy
        return f.string(from: baseDate)
    }

    // 최근 연도 목록(올해 포함) — 현재 10년
    private var recentYears: [Int] {
        let cur = Calendar.current.component(.year, from: Date())
        return (0..<10).map { cur - $0 }
    }

    var body: some View {
        let content =
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                Text("회고 이력")
                    .font(.title3.weight(.semibold))

                // 카드 1: 월 달력
                SettingsCard {
                    MonthHeader(
                        title: titleString,
                        onPrev: { changeMonth(by: -1) },
                        onNext: { changeMonth(by: +1) },
                        onTitleTap: { showYearMonthPicker = true }
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

                // 카드 2: 연간 히트맵 (버튼 → 부모 오버레이 오픈)
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
}

// 월 헤더
private struct MonthHeader: View {
    let title: String
    let onPrev: () -> Void
    let onNext: () -> Void
    let onTitleTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left").bold()
                    .frame(width: 44, height: 44)
            }
            Spacer(minLength: 0)
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

// 달력 그리드 (선택 + 더블탭 시트)
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

        let firstWeekday = cal.component(.weekday, from: firstDay) // 1=일
        var arr: [Date?] = Array(repeating: nil, count: max(firstWeekday - 1, 0))
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: firstDay) {
                arr.append(date)
            }
        }
        while arr.count < 42 { arr.append(nil) } // 6주 고정
        return arr
    }

    private let dayWeeks: [String] = ["일","월","화","수","목","금","토"]

    var body: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    Text(dayWeeks[idx])
                        .font(.system(size: 14))
                        .foregroundColor(idx == 0 ? .red : (idx == 6 ? .blue : .primary))
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
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
                        .onTapGesture { selectedDate = date }              // 단일 탭: 선택
                        .onTapGesture(count: 2) { onDoubleTap(date) }      // 더블 탭: 시트
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .padding(.bottom, 4)
        }
    }
}

// 날짜 셀
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

// MARK: - 연간 히트맵 카드 (연도 버튼만; 오버레이는 부모가 띄움)
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
                        Text(verbatim: "\(year)년") // 고정 문자열(쉼표 X)
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

            YearHeatmapCanvas(year: year, countsByDay: countsByDay)
                .frame(height: 140)
        }
    }
}

// MARK: - 히트맵 Canvas 본체(이진 색상, 월 경계선만)
private struct YearHeatmapCanvas: View {
    let year: Int
    let countsByDay: [Date: Int]

    private let cal = Calendar.current
    private let cell: CGFloat = 14
    private let gap: CGFloat = 4
    private let corner: CGFloat = 3
    private let strokeWidth: CGFloat = 0.5

    private func startOfWeek(for date: Date) -> Date {
        let weekday = cal.component(.weekday, from: date) // 1=일
        return cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: date))!
    }
    private func endOfWeek(for date: Date) -> Date {
        let weekday = cal.component(.weekday, from: date)
        return cal.date(byAdding: .day, value: (7 - weekday), to: cal.startOfDay(for: date))!
    }

    private var startOfYear: Date { cal.date(from: DateComponents(year: year, month: 1, day: 1))! }
    private var endOfYearExclusive: Date { cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))! }

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
        GeometryReader { _ in
            ScrollView(.horizontal, showsIndicators: false) {
                Canvas { ctx, _ in
                    for (col, weekStart) in weekStarts.enumerated() {
                        let x = CGFloat(col) * (cell + gap)

                        // 월 경계선(주에 1일이 포함되면 세퍼레이터)
                        if containsFirstOfMonth(weekStart) {
                            let lineRect = CGRect(x: x - gap * 0.5, y: 0, width: 1, height: contentHeight)
                            ctx.fill(Path(roundedRect: lineRect, cornerRadius: 0.5), with: .color(.gray.opacity(0.25)))
                        }

                        for row in 0..<7 {
                            guard let day = cal.date(byAdding: .day, value: row, to: weekStart) else { continue }
                            if !(startOfYear ..< endOfYearExclusive).contains(day) { continue }

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
                .frame(width: contentWidth, height: contentHeight)
                .accessibilityHidden(true)
            }
            .frame(height: contentHeight)
        }
        .frame(height: contentHeight)
    }

    private func containsFirstOfMonth(_ weekStart: Date) -> Bool {
        for d in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: d, to: weekStart) else { continue }
            if cal.component(.day, from: day) == 1 { return true }
        }
        return false
    }
}

// ✅ 커스텀 바텀시트 오버레이 (밖 탭 닫힘, 고정, 위 여백, 바닥 여백)
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

// MARK: - 회고 통계 (카드) — 리팩터 + 숫자 항상 표기
private struct MemoStatsSectionView: View {
    let dayCounts: [Date: Int]

    // 전체 메모 수(누적)
    private var totalMemoCount: Int {
        dayCounts.values.reduce(0, +)
    }

    // 이번달 작성한 횟수
    private var thisMonthMemoCount: Int {
        let cal = Calendar.current
        let now = Date()
        return dayCounts.reduce(0) { acc, pair in
            let (day, count) = pair
            return cal.isDate(day, equalTo: now, toGranularity: .month) ? acc + count : acc
        }
    }

    // 최근 7일 데이터 -------------------------------------------------
    private var last7Days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
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
            let count = dayCounts[key] ?? 0
            return DailyCount(date: key, count: count)
        }
    }
    private let yTicks: [Double] = [5, 10, 15, 20].map(Double.init)

    // 올해 월별 데이터 ------------------------------------------------
    struct MonthCount: Identifiable {
        let month: Int   // 1~12
        let count: Int
        var id: Int { month }
    }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentYearString: String { String(currentYear) } // ← 쉼표 없는 문자열
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
        return monthsUpToNow.map { m in MonthCount(month: m, count: map[m] ?? 0) }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                Text("회고 통계")
                    .font(.title3.weight(.semibold))

                // 카드 1: 총/이번달
                SettingsCard {
                    HStack(spacing: 12) {
                        StatCard(title: "이제까지 총 메모수", value: "\(totalMemoCount)")
                        StatCard(title: "이번달 작성한 횟수", value: "\(thisMonthMemoCount)")
                    }
                }

                // 카드 2: 최근 1주 막대 차트 (숫자 항상 표시)
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

                // 카드 3: 올해 월별 라인 차트 (숫자 항상 표시, 1~현재월 라벨 보장)
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        // ✅ 연도는 문자열로 직접 출력(쉼표 방지)
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

// ✅ 최근 1주 막대 차트 — 막대 "가운데 위"에 숫자만 표시 (0일은 숨김)
private struct Last7BarChartAlwaysLabeled: View {
    let data: [MemoStatsSectionView.DailyCount]
    let tickValues: [Double]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("날짜", item.date, unit: .day),
                y: .value("횟수", item.count)
            )
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
        .chartYAxis {
            AxisMarks(position: .trailing, values: tickValues) { v in
                AxisGridLine()
                AxisTick()
                if let dv = v.as(Double.self) {
                    AxisValueLabel { Text(Int(dv), format: .number) }
                }
            }
        }
        .chartXAxis {
            let xs: [Date] = data.map { $0.date }
            AxisMarks(values: xs) { value in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
    }
}

// ✅ 올해 월별 라인 차트 — 각 점 위에 항상 숫자 표시 + 현재월 라벨 보장
// ✅ 올해 월별 라인 차트 — 각 점 위에 "숫자만" 표시 (가운데 위, 0이면 숨김)
// ✅ 올해 월별 라인 차트 — 각 점 위에 "숫자만" 표시(0이면 숨김) + 현재달 라벨/공간 보장
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
                // ✅ 0이면 숨기고, 값이 있을 때만 점 "가운데 위"에 숫자 표시
                .annotation(position: .top, alignment: .center) {
                    if item.count > 0 {
                        Text(item.count, format: .number)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .padding(.bottom, 2)
                    }
                }
            }

            // (옵션) 현재월이 0이어도 X축에 라벨이 보이도록 보강
            if let last = data.last, last.month == currentMonth, last.count == 0 {
                PointMark(x: .value("월", currentMonth), y: .value("횟수", 0))
                    .foregroundStyle(.clear)
                    .annotation(position: .bottom) { Text("\(currentMonth)월") }
            }
        }
        // ✅ X축: 끝단 여유를 두어 현재월 라벨/마커가 잘리지 않게
        .chartXScale(domain: 0.5 ... Double(currentMonth) + 1.0)
        .chartPlotStyle { plot in
            plot.padding(.trailing, 40)
        }
        .chartXAxis {
            // ✅ 항상 1~현재월까지 강제 노출
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
        // Y축: 0~20, 5 단위
        .chartYScale(domain: 0...20)
        .chartYAxis {
            let ticks: [Double] = [5, 10, 15, 20].map(Double.init)
            AxisMarks(position: .trailing, values: ticks) { value in
                AxisGridLine(); AxisTick()
                if let dv = value.as(Double.self) {
                    AxisValueLabel { Text(Int(dv), format: .number) }
                }
            }
        }
    }
}

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

// MARK: - 키워드 통계 (카드) — 도넛은 기간 필터, 막대는 누적 + [전체보기] 토글
private struct KeywordStatsSectionView: View {
    let countTags: [String: Int]   // 누적(막대용)
    let memos: [Memo]              // 기간 필터 집계(도넛용)

    // 도넛 기간 필터
    private enum Period: String, CaseIterable, Identifiable {
        case year = "전체년도", month = "이번 달", week = "1주일"
        var id: String { rawValue }
    }
    @State private var selectedPeriod: Period = .year

    // 막대 전체보기 토글
    @State private var showAllBars: Bool = false

    // 색상 규칙
    private let rankColors: [Color] = [.red, .yellow, .green, .blue]
    private let othersColor: Color = .gray

    // "전체년도" 선택 여부 (도넛 중앙 라벨 노출 조건)
  //  private var isYearSelected: Bool { selectedPeriod == .year }

    // MARK: - 도넛: 기간 필터 집계
    private var filteredCountTags: [String: Int] {
        let cal = Calendar.current
        let now = Date()
        let start: Date = {
            switch selectedPeriod {
            case .year:
                return cal.date(from: DateComponents(year: cal.component(.year, from: now), month: 1, day: 1))
                ?? cal.startOfDay(for: now)
            case .month:
                return cal.date(from: DateComponents(year: cal.component(.year, from: now),
                                                     month: cal.component(.month, from: now), day: 1))
                ?? cal.startOfDay(for: now)
            case .week:
                let today = cal.startOfDay(for: now)
                return cal.date(byAdding: .day, value: -6, to: today) ?? today // 오늘 포함 7일
            }
        }()
        let end = now

        // 기간 내 메모만 선택 → 태그 집계
        var map: [String: Int] = [:]
        for memo in memos where memo.day >= start && memo.day <= end {
            for t in memo.tags where !t.isEmpty {
                map[t, default: 0] += 1
            }
        }
        return map
    }

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

    private struct Slice: Identifiable { let id = UUID(); let name: String; let count: Int; let color: Color }

    private var donutSlices: [Slice] {
        var arr: [Slice] = []
        for (idx, p) in donutTop4.enumerated() {
            arr.append(Slice(name: p.0, count: p.1, color: rankColors[min(idx, rankColors.count - 1)]))
        }
        if donutOthers > 0 { arr.append(Slice(name: "기타", count: donutOthers, color: othersColor)) }
        return arr
    }

    private func percentString(_ count: Int) -> String {
        guard donutTotal > 0 else { return "0%" }
        let p = Double(count) / Double(donutTotal) * 100
        return String(format: "%.0f%%", p.rounded())
    }

    // MARK: - 막대: 누적 상위5 (상위4 + 기타) + 전체보기
    private var barSortedAll: [(String, Int)] {
        countTags.sorted { l, r in
            if l.value == r.value { return l.key < r.key }
            return l.value > r.value
        }
    }
    private var barTop4: [(String, Int)] { Array(barSortedAll.prefix(4)) }
    private var barOthers: Int { barSortedAll.dropFirst(4).reduce(0) { $0 + $1.1 } }

    // 상위5(= 상위4 + 기타)
    private var barDataTop5: [Slice] {
        if barSortedAll.count >= 5 {
            var arr: [Slice] = []
            for (idx, p) in barTop4.enumerated() {
                arr.append(Slice(name: p.0, count: p.1, color: rankColors[min(idx, rankColors.count - 1)]))
            }
            if barOthers > 0 { arr.append(Slice(name: "기타", count: barOthers, color: othersColor)) }
            return arr
        } else {
            return barSortedAll.enumerated().map { idx, e in
                Slice(name: e.0, count: e.1, color: rankColors[min(idx, rankColors.count - 1)]) }
        }
    }

    // 전체보기: 모든 태그를 개별 막대로(상위4는 고유색, 나머지는 회색)
    private var barDataAll: [Slice] {
        barSortedAll.enumerated().map { idx, e in
            let color = (idx < 4) ? rankColors[idx] : othersColor
            return Slice(name: e.0, count: e.1, color: color)
        }
    }

    private var barDataEffective: [Slice] {
        showAllBars ? barDataAll : barDataTop5
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                Text("키워드 통계")
                    .font(.title3.weight(.semibold))

                // 카드 1: 도넛 — 기간 필터 적용 + 중앙에 "전체년도 총 N"
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
                                    SectorMark(
                                        angle: .value("Count", item.count),
                                        innerRadius: .ratio(0.6)
                                    )
                                    .foregroundStyle(item.color)
                                    .cornerRadius(2)
                                    .accessibilityLabel("\(item.name)")
                                    .accessibilityValue("\(item.count)건, \(percentString(item.count))")
                                    // 중앙 텍스트는 아래 overlay에서 고정 표시
                                }
                                .frame(height: 220)
                            }
                            // ⬇️ 도넛 정중앙에 "전체년도 총 N" 고정 표기
                            .overlay(alignment: .center) {
                                if donutTotal > 0 {
                                    VStack(spacing: 2) {
                                        Text(selectedPeriod.rawValue)          // 전체년도 / 이번 달 / 1주일
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("총 \(donutTotal)")               // 선택한 기간의 총 합계
                                            .font(.title3.weight(.bold))
                                    }
                                    .accessibilityHidden(true)
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

                // 카드 2: 가로 막대 — 누적 상위5 + [전체보기] 토글
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("상위 5 키워드 (누적)")
                                .font(.headline)
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
                                BarMark(
                                    x: .value("횟수", item.count),
                                    y: .value("태그", item.name)
                                )
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
                                legendDot(.red, "1위"); legendDot(.yellow, "2위")
                                legendDot(.green, "3위"); legendDot(.blue, "4위")
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

    @ViewBuilder
    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}


// MARK: - 년/월 휠 피커 (쉼표 없는 "2025년")
private struct YearMonthWheelPicker: View {
    @State private var tempYear: Int
    @State private var tempMonth: Int
    @State private var yearSelection: Int

    let onConfirm: (Int, Int) -> Void
    let onCancel: () -> Void

    private let years: [Int]
    private let months: [Int] = Array(1...12)

    init(selectedYear: Int, selectedMonth: Int,
         onConfirm: @escaping (Int, Int) -> Void,
         onCancel: @escaping () -> Void) {
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
                Button("완료") {
                    onConfirm(yearSelection, tempMonth)
                }
            }
            .padding(.horizontal)

            HStack {
                Picker("년도", selection: $yearSelection) {
                    ForEach(years, id: \.self) { y in
                        Text(String(y) + "년").tag(y)   // ← 쉼표 없이
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

// ✅ 월 캘린더 Day 리스트 시트 (간단/안정 버전)
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
                    Text("이 날짜의 회고가 없습니다.")
                        .foregroundStyle(.secondary)
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
        .onChange(of: memos) { latest in
            NotificationCenter.default.post(name: .memosDidChange, object: nil, userInfo: ["memos": latest])
        }
    }

    private func formattedTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy. MM. dd"
        return f.string(from: d)
    }
}

// MARK: - 카드 컴포넌트 (흰색 배경 + 흰색 테두리, 내부는 라이트 스킴 강제)
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

// MARK: - Preview
#Preview {
    ChartView(markedDates: [], countTags: [:], dayCounts: [:], memos: [])
        .environment(\.locale, Locale(identifier: "ko_KR"))
}
