//
//  GtyConnecter.swift
//  GtyBluetooth
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation
import CoreBluetooth

class GtyConnecter: CentralManagerConnectionDelegate {
    
    typealias SuccessHandle = ((_ central: CBCentralManager, _ peripheral: CBPeripheral) -> Void)
    typealias FailHandle = ((_ error: NSError?) -> Void)
    
    var centralManager: CBCentralManager?
    var discovery: GtyDiscovery?
    open var discoverys = [GtyDiscovery]()
    var parser: GtyParserSession?
    var autoConnect = false
    fileprivate var connectTimer: Timer?
    fileprivate var successHandle: SuccessHandle?
    fileprivate var failHandle: FailHandle?
    fileprivate var lastPeripheral: CBPeripheral?
    fileprivate var lastPeripherals = [CBPeripheral]()
    fileprivate var isCancel = false
    
    /**
     no central manager, discovery -> return false
     */
    func connectWithDuration(_ duration: TimeInterval, connectSuccess: SuccessHandle?, failHandle:FailHandle?) -> Bool {
        guard let centralManager = self.centralManager, let discovery = self.discovery else {
            return false
        }
        self.successHandle = connectSuccess
        self.failHandle = failHandle
        invalidateTimer()
        connectTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GtyConnecter.timeOut), userInfo: nil, repeats: false)
        if let lastPeripheral = lastPeripheral {
            self.cancel(centralManager, peripheral: lastPeripheral)
        }
        centralManager.connect(discovery.peripheral, options: nil)
        return true
    }
    /**
     no central manager, discovery -> return false
     */
    func connectWithDurationMultible(_ duration: TimeInterval, connectSuccess: SuccessHandle?, failHandle:FailHandle?) -> Bool {
        guard let centralManager = self.centralManager, let discovery = self.discoverys.last else {
            return false
        }
        self.successHandle = connectSuccess
        self.failHandle = failHandle
        print("4")
        invalidateTimer()
        print("5")
        connectTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GtyConnecter.timeOut), userInfo: nil, repeats: false)
        lastPeripherals.append(discovery.peripheral)
        print("6")
        centralManager.connect(lastPeripherals.last!, options: nil)
        print("7")
        return true
    }
    
    func connectLastPeripheral() {
        if let centralManager =  centralManager, let lastPeripheral = lastPeripheral {
            centralManager.connect(lastPeripheral, options: nil)
        }
    }
    func connectLastPeripheralMultible() {
        for peri in lastPeripherals {
            self.centralManager!.connect(peri, options: nil)
        }
    }
    
    func disConnect() {
        guard let discovery = self.discovery else { return }
        self.cancel(centralManager, peripheral: discovery.peripheral)
    }
    func disConnectMultible() {
        if lastPeripherals.count == 0{return}
        for peri in lastPeripherals {
            self.cancel(self.centralManager!, peripheral: peri)
        }
        lastPeripherals.removeAll()
    }
    func disConnectWithNumber(_ peripheralNumber:Int) {
        if lastPeripherals.count == 0{return}
        self.cancel(self.centralManager!, peripheral: lastPeripherals[peripheralNumber])
        lastPeripherals.remove(at: peripheralNumber)
    }
    
    func disConnectLast() {
        if lastPeripherals.count == 0{return}
        self.cancel(self.centralManager!, peripheral: lastPeripherals.last)
        lastPeripherals.removeLast()
    }
    
    //MARK: CentralManagerConnectionDelegate
    
    func centralManager(_ central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: GtyConnectStateNotify), object: true)
        self.lastPeripheral = peripheral
        self.invalidateTimer()
        guard let parser = self.parser else { return }
        parser.isFree = true
        parser.connected = true
        parser.peripheral = peripheral
        parser.peripheralArray.append(peripheral)
        parser.startRetrivePeripheral{ [weak self] () in
            guard let `self` = self else { return }
            self.successHandle?(central, peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let failHandle = self.failHandle {
            failHandle(error)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: GtyConnectStateNotify), object: false)
        parser?.connected = false
        parser?.peripheralArray.removeAll()
        if isCancel {
            self.lastPeripheral = nil
            isCancel = false
            return
        }
        if autoConnect {
            central.connect(peripheral, options: nil)
        }
    }
    
    //MARK: Private Method
    
    @objc fileprivate func timeOut() {
        if let failHandle = self.failHandle {
            let timeoutError = NSError(domain: "com.gtyfour.ble", code: -1008, userInfo: ["msg" : "connect timeout"])
            failHandle(timeoutError)
        }
        self.disConnect()
    }
    
    fileprivate func cancel(_ central: CBCentralManager?, peripheral: CBPeripheral?) {
        isCancel = true
        self.invalidateTimer()
        if let centralManager = centralManager, let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    fileprivate func invalidateTimer() {
        connectTimer?.invalidate()
        self.connectTimer = nil
    }
}
