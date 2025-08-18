//
//  ChartViewComponent.swift
//  Review
//
//  Created by 송영민 on 8/18/25.
//

import SwiftUI

// MARK: - Shared model
struct NativeSlice: Identifiable, Hashable {
  let id = UUID()
  var name: String
  var count: Int
  var color: Color
}

// MARK: - Trailing Y Axis (grid + labels)
struct TrailingYAxis: View {
  var ticks: [Int] = [5,10,15,20]
  var yMax: Int = 20
  var body: some View {
    GeometryReader { geo in
      let h = max(geo.size.height, 1)
      ZStack(alignment: .trailing) {
        ForEach(ticks, id: \.self) { t in
          let ratio = CGFloat(t) / CGFloat(max(yMax, 1))
          let y = (1 - ratio) * h
          Path { p in
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: geo.size.width, y: y))
          }
          .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
          .allowsHitTesting(false)
          
          Text("\(t)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .position(x: geo.size.width - 2, y: y - 8)
            .allowsHitTesting(false)
        }
      }
    }
  }
}

// MARK: - Last 7 Days Bar (Vertical)
struct Last7BarChartNative: View {
  struct Item: Identifiable {
    var id: Date { date }
    var date: Date
    var count: Int
  }
  
  private var data: [Item]
  private var ticks: [Int]
  private var yMax: Int = 20 // fixed
  
  init(data: [Item], tickValues: [Double] = [5,10,15,20]) {
    self.data = data
    self.ticks = tickValues.map(Int.init)
  }
  
  var body: some View {
    GeometryReader { geo in
      let W = geo.size.width
      let H = geo.size.height
      let rightPad: CGFloat = 30
      let xLabelH: CGFloat = 20
      let topPad: CGFloat = 2
      let chartH = max(H - xLabelH - topPad, 1)
      let spacing: CGFloat = 8
      let count = max(data.count, 1)
      let totalSpacing = spacing * CGFloat(max(count - 1, 0))
      let plotW = max(W - rightPad - totalSpacing, 1)
      let barW = max(plotW / CGFloat(count), 8)
      
      ZStack(alignment: .bottomLeading) {
        TrailingYAxis(ticks: ticks, yMax: yMax)
          .frame(width: W, height: chartH)
          .padding(.trailing, rightPad)
          .offset(y: topPad)
        
        HStack(alignment: .bottom, spacing: spacing) {
          ForEach(data) { it in
            let h = CGFloat(it.count) / CGFloat(max(yMax, 1)) * chartH
            VStack(spacing: 4) {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor)
                .frame(width: barW, height: max(h, 0))
                .overlay(alignment: .top) {
                  if it.count > 0 {
                    Text("\(it.count)")
                      .font(.caption.bold())
                      .padding(.bottom, 2)
                  }
                }
              Text(it.date, format: .dateTime.day())
                .font(.caption2)
                .frame(height: xLabelH)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
          }
        }
        .padding(.trailing, rightPad)
        .offset(y: topPad)
      }
    }
  }
}

// MARK: - Monthly Line (1..currentMonth)
struct MonthlyLineChartNative: View {
  struct Item: Identifiable {
    var id: Int { month }
    var month: Int
    var count: Int
  }
  
  private var data: [Item]
  private var currentMonth: Int
  private var ticks: [Int]
  private var yMax: Int = 20 // fixed
  
  init(data: [Item], currentMonth: Int, tickValues: [Double] = [5,10,15,20]) {
    self.data = data
    self.currentMonth = max(currentMonth, 1)
    self.ticks = tickValues.map(Int.init)
  }
  
  var body: some View {
    GeometryReader { geo in
      let W = geo.size.width
      let H = geo.size.height
      let leftPad: CGFloat = 0
      let rightPad: CGFloat = 40
      let bottom: CGFloat = 20
      let top: CGFloat = 4
      let plotW = max(W - rightPad - leftPad, 1)
      let plotH = max(H - bottom - top, 1)
      let step = plotW / CGFloat(max(currentMonth - 1, 1))
      
      func xPos(_ m: Int) -> CGFloat {
        guard currentMonth > 1 else { return leftPad + plotW / 2 }
        return leftPad + CGFloat(m - 1) * step
      }
      func yPos(_ c: Int) -> CGFloat {
        let ratio = CGFloat(c) / CGFloat(max(yMax, 1))
        return top + (1 - ratio) * plotH
      }
      
      ZStack(alignment: .bottomLeading) {
        TrailingYAxis(ticks: ticks, yMax: yMax)
          .frame(width: W, height: plotH)
          .padding(.trailing, rightPad)
          .offset(y: top)
        
        Path { p in
          guard let first = data.first else { return }
          p.move(to: CGPoint(x: xPos(first.month), y: yPos(first.count)))
          for it in data.dropFirst() {
            p.addLine(to: CGPoint(x: xPos(it.month), y: yPos(it.count)))
          }
        }
        .stroke(Color.accentColor, lineWidth: 2)
        
        ForEach(data) { it in
          let pt = CGPoint(x: xPos(it.month), y: yPos(it.count))
          Circle().fill(Color.accentColor).frame(width: 6, height: 6)
            .position(pt)
            .overlay(alignment: .top) {
              if it.count > 0 {
                Text("\(it.count)")
                  .font(.caption.bold())
                  .padding(.bottom, 2)
                  .offset(y: -10)
              }
            }
        }
        
        HStack(spacing: 0) {
          ForEach(1...currentMonth, id: \.self) { m in
            Text("\(m)월")
              .font(m == currentMonth ? .caption.bold() : .caption)
              .foregroundStyle(m == currentMonth ? .primary : .secondary)
              .frame(maxWidth: .infinity)
          }
        }
        .frame(width: plotW, height: bottom)
        .position(x: leftPad + plotW / 2, y: H - bottom / 2)
      }
    }
  }
}

// MARK: - Donut (Top4 + Others)
struct DonutChartNative: View {
  var slices: [NativeSlice]
  var innerRatio: CGFloat = 0.6
  
  init(slices: [NativeSlice], innerRatio: CGFloat = 0.6) {
    self.slices = slices; self.innerRatio = innerRatio
  }
  
  private var total: Double { max(Double(slices.reduce(0) { $0 + $1.count }), 0) }
  
  var body: some View {
    GeometryReader { geo in
      let size = min(geo.size.width, geo.size.height)
      let sum = max(total, 1)
      var start = Angle.degrees(-90)
      var angles: [(start: Angle, end: Angle)] = []
      for s in slices {
        let frac = Double(s.count) / sum
        let end = start + .degrees(frac * 360)
        angles.append((start: start, end: end))
        start = end
      }
      
      ZStack {
        ForEach(slices.indices, id: \.self) { i in
          let s = slices[i]
          let a = angles[i]
          RingSlice(startAngle: a.start, endAngle: a.end, innerRatio: innerRatio)
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

struct RingSlice: Shape {
  var startAngle: Angle
  var endAngle: Angle
  var innerRatio: CGFloat = 0.6
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outerR = min(rect.width, rect.height) / 2
    let innerR = outerR * innerRatio
    var p = Path()
    p.addArc(center: center, radius: outerR, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    p.addLine(to: CGPoint(x: center.x + innerR * CGFloat(cos(endAngle.radians)), y: center.y + innerR * CGFloat(sin(endAngle.radians))))
    p.addArc(center: center, radius: innerR, startAngle: endAngle, endAngle: startAngle, clockwise: true)
    p.closeSubpath()
    return p
  }
}

// MARK: - Horizontal Bar List (for Keywords)
struct HBarListNative: View {
  var items: [NativeSlice]
  
  var body: some View {
    let maxV = max(items.map { $0.count }.max() ?? 1, 1)
    VStack(spacing: 8) {
      ForEach(items) { it in
        HStack(spacing: 8) {
          Text(it.name)
            .font(.subheadline)
            .lineLimit(1)
            .frame(width: 64, alignment: .leading)
          GeometryReader { geo in
            let w = geo.size.width
            let ratio = CGFloat(it.count) / CGFloat(maxV)
            ZStack(alignment: .leading) {
              Capsule().fill(Color(.systemGray6))
              Capsule().fill(it.color).frame(width: max(w * ratio, 4))
            }
          }
          .frame(height: 16)
          Text("\(it.count)")
            .font(.caption.weight(.semibold))
            .frame(width: 36, alignment: .trailing)
        }
        .frame(height: 24)
      }
    }
  }
}
