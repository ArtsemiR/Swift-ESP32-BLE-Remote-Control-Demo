# iOS ESP32 BLE Remote Control Demo
![](Demo-960-720-12.gif)

This Swift project demonstrates how to manage Bluetooth Low Energy (BLE) connections with ESP32 devices using ```CoreBluetooth``` framework. The application allows for discovering, connecting to, and communicating with ESP32 peripherals.

## Info.plist Configuration

The `Info.plist` file is configured to request Bluetooth usage permission from the user:

```xml
<plist version="1.0">
<dict>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>This app uses Bluetooth to connect and control ESP32 devices.</string>
</dict>
</plist>
```
This setting is required for iOS apps that use Bluetooth features, ensuring the app complies with Apple's privacy guidelines.


## BLEManager.swift
### Peripheral Structure
Defines a structure for BLE peripherals, encapsulating properties like ID, name, RSSI, etc., for easy management of discovered BLE devices.

```swift
struct Peripheral: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let advertisementServiceUUIDs: [String]?
    let peripheral: CBPeripheral
}
```

### BLEManager Class
Manages BLE operations and conforms to SwiftUI's ObservableObject for UI updates, as well as CoreBluetooth's CBCentralManagerDelegate and CBPeripheralDelegate for handling BLE events.

ESP32 **Identifiers** determined during programming of this board here - https://github.com/ArtsemiR/ESP32-BLE-Remote-Control-Demo
```swift
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // UUIDs for ESP32 BLE service and characteristic.
    enum ESP32Constants {
        static let serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
        static let characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
    }

    var centralManager: CBCentralManager!
    var esp32Peripheral: CBPeripheral?
    var esp32Characteristic: CBCharacteristic?

    @Published var peripherals: [Peripheral] = []
    @Published var isConnected = false // Indicates if the app is connected to a peripheral.
    @Published var bootButtonState = false // Tracks the state of the BOOT button.

    // Function implementations...
}
```

### Central Manager Delegate Methods
Handles central manager events like state updates, discovering peripherals, and managing connections.

More logic in the source code.

```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) { /* ... */ }
func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) { /* ... */ }
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) { /* ... */ }
func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) { /* ... */ }
```

### Peripheral Delegate Methods
Manages peripheral-related events such as discovering services and characteristics, and handling updates to characteristic values.

More logic in the source code.

```swift
func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) { /* ... */ }
func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) { /* ... */ }
func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) { /* ... */ }
func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) { /* ... */ }
```
