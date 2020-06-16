//
//  SecondViewController.swift
//  UrbanRecorder
//
//  Created by Makoto Amano on 2020/06/14.
//  Copyright © 2020 Makoto Amano. All rights reserved.
//

//Connect M5Stick-C put with ENV Hat
import UIKit
import CoreBluetooth
import SwiftyDropbox

class SecondViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    var peripheral: CBPeripheral!
    
    var connectPeripheral: CBPeripheral? = nil
    var writeCharacteristic: CBCharacteristic? = nil
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var connectLabel: UILabel!
    
    var scanSwitch = false
    var flag       = false
    let programStart = Date()
    var date = " "
    var recStart:TimeInterval     = 0.0
    var csvArray:[[String]] = [["time", "temperature", "humidity", "pressure"]]
    var temperature:Float = 0.0
    var humidity:Float    = 0.0
    var pressure:Float    = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //  接続状況が変わるたびに呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print ("state: \(central.state)")
        if central.state == CBManagerState.poweredOn {
            print("Ready!")
        }else {
            print("Not Ready!")
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == CBManagerState.poweredOn {
            let service = CBMutableService(type: CBUUID(string: Bluetooth.Service.kUUID), primary: true)
            self.peripheralManager.add(service)
        }
    }
    
    @IBAction func startScaning(_ sender: UIButton) {
        print("start scan")
        if(centralManager.isScanning == false){
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    @IBAction func stopScanning(_ sender: UIButton) {
        print("Stop scan")
        centralManager.stopScan()
    }
    
    //  スキャン結果を取得
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name, peripheralName.contains(Bluetooth.kPeripheralName) {
            self.connectPeripheral = peripheral
            self.centralManager.connect(peripheral, options: nil)
            print("機器に接続：\(String(describing: peripheral.name))")
            connectLabel.text = "\(String(describing: peripheral.name))"
        }
    }
    
    //  接続成功時に呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connect success")
        connectLabel.text = "Connect success"
        self.connectPeripheral = peripheral
        self.connectPeripheral?.delegate = self
        // 指定のサービスを探索
        if let peripheral = self.connectPeripheral {
            peripheral.discoverServices([CBUUID(string: Bluetooth.Service.kUUID)])
        }
        centralManager.stopScan()
    }
    
    //  接続失敗時に呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    }
    // 接続切断時
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("接続切断：\(String(describing: error))")
    }
    
    
    
    // サービス検索結果取得
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            centralManager.stopScan()
            return
        }
        
        if let peripheralServices = peripheral.services {
            for service in peripheralServices where service.uuid == CBUUID(string: Bluetooth.Service.kUUID) {
                print("search Characteristic")
                // キャラクタリスティック探索開始
                let characteristicUUIDArray: [CBUUID] = [CBUUID(string: Bluetooth.Characteristic.kUUID01)]
                peripheral.discoverCharacteristics(characteristicUUIDArray, for: service)
            }
        }
    }
    
    //  キャラクタリスティック検索結果取得
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            centralManager.stopScan()
            print("キャラクタリスティック発見時：\(String(describing: error))")
            return
        }
        guard let serviceCharacteristics = service.characteristics else {
            centralManager.stopScan()
            return
        }
        // キャラクタリスティック別の処理
        for characreristic in serviceCharacteristics {
            if characreristic.uuid == CBUUID(string: Bluetooth.Characteristic.kUUID01) {
                peripheral.setNotifyValue(true, for: characreristic)
                print("Notify")
                peripheral.readValue(for: characreristic)
            }
        }
    }
    
    //Characteristic値取得時・変更時
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("キャラクタリスティック値取得・変更時エラー：\(String(describing: error))")
            return
        }
        
        guard let data:NSData = characteristic.value as NSData? else {
            print("wrapping failed")
            return
        }
        
        if data.length == 0 {
            print("No data")
            return
        } else {
            // データが渡ってくる
            print("data: \(String(describing: data))")
            let out = data.map { String(format: "%02X", $0)}
            
            //        let seq        = out[0]
            let temp_up    = out[2]
            let temp_down  = out[1]
            let humid_up   = out[4]
            let humid_down = out[3]
            let press_up   = out[6]
            let press_down = out[5]
            
            temperature  = Float(Int(temp_up+temp_down, radix: 16)!)/100
            humidity     = Float(Int(humid_up + humid_down, radix: 16)!)/100
            pressure     = Float(Int(press_up + press_down, radix: 16)!)/10
            
            temperatureLabel.text = String(temperature)
            humidityLabel.text    = String(humidity)
            pressureLabel.text    = String(pressure)
            
            appDelegate.rec.setTemperature(temperature)
            appDelegate.rec.setHumidity(humidity)
            appDelegate.rec.setPressure(pressure)
        }
    }
}


