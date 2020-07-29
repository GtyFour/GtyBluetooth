//
//  ReceiveDataCenter.swift
//  MatataCode
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation
import CoreBluetooth
public let ERR_DATA_LOST:Int = 10001
public let ERR_DATA_DISMATCH:Int = 10002
public let ERR_DATA_UNLINK:Int = 10003
public let ALL_DATA_CORRECT:Int = 0
public let lock = NSConditionLock.init(condition: 1)
public let lock2 = NSConditionLock.init(condition: 2)
class ReceiveDataCenter: NSObject, ParserDataReceiveDelegate {
    var DataRecived : Data!
    var DataSent : Data!
    public var checkResult:Int! = 10
    func receiveData(_ data: Data, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        DataRecived = data
        checkResult = 10
        if DataSent == DataRecived{
            checkResult = ALL_DATA_CORRECT
            lock.unlock()
        }else{
            checkResult = ERR_DATA_DISMATCH
            lock.unlock()
        }
    }
    public func recivedDataCheck()->Int{
        
        return checkResult
    }
    public func setSendData(_ data: Data){
        DataSent = data
    }
}
