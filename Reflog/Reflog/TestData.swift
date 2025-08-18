//
//  ChartViewComponent.swift
//  Review
//
//  Created by 송영민 on 8/18/25.
//

import Foundation

enum DummyData {
  static func generateLastYearDistributed(memosPerMonth: Int = 3) -> [Memo] {
    let cal = Calendar.current
    let now = Date()
    let lastYear = cal.component(.year, from: now) - 1
    var result: [Memo] = []
    for month in 1...12 {
      for _ in 0..<memosPerMonth {
        if let day = randomDate(year: lastYear, month: month, using: cal) {
          result.append(randomMemo(on: day))
        }
      }
    }
    return result
  }

  static func generateLastMonth(count: Int = 6) -> [Memo] {
    let cal = Calendar.current
    let now = Date()
    let comps = cal.dateComponents([.year, .month], from: cal.date(byAdding: .month, value: -1, to: now)!)
    guard let y = comps.year, let m = comps.month else { return [] }
    return (0..<count).compactMap { _ in
      guard let d = randomDate(year: y, month: m, using: cal) else { return nil }
      return randomMemo(on: d)
    }
  }

  static func generateThisMonth(count: Int = 4) -> [Memo] {
    let cal = Calendar.current
    let now = Date()
    let y = cal.component(.year, from: now)
    let m = cal.component(.month, from: now)
    return (0..<count).compactMap { _ in
      guard let d = randomDate(year: y, month: m, using: cal) else { return nil }
      return randomMemo(on: d)
    }
  }

  static func composeDemo(lastYearPerMonth: Int = 3,
                          lastMonthCount: Int = 6,
                          thisMonthCount: Int = 4) -> [Memo] {
    var arr: [Memo] = []
    arr += generateLastYearDistributed(memosPerMonth: lastYearPerMonth)
    arr += generateLastMonth(count: lastMonthCount)
    arr += generateThisMonth(count: thisMonthCount)
    return sortByDateDesc(arr)
  }

  static func generateRandomInYears(startYear: Int = 2022,
                                    endYear: Int = 2025,
                                    total: Int = 500) -> [Memo] {
    let cal = Calendar.current
    let start = cal.date(from: DateComponents(year: startYear, month: 1, day: 1)) ?? Date.distantPast
    let endCandidate = cal.date(from: DateComponents(year: endYear + 1, month: 1, day: 1)) ?? Date()
    let now = Date()
    let end = min(now, endCandidate)

    var result: [Memo] = []
    result.reserveCapacity(total)

    for _ in 0..<total {
      if let d = randomDate(between: start, and: end) {
        result.append(randomMemo(on: d))
      }
    }
    return sortByDateDesc(result)
  }

  private static func randomDate(year: Int, month: Int, using cal: Calendar) -> Date? {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = 1
    guard let first = cal.date(from: comps),
          let range = cal.range(of: .day, in: .month, for: first) else { return nil }
    comps.day = Int.random(in: range)
    comps.hour = Int.random(in: 9...21)
    comps.minute = [0, 15, 30, 45].randomElement()!
    return cal.date(from: comps)
  }

  private static func randomDate(between start: Date, and end: Date) -> Date? {
    let startTs = start.timeIntervalSince1970
    let endTs = end.timeIntervalSince1970
    guard endTs > startTs else { return nil }
    let r = Double.random(in: 0..<(endTs - startTs))
    return Date(timeIntervalSince1970: startTs + r)
  }

  private static let tagPool = ["업무","개인 업무","독서","운동","UI/UX","SwiftUI","알고리즘","공부","프로젝트","과일"]
  private static let titlePool = ["리서치 정리","아이디어 스케치","주간 회고","오늘의 목표","읽은 책 메모","트레이닝 기록","버그 리포트","UI 개선 포인트","코드 리팩터","장보기 목록"]
  private static let contentPool = ["간단한 내용 메모","세부 계획 수립","핵심 요약","회고 포인트 정리","다음 액션 아이템","메모 상세"]

  private static func randomMemo(on day: Date) -> Memo {
    let tagCount = Int.random(in: 1...2)
    let tags = Array(tagPool.shuffled().prefix(tagCount))
    let title = titlePool.randomElement()!
    let content = contentPool.randomElement()!
    return Memo(day: day, title: title, tags: tags, content: content)
  }

  private static func sortByDateDesc(_ arr: [Memo]) -> [Memo] {
    arr.sorted { l, r in
      if l.day != r.day { return l.day > r.day }
      return l.id.uuidString < r.id.uuidString
    }
  }
}

extension DummyData {
  static func generateFromYesterday(days: Int = 6, total: Int = 20) -> [Memo] {
    precondition(days > 0 && total >= 0, "days는 1 이상, total은 0 이상이어야 합니다.")
    let cal = Calendar.current
    let now = Date()
    let base = total / days
    let rem  = total % days
    let perDay: [Int] = (0..<days).map { i in base + (i < rem ? 1 : 0) }
    var result: [Memo] = []
    result.reserveCapacity(total)
    for (i, count) in perDay.enumerated() {
      guard let baseDate = cal.date(byAdding: .day, value: -(i + 1), to: now) else { continue }
      let dayStart = cal.startOfDay(for: baseDate)
      for j in 0..<count {
        let ts = cal.date(byAdding: .minute, value: j, to: dayStart) ?? dayStart
        result.append(randomMemo(on: ts))
      }
    }
    return sortByDateDesc(result)
  }

  static func composeDemoArrays(_ arr: [Memo]) -> [Memo] {
    sortByDateDesc(arr)
  }
}
