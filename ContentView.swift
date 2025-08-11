//
//  ContentView.swift
//  AsyncAwait
//
//  Created by 남병수 on 8/8/25.
//

import SwiftUI

func fetchUserData() async throws -> String {
  // Simulate network delay
  try await Task.sleep(nanoseconds: 1_000_000_000)
  if Bool.random() {
    throw URLError(.badServerResponse) // Simulate an error
  }
  return "User Data"
}

struct ContentView: View {
  @State private var isLoading: Bool = false
  @State private var userData: String = "Async Await Example"
  @State private var errorMessage: String?

  var body: some View {
    VStack {
      if isLoading {
        ProgressView("Loading...")
          .padding()
      } else if let errorMessage = errorMessage {
        Text("Error: \(errorMessage)")
          .foregroundColor(.red)
          .padding()
      } else {
        Text(userData)
          .font(.title)
          .padding()
      }
        Button("Fetch User Data") {
          Task {
            do {
              isLoading = true
              errorMessage = nil
              userData = try await fetchUserData()
            } catch {
              errorMessage = error.localizedDescription
            }
            isLoading = false
          }
        }
    }
  }
}

#Preview {
    ContentView()
}
