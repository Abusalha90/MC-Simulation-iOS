//
//  MyJoystickView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/27/25.
//
import SwiftUI
import SwiftUIJoystick


#Preview {
    MyJoystickView(leftStick: JoystickMonitor(), rightStick: JoystickMonitor())
}


struct MyJoystickView: View {
    @ObservedObject var leftStick : JoystickMonitor
    @ObservedObject var rightStick : JoystickMonitor

    var body: some View {
        VStack {
            Spacer()
            HStack{
                JoystickBuilder(
                    monitor: self.leftStick,
                    width: 150,
                    shape: .circle,
                    background: {
                        // Example Background
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.accentRadiation.opacity(0.4))
                    },
                    foreground: {
                        // Example Thumb
                        Circle().fill(Color.gray)
                    },
                    locksInPlace: false)
                Spacer()
                JoystickBuilder(
                    monitor: self.rightStick,
                    width: 150,
                    shape: .circle,
                    background: {
                        // Example Background
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.accentRadiation.opacity(0.4))
                    },
                    foreground: {
                        // Example Thumb
                        Circle().fill(Color.gray)
                    },
                    locksInPlace: false)
            }
        }
    }
}
