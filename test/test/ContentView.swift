//
//  ContentView.swift
//  test
//
//  Created by William Sio on 8/13/25.
//

import SwiftUI

struct ContentView: View {
    @State var countDownTimer = 10
    @State var timerRunning = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        Text("\(countDownTimer)").onReceive(timer) { _ in
            if countDownTimer > 0 && timerRunning {
                countDownTimer -= 1
            } else {
                timerRunning = false
            }
        }
        HStack {
            Button ("Start") {
                timerRunning = true
            }
            Button ("Reset") {
                countDownTimer = 10
                timerRunning = false
            }
        }
        
        if countDownTimer == 0 {
            Text("Time is up")
        }
    }
}


#Preview {
    ContentView()
}
