//
//  ReceiveDataCenter.swift
//  MatataCode
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation
import CoreBluetooth

class ReceiveDataCenter: NSObject, ParserDataReceiveDelegate {
    
    func receiveData(_ data: Data, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        //let bytes = [UInt8](data)
//        print(bytes)
        //print("receive data: " + "\(bytes)" + "from: " + "\(peripheral.identifier)")
    }
}
