//
//  CentralManagerDelegateProxy.swift
//  GtyBluetooth
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CentralManagerStateDelegate: class {
    func centralManagerDidUpdateState(_ central: CBCentralManager)
}

protocol CentralManagerDiscoveryDelegate: class {
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
}

protocol CentralManagerConnectionDelegate: class {
    func centralManager(_ central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral)
    func centralManager(_ central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?)
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
}

open class CentralManagerDelegateProxy: NSObject, CBCentralManagerDelegate {
    
    weak var stateDelegate: CentralManagerStateDelegate?
    weak var discoveryDelegate: CentralManagerDiscoveryDelegate?
    weak var connectionDelegate: CentralManagerConnectionDelegate?
    
    init(stateDelegate: CentralManagerStateDelegate?, discoveryDelegate: CentralManagerDiscoveryDelegate?, connectionDelegate: CentralManagerConnectionDelegate?) {
        self.stateDelegate = stateDelegate
        self.discoveryDelegate = discoveryDelegate
        self.connectionDelegate = connectionDelegate
        super.init()
    }
    
    // MARK: CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateDelegate?.centralManagerDidUpdateState(central)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveryDelegate?.centralManager(central, didDiscoverPeripheral: peripheral, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionDelegate?.centralManager(central, didConnectPeripheral: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionDelegate?.centralManager(central, didFailToConnectPeripheral: peripheral, error: error as NSError?)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionDelegate?.centralManager(central, didDisconnectPeripheral: peripheral, error: error as NSError?)
    }
}
