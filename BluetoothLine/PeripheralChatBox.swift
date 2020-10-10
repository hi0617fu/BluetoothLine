//
//  PeripheralChatBox.swift
//  BluetoothLine
//
//  Created by se on 2020/09/25.
//  Copyright © 2020 se. All rights reserved.
//

import UIKit
import CoreBluetooth



class PeripheralChatBox:  UIViewController, CBPeripheralManagerDelegate, UITextViewDelegate, UITextFieldDelegate{
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            return
        }
        print("Peripheral manager is running")
    }
    
    
    //UI
    @IBOutlet weak var baseTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var advertisingSwitch: UISwitch!
    
    //Data
    var peripheralManager: CBPeripheralManager!
    var peripheral: CBPeripheral!
    private var consoleAsciiText: NSAttributedString? = NSAttributedString(string: "")
    
    override func viewDidLoad() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
        super.viewDidLoad()
        baseTextView.isUserInteractionEnabled = true //キーボードを出したくない
        baseTextView.isEditable = false //キーボードを出したくない
        baseTextView.isSelectable = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        peripheralManager.stopAdvertising()
        super.viewWillDisappear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
    }
    
    @IBAction func getText(sender : UITextField) {
    }
    
    
    @IBAction func switchChanged(_ sender: Any) {
        if advertisingSwitch.isOn {
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [BLEService_UUID]])
        } else {
            peripheralManager.stopAdvertising()
        }
    }
    
    @IBAction func clickSendAction(_ sender: AnyObject) {
        outgoingData()
    }

    func outgoingData() {
        let appendString = "\n"
        
        let inputText = inputTextField.text
        
        let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
        let myAttributes1 = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): myFont!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.blue]
        
        writeValue(data: inputText!)
        
        let attribString = NSAttributedString(string: "[Outgoing]: " + inputText! + appendString, attributes: convertToOptionalNSAttributedStringKeyDictionary(myAttributes1))
        let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
        newAsciiText.append(attribString)
        
        consoleAsciiText = newAsciiText
        baseTextView.attributedText = consoleAsciiText
        baseTextView.isUserInteractionEnabled = true //キーボードを出したくない
        baseTextView.isEditable = false //キーボードを出したくない
        baseTextView.isSelectable = false
        //erase what's in the text field
        inputTextField.text = ""
    }
    
    func writeValue(data: String) {
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        if let discoveredPeripheral = discoveredPeripheral {
            if let txCharacteristic = txCharacteristic {
                discoveredPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
}

fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

