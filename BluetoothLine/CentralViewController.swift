//
//  CentralViewController.swift
//  BluetoothLine
//
//  Created by se on 2020/09/23.
//  Copyright © 2020 se. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

var rxCharacteristic: CBCharacteristic?
var txCharacteristic: CBCharacteristic?
var characteristicASCIIValue = NSString()
var discoveredPeripheral:  CBPeripheral?

class CentralViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource{
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("Bluetooth Enabled")
            startScan()
        } else {
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! PeripheralViewController
        let peripheral = self.peripherals[indexPath.row]
        
        if peripheral.name == nil {
            cell.peripheralLabel.text = "nil"
        } else {
            cell.peripheralLabel.text = peripheral.name
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt  indexPath: IndexPath) {
        discoveredPeripheral = peripherals[indexPath.row]
        connectToDevice()
    }
    
    
    //UI
    @IBOutlet weak var TableView: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    @IBAction func refreshAction(_ sender: AnyObject) {
        disconnectFromDevice()
        self.peripherals = []
        self.TableView.reloadData()
        startScan()
    }
    
    //data
    var centralManager: CBCentralManager!
    var transferCharacteristic: CBCharacteristic?
    var data = NSMutableData()
    var writeData: String = ""
    var timer = Timer()
    var peripherals: [CBPeripheral]  = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.TableView.delegate = self
        self.TableView.dataSource = self
        self.TableView.reloadData()
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override func viewDidAppear(_ animated: Bool){
        disconnectFromDevice()
        super.viewDidAppear(animated)
        refreshScanView()
        print("View Cleared")
    }
    
    override func viewWillDisappear(_ animated: Bool){
        super.viewWillDisappear(animated)
        print("Stop Scanning")
        centralManager?.stopScan()
    }
    
    func startScan() {
        peripherals = []
        print("Now Scanning...")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(self.cancelScan),userInfo: nil, repeats: false)
    }
    
    @objc func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found:  \(peripherals.count)")
    }
    
    func refreshScanView() {
        TableView.reloadData()
    }
    
    func disconnectFromDevice() {
        if discoveredPeripheral != nil {
            centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
        }
    }
    
    func restoreCentralManager() {
        centralManager?.delegate = self
    }
    
    func connectToDevice() {
        centralManager?.connect(discoveredPeripheral!, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any]) {
        discoveredPeripheral = peripheral
        self.peripherals.append(peripheral)
        peripheral.delegate = self
        self.TableView.reloadData()
        if discoveredPeripheral == nil {
            print("Found new peripheral devices with services")
            print("Peripheral name: \(String(describing:  peripheral.name))")
            print("**********************************")
            print("Advertisement Data : \(advertisementData)")
        }
    }
    
    func conncetToDevice() {
        centralManager?.connect(discoveredPeripheral!, options:  nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**********************************")
        print("Connection complete")
        print("Peripheral  info: \(String(describing:  discoveredPeripheral))")
        centralManager?.stopScan()
        print("Scan Stopped")
        data.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID])
        let storyboard  = UIStoryboard(name: "Main", bundle: nil)
        let centralChatBox = storyboard.instantiateViewController(withIdentifier: "CentralChatBox") as! CentralChatBox
        centralChatBox.peripheral = peripheral
        navigationController?.pushViewController(centralChatBox, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    func disconnectAllConnection() {
        centralManager.cancelPeripheralConnection(discoveredPeripheral!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("**********************************")
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered Services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("**********************************")
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else {
            return
        }
        print("Found \(characteristics.count) characteristics!")
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx) {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true,  for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx  Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == rxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                characteristicASCIIValue = ASCIIstring
                print("Value Received: \((characteristicASCIIValue as String))")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue:"Notify"), object: nil)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("**********************************")
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) !=  nil) {
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor?
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
                print("Rx Value \(String(describing: rxCharacteristic?.value))")
                print("Tx Value \(String(describing: txCharacteristic?.value))")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("**********************************")
        if(error != nil) {
            print("Error changing notification state: \(String(describing: error?.localizedDescription))")
        } else {
            print("Characteristic's value subscribed")
        }
        if(characteristic.isNotifying) {
            print("Subscribed.  Notification  has begun for: \(characteristic.uuid)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error  == nil else {
            print("Error  discovering services: error")
            return
        }
        print("Succeeded!")
    }
}
