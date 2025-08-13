//
//  ReviewApp.swift
//  Review
//
//  Created by SJS on 8/11/25.
//

import SwiftUI

@main
struct ReviewApp: App {
  @StateObject private var tagStore = TagStore()
  
    var body: some Scene {
        WindowGroup {
            ListView()
            .environmentObject(tagStore)
        }
    }
}
