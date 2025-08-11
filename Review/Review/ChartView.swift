//
//  ChartView.swift
//  Review
//
//  Created by 송영민 on 8/11/25.
//

import SwiftUI

struct ChartView: View {
  @State private var showFullJandiblock: Bool = false

  private let totalWeeks: Int = 53
  private let days: Int = 7
  private let recentWeeks: Int = 10
  
  
  var body: some View {
    VStack {
      Text("활동")
      VStack {
        Divider()
        Text("활동 요약")
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.leading)

        HStack(spacing: 2) {
          VStack(spacing: 2) {
            Text("일")
              .foregroundColor(.red)
              .font(.system(size: 14))
              .frame(height: 17)
            Text("월")
              .font(.system(size: 14))
              .frame(height: 17)
            Text("화")
              .font(.system(size: 14))
              .frame(height: 17)
            Text("수")
              .font(.system(size: 14))
              .frame(height: 17)
            Text("목")
              .font(.system(size: 14))
              .frame(height: 17)
            Text("금")
              .font(.system(size: 14))
              .frame(height: 17)
            Text("토")
              .foregroundColor(.blue)
              .font(.system(size: 14))
              .frame(height: 17)
          }
          ForEach((totalWeeks - recentWeeks)..<totalWeeks, id: \.self) { _ in
            VStack(spacing: 2) {
              ForEach(0..<days, id: \.self) { _ in
                JandiBlock()
              }
            }
          }
        }
        .padding(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .onTapGesture {
          showFullJandiblock = true
        }
      }
      Divider()
        .sheet(isPresented: $showFullJandiblock) {
          JandiFullView(totalweeks: totalWeeks, days: days)

        }
    }
  }
}

//네모 한개 정의
struct JandiBlock: View {
  var body: some View {
    Rectangle()
      .fill(Color.blue)
      .frame(width: 15, height: 15)
      .cornerRadius(4)
      .padding(.vertical, 1)
  }
}

//네모 전체 (팝업 형식)
struct JandiFullView: View {
  let totalweeks: Int
  let days: Int

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 2) {
        VStack(spacing: 2) {
          Text("일")
            .foregroundColor(.red)
            .font(.system(size: 14))
            .frame(height: 17)
          Text("월")
            .font(.system(size: 14))
            .frame(height: 17)
          Text("화")
            .font(.system(size: 14))
            .frame(height: 17)
          Text("수")
            .font(.system(size: 14))
            .frame(height: 17)
          Text("목")
            .font(.system(size: 14))
            .frame(height: 17)
          Text("금")
            .font(.system(size: 14))
            .frame(height: 17)
          Text("토")
            .foregroundColor(.blue)
            .font(.system(size: 14))
            .frame(height: 17)
        }
        
        ForEach(0..<totalweeks, id: \.self) { _ in
          VStack(spacing: 2) {
            ForEach(0..<days, id: \.self) { _ in
              JandiBlock()
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
  ChartView()
}
