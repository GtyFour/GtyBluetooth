//
//  GtyConstants.swift
//  BleCore
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//

import Foundation

/**
    NOTIFICATION: complete resolution of peripheral
*/

/**
    central state change notification
 */
public let GtyCentralStateNotify = "GtyCentralStateNotify"
/**
 peripheral conntect state change notification
 */
public let GtyConnectStateNotify = "GtyConnectStateNotify"
/**
 peripheral's services retrive finished notification
 */
public let GtyRetriveFinishNotify = "GtyRetriveFinishNotify"
/**
 read peripheral's RSSI notification
 */
public let GtyReadRSSINotify = "GtyReadRSSINotify"

/**
    Parser Error
 */
public enum GtyParserError: Error {
    case wrongCharacterUUIDStr
    case noPeripheral
}


