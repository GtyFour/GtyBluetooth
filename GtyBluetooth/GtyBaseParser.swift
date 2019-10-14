//
//  PeripheralParser.swift
//  BleCore
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//


import Foundation
import CoreBluetooth

open class GtyBaseParser:NSObject, GtyParserSession, CBPeripheralDelegate{
    
    open var isFree = false
    open var connected = false
    fileprivate var retriveServiceIndex = 0
    fileprivate var retriveServiceIndexes = [Int]()
    fileprivate var delegate:ParserDelegate?
    fileprivate var comingDataMonitor: ParserDataReceiveDelegate?
    fileprivate var curPeripheralNumber = 0
    fileprivate var curPeripheral:CBPeripheral?
    fileprivate var curPeripherals = [CBPeripheral]()
    fileprivate lazy var containCharacteristics = [CBCharacteristic]()
    fileprivate lazy var containCharacteristicsArray = [[CBCharacteristic]]()
    fileprivate var completeHandle: (() -> Void)?

    weak open var parserDelegate: ParserDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    weak open var dataComingMonitor: ParserDataReceiveDelegate? {
        get { return self.comingDataMonitor }
        set { self.comingDataMonitor = newValue }
    }
    
    open var peripheral: CBPeripheral? {
        get { return curPeripheral }
        set { curPeripheral = newValue }
    }
    
    open var peripheralNumber: Int? {
        get { return curPeripheralNumber }
        set { curPeripheralNumber = newValue! }
    }
    open var peripheralArray: [CBPeripheral] {
        get { return curPeripherals }
        set { curPeripherals = newValue }
    }
    
    open func startRetrivePeripheral(_ complete: (() -> Void)?) {
//        print("startRetrivePeripheral  curPeripheralNumber:\(curPeripheralNumber)---retriveServiceIndex:\(retriveServiceIndex)---")
        retriveServiceIndex = 0
        retriveServiceIndexes.append(retriveServiceIndex)
        containCharacteristicsArray.append(containCharacteristics)
//        curPeripheral = curPeripherals[curPeripheralNumber]
        curPeripheral = curPeripherals.last!
        guard let curPeripheral = curPeripheral else { complete?(); return }
        curPeripheral.delegate = self
        curPeripheral.discoverServices(nil)
        self.completeHandle = complete
    }
    open func writeData(_ data: Data, characterUUIDStr: String, withResponse: Bool) throws {
        do {
            let (per, chara) = try self.prepareForAction(characterUUIDStr)
            let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
            per.writeValue(data, for: chara, type: type)
        } catch let error {
            throw error
        }
    }
    open func writeDataWithNumber(_ data: Data, characterUUIDStr: String, withResponse: Bool, _ peripheralNumber:Int) throws {
        do {
            let (per, chara) = try self.prepareForActionWithNumber(characterUUIDStr,peripheralNumber)
            let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
//            print("per:\(per)")
//            print("chara:\(chara)")
            per.writeValue(data, for: chara, type: type)
        } catch let error {
            throw error
        }
    }
    
    open func readCharacteristic(_ characterUUIDStr: String) throws {
        do {
            let (per, chara) = try self.prepareForAction(characterUUIDStr)
            per.readValue(for: chara)
        } catch let error {
            throw error
        }
    }
    open func readCharacteristicWithNumber(_ characterUUIDStr: String, peripheralNumber:Int) throws {
        do {
            let (per, chara) = try self.prepareForActionWithNumber(characterUUIDStr,peripheralNumber)
            per.readValue(for: chara)
        } catch let error {
            throw error
        }
    }
    
    //MARK: - CBPeripheralDelegate
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        containCharacteristics.removeAll()
//        print("###########containCharacteristics:\(containCharacteristics)")
        guard let services = peripheral.services else { return }
        _ = services.map {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)  {
        guard let characteristics = service.characteristics else { return }
        containCharacteristics = characteristics.reduce(containCharacteristics) {
            if $1.properties.contains(CBCharacteristicProperties.notify) {
                peripheral.setNotifyValue(true, for: $1)
            }
//            print("$0 + [$1]:\($0 + [$1])")
            return $0 + [$1]
        }
//        print("----- INDEX！！:\(containCharacteristicsArray.count-1)")
//        print("----- containCharacteristics.last!！！:\(containCharacteristics.last!)")
        containCharacteristicsArray[containCharacteristicsArray.count-1] = containCharacteristics
//        retriveServiceIndex += 1
        retriveServiceIndexes[retriveServiceIndexes.count-1] += 1
        if retriveServiceIndex == peripheral.services!.count {
            self.isFree = true
            self.completeHandle?()
            NotificationCenter.default.post(name: Notification.Name(rawValue: GtyRetriveFinishNotify), object: nil)
        }
//        print("----- containCharacteristics:\(containCharacteristics)")
//        print("----- containCharacteristicsArray:\(containCharacteristicsArray)")
//        print("----- curPeripheralNumber:\(curPeripheralNumber)")
//        print("----- retriveServiceIndex:\(retriveServiceIndex)")
//        print("----- retriveServiceIndexes:\(retriveServiceIndexes)")
//        print("----- peripheral:\(peripheral)")
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        dataComingMonitor?.receiveData(value, peripheral: peripheral, characteristic: characteristic)
        delegate?.receiveData(value, peripheral: peripheral, characteristic: characteristic)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        delegate?.didWriteData(peripheral, characteristic: characteristic, error: error as NSError?)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard (error == nil) else { return }
        NotificationCenter.default.post(name: Notification.Name(rawValue: GtyReadRSSINotify), object: RSSI, userInfo: ["peripheral" : peripheral])
    }
    
    //MARK: - Private Method
    
    fileprivate func prepareForAction(_ UUIDStr: String) throws -> (CBPeripheral, CBCharacteristic) {
        guard let curPeripheral = curPeripheral else {
            throw GtyParserError.noPeripheral
        }
        
        let flatResults = containCharacteristics.compactMap { (chara) -> CBCharacteristic? in
            if chara.uuid.uuidString.lowercased() == UUIDStr.lowercased() {
                return chara
            }
            return nil
        }
        if flatResults.count == 0 {
            throw GtyParserError.wrongCharacterUUIDStr
        }

        return (curPeripheral, flatResults.first!)
    }
    fileprivate func prepareForActionWithNumber(_ UUIDStr: String, _ peripheralNumber:Int) throws -> (CBPeripheral, CBCharacteristic) {
        curPeripheralNumber = peripheralNumber
        curPeripheral = curPeripherals[peripheralNumber]
        retriveServiceIndex = retriveServiceIndexes[peripheralNumber]
        containCharacteristics = containCharacteristicsArray[peripheralNumber]
//        print("++++  curPeripheral:\(String(describing: curPeripheral))")
//        print("++++  curPeripherals[\(peripheralNumber)]:\(curPeripherals[peripheralNumber])")
//        print("++++  curPeripheralNumber:\(curPeripheralNumber)")
//        print("++++  retriveServiceIndex:\(retriveServiceIndex)")
//        print("++++  containCharacteristics:\(containCharacteristics)")
        guard let curPeripheral = curPeripheral else {
            throw GtyParserError.noPeripheral
        }
        
        let flatResults = containCharacteristics.compactMap { (chara) -> CBCharacteristic? in
            if chara.uuid.uuidString.lowercased() == UUIDStr.lowercased() {
                return chara
            }
            return nil
        }
        if flatResults.count == 0 {
            throw GtyParserError.wrongCharacterUUIDStr
        }

        return (curPeripheral, flatResults.first!)
    }
    
    deinit {
        print("[Release: ] __BaseParser release")
    }
}
