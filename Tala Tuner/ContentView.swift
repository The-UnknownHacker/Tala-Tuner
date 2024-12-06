//
//  ContentView.swift
//  Tala Tuner
//
//  Created by Aarav J on 16/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    
    var body: some View {
        VStack(spacing: 30) {
            // Note display
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                Text(audioEngine.currentNote)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(noteColor)
            }
            
            // Tuning meter
            TuningMeterView(cents: Double(audioEngine.centsDeviation))
                .frame(height: 60)
                .padding(.horizontal)
        }
        .padding()
        .onAppear {
            try? audioEngine.start()
        }
    }
    
    private var noteColor: Color {
        switch audioEngine.tuningStatus {
        case .flat: return .blue
        case .sharp: return .red
        case .inTune: return .green
        case .none: return .primary
        }
    }
}

struct TuningMeterView: View {
    let cents: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                // Center marker
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Needle
                Rectangle()
                    .fill(needleColor)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                    .offset(x: calculateNeedleOffset(width: geometry.size.width))
                    .animation(.spring(response: 0.3), value: cents)
            }
        }
    }
    
    private var needleColor: Color {
        if abs(cents) < 5 {
            return .green
        } else if cents < 0 {
            return .blue
        } else {
            return .red
        }
    }
    
    private func calculateNeedleOffset(width: CGFloat) -> CGFloat {
        // Limit the cents range to ±50 for display purposes
        let clampedCents = max(-50, min(50, cents))
        // Convert to percentage of width
        return (CGFloat(clampedCents) / 100.0) * width + width / 2
    }
}

#Preview {
    ContentView()
}
