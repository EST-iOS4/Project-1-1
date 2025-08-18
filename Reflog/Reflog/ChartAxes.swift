//
//  ChartAxes.swift
//  Review
//
//  Created by 송영민 on 8/18/25.
//

import SwiftUI
import Charts

extension View {
    /// 공통 Y축 눈금/그리드 (기본 오른쪽 축)
    func chartYTicks(_ ticks: [Double], trailing: Bool = true) -> some View {
        self.chartYAxis {
            AxisMarks(position: trailing ? .trailing : .leading, values: ticks) { value in
                AxisGridLine()
                AxisTick()
                if let dv = value.as(Double.self) {
                    AxisValueLabel { Text(Int(dv), format: .number) }
                }
            }
        }
    }
}
