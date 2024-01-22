//
//  ContentView.swift
//  ESP32 BLE
//
//  Created by Artsemi Ryzhankou on 19/01/2024.
//

import SwiftUI
import Combine

struct ContentView: View {

    @ObservedObject var bleManager = BLEManager()

    @State var isEsp32LedEnabled = false
    @State var sevenSegmentValue = 0
    @State var trafficLightColor = "RED"

    @State var isAutoSwitched = false
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var cancellable: AnyCancellable?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if bleManager.peripherals.isEmpty {
                    ProgressView("Searching for ESP32 Module")
                        .progressViewStyle(.circular)
                } else if bleManager.isConnected {
                    List {
                        Section("On-board ESP-32 LED") {
                            ledControl
                        }
                        Section("Seven-segment display") {
                            sevenSegmentDisplayControl
                        }

                        Section("Traffic Light") {
                            trafficLight
                        }

                        Section("BOOT Button State") {
                            receivedBoolen
                        }

                        Button("Disconnect") {
                            bleManager.disconnectFromPeripheral()
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .onAppear {
                        isEsp32LedEnabled = false
                        sevenSegmentValue = 0
                        trafficLightColor = "RED"
                        isAutoSwitched = false
                        cancellable?.cancel()
                    }
                } else {
                    List(bleManager.peripherals) { peripheral in
                        device(peripheral)
                    }
                    .refreshable {
                        bleManager.refreshDevices()
                    }
                }
            }
            .navigationTitle("ESP32 Control")
        }
    }

    var ledControl: some View {
        Toggle("Led",
               systemImage: "lightbulb.led",
               isOn: $isEsp32LedEnabled
        )
        .foregroundStyle(.primary)
        .onChange(of: isEsp32LedEnabled) { _, newValue in
            bleManager.sendTextValue(newValue ? "LED_ON" : "LED_OFF")
        }
    }

    var sevenSegmentDisplayControl: some View {
        Stepper(value: $sevenSegmentValue,
                in: 0...9,
                step: 1) {
            HStack(spacing: 4) {
                Text(sevenSegmentValue.description)
            }
        }
        .onChange(of: sevenSegmentValue) { _, newValue in
            bleManager.sendTextValue(newValue.description)
        }
    }

    var trafficLight: some View {
        VStack(alignment: .leading) {
            Toggle("Auto",
                   isOn: $isAutoSwitched
            )
            Divider()
            Picker("Traffic Light", selection: $trafficLightColor) {
                Text("Red").tag("RED")
                Text("Yellow").tag("YELLOW")
                Text("Green").tag("GREEN")
            }
            .frame(height: 50)
            .pickerStyle(.segmented)
            .tint(.blue)
            .onChange(of: trafficLightColor) { _, newValue in
                bleManager.sendTextValue(newValue.uppercased())
            }
            .onChange(of: isAutoSwitched) { _, newValue in
                switch newValue {
                case true:
                    cancellable = timer.autoconnect().sink { _ in
                        switch trafficLightColor {
                        case "RED":
                            trafficLightColor = "YELLOW"
                            bleManager.sendTextValue("YELLOW")
                        case "YELLOW":
                            trafficLightColor = "GREEN"
                            bleManager.sendTextValue("GREEN")
                        case "GREEN":
                            trafficLightColor = "RED"
                            bleManager.sendTextValue("RED")
                        default:
                            trafficLightColor = "RED"
                        }
                    }
                case false:
                    cancellable?.cancel()
                }
            }
        }
    }

    var receivedBoolen: some View {
        VStack(alignment: .leading) {
            Text(Image(systemName: bleManager.bootButonState ? "button.programmable" : "circle"))
            +
            Text("  \(bleManager.bootButonState ? "Pressed" : "Released")")
        }
    }

    func device(_ peripheral: Peripheral) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(peripheral.name)
                Spacer()
                Button(action: {
                    bleManager.connectPeripheral(peripheral: peripheral)
                }) {
                    Text("Connect")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            VStack(alignment: .leading) {
                Group {
                    Text("""
                          Device UUID:
                          \(peripheral.id.uuidString)
                          """)
                    .padding([.bottom], 10)

                    if let adsServiceUUIDs = peripheral.advertisementServiceUUIDs {
                        Text("Advertisement Service UUIDs:")
                        ForEach(adsServiceUUIDs, id: \.self) { uuid in
                            Text(uuid)
                        }
                    }

                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("\(peripheral.rssi) dBm")
                    }
                    .padding([.top], 10)
                }
                .font(.footnote)
            }
        }
    }
}


