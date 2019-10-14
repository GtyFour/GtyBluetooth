//
//  DiscoveredPeripheral.swift
//  GtyBluetooth
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation
import CoreBluetooth.CBCentralManager

public struct GtyDiscovery {
    
    public var peripheral: CBPeripheral
    
    public var advertisementData: [String : AnyObject]?
    
    public var RSSI: Int32
}
