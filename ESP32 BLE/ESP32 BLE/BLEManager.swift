//
//  BLEManager.swift
//  ESP32 BLE
//
//  Created by Artsemi Ryzhankou on 19/01/2024.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let advertisementServiceUUIDs: [String]?
    let peripheral: CBPeripheral
}

// BLEManager class conforms to observable object for SwiftUI, CBCentralManagerDelegate and CBPeripheralDelegate for managing BLE connections.
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // Constants specific to the ESP32 BLE service and characteristic UUIDs.
    enum ESP32Constants {
        static let serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
        static let characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
    }

    // Central manager to handle BLE operations.
    var centralManager: CBCentralManager!
    // Reference to the connected ESP32 peripheral.
    var esp32Peripheral: CBPeripheral?
    // Reference to the characteristic through which communication happens.
    var esp32Characteristic: CBCharacteristic?

    @Published var peripherals: [Peripheral] = []
    @Published var isConnected = false // Indicates if the app is connected to a peripheral.
    @Published var bootButonState = false // true - pressed, false - released

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Function to send a string value to the ESP32.
    func sendTextValue(_ text: String) {
        let data = Data(text.utf8)
        if let myCharacteristic = esp32Characteristic {
            esp32Peripheral?.writeValue(data, for: myCharacteristic, type: .withResponse)
        }
    }

    // Function to initiate a connection to a chosen peripheral.
    func connectPeripheral(peripheral: Peripheral) {
        guard let foundPeripheral = peripherals.first(where: { $0.id == peripheral.id })?.peripheral else { return }
        esp32Peripheral = foundPeripheral
        esp32Peripheral?.delegate = self
        centralManager.connect(foundPeripheral, options: nil)
    }

    // Function to disconnect from the current peripheral.
    func disconnectFromPeripheral() {
        if let peripheral = esp32Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func refreshDevices() {
        if centralManager.state == .poweredOn {
            peripherals.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth is not powered on")
        }
    }

    // MARK: - CBCentralManagerDelegate Methods

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        refreshDevices()
    }

    // Called when a peripheral is discovered during scanning.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if peripheral.name?.contains("ESP32") ?? false {
            let adsServiceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.compactMap({ data in
                data.uuidString
            })

            let newPeripheral = Peripheral(id: peripheral.identifier,
                                           name: peripheral.name ?? "Unknown",
                                           rssi: RSSI.intValue,
                                           advertisementServiceUUIDs: adsServiceUUIDs,
                                           peripheral: peripheral)
            if !peripherals.contains(where: { $0.id == newPeripheral.id }) {
                peripherals.append(newPeripheral)
            }
        }
    }

    // Called when a connection is successfully established with a peripheral.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        esp32Peripheral?.discoverServices([CBUUID(string: ESP32Constants.serviceUUID)])
        centralManager.stopScan()
    }

    // Called when the peripheral is disconnected.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        esp32Peripheral = nil
        esp32Characteristic = nil
        peripherals.removeAll()
        refreshDevices()
    }

    // MARK: - CBPeripheralDelegate Methods

    // Called when services of a peripheral are discovered.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                // Discover characteristics for the service with the specified UUID
                peripheral.discoverCharacteristics([CBUUID(string: ESP32Constants.characteristicUUID)], for: service)
            }
        }
    }

    // Called when characteristics for a service are discovered.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.write) {
                    esp32Characteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    // Called when the value of a characteristic is updated.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }

        if characteristic == esp32Characteristic {
            if let data = characteristic.value {
                let buttonState = data.first == 1
                bootButonState = buttonState
                print("BOOT Button State: \(buttonState)")
            }
        }
    }

    // Called when a value is successfully written to a characteristic.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error in sending data: \(error)")
            return
        }
        print("Data has been successfully sent and processed.")
    }
}
