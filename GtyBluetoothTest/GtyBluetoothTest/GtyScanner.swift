//
//  Scanner.swift
//  GtyBluetooth
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation
import CoreBluetooth

class GtyScanner: CentralManagerDiscoveryDelegate {
    
    typealias DiscoveryHandle = ((_ discovery: GtyDiscovery) -> Void)
    typealias CompleteHandle = (() -> Void)
    
    var centralManager: CBCentralManager?
    var servicesUUIDStrs: [String]?
    fileprivate var scanTimer: Timer?
    fileprivate var discoveryHandle: DiscoveryHandle?
    fileprivate var completeHandle: CompleteHandle?
    /**
        no central manager -> return false
     */
    func scanWithDuration(_ duration: TimeInterval, discoveryHandle: DiscoveryHandle?, completeHandle: CompleteHandle?) -> Bool {
        guard let centralManager = centralManager else {
            return false
        }
        
        self.discoveryHandle = discoveryHandle
        self.completeHandle = completeHandle
        invalidateTimer()
        scanTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GtyScanner.timeOut), userInfo: nil, repeats: false)
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey : false]
        centralManager.scanForPeripherals(withServices: stringsToUUIDs(servicesUUIDStrs), options: scanOption)
        
        if let connectedDiscover = retriveConnectedDiscovery(), let discoveryHandle = self.discoveryHandle {
            _ = connectedDiscover.map{
                discoveryHandle($0)
            }
        }
        return true
    }
    
    func stopScan() {
        endScan()
    }
    
    //MARK: CentralManagerDiscoveryDelegate -
    
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: NSNumber) {
        guard let discoveryHandle = self.discoveryHandle else { return }
        DispatchQueue.main.async {
            let discovery = GtyDiscovery(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI.int32Value)
            discoveryHandle(discovery)
        }
    }
    
    //MARK: Private Method -
    
    @objc fileprivate func timeOut() {
        endScan()
    }
    
    fileprivate func retriveConnectedDiscovery() -> [GtyDiscovery]? {
        let servicesUUIDs = stringsToUUIDs(servicesUUIDStrs)
        if let centralManager = centralManager, let servicesUUIDs = servicesUUIDs {
            let discoverys = centralManager.retrieveConnectedPeripherals(withServices: servicesUUIDs).map{
                return GtyDiscovery(peripheral: $0, advertisementData: nil, RSSI: -1)
            }
            return discoverys
        }
        return nil
    }
    
    fileprivate func endScan() {
        invalidateTimer()
        centralManager?.stopScan()
        completeHandle?()
        completeHandle = nil
        discoveryHandle = nil
    }
    
    fileprivate func invalidateTimer() {
        scanTimer?.invalidate()
        self.scanTimer = nil
    }
    
    fileprivate func stringsToUUIDs(_ strs:[String]?) -> [CBUUID]?{
        guard let strs = strs else { return nil }
        let UUIDs = strs.reduce([CBUUID](), { (uuids, uuidStr) -> [CBUUID] in
            let uuid = CBUUID.init(string: uuidStr)
            return uuids + [uuid]
        })
        return UUIDs
    }
}
