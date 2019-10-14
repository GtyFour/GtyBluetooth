//
//  CentralManager.swift
//  BleCore
//
//  Created by GtyFour on 2018/12/24.
//  Copyright © 2018 GtyFour. All rights reserved.
//
//  Build on CmdBluetooth https://github.com/ZeroFengLee/CmdBluetooth
//  add multible link and a Dictionary Class For Connected Peripherals Manager

import Foundation
import CoreBluetooth.CBCentralManager

open class GtyCentralManager: NSObject, CentralManagerStateDelegate {
    
    public typealias DiscoveryHandle = ((_ discovery: GtyDiscovery) -> Void)
    public typealias ScanCompleteHandle = (() -> Void)
    public typealias ConnectSuccessHandle = ((_ central: CBCentralManager, _ peripheral: CBPeripheral) -> Void)
    public typealias ConnectFailHandle = ((_ error: NSError?) -> Void)
    /**
     listen for cetral state
     */
    open var centralState: ((_ state: Int) -> Void)?
    open var keyname:String!
    /**
     connect status
     */
    open var connectedStatus: Bool {
        get {
            guard let parser = parser else { return false }
            return parser.connected
        }
    }
    /**
     central status
     */
    open var centralStatus: Int {
        get {
            return centerManager.state.rawValue
        }
    }
    /**
     current connected peripheral
     */
     open var currentConnectedPeripheral: CBPeripheral? {
         get {
             guard let parser = parser , parser.connected else { return nil }
             return parser.peripheral
         }
     }
     open var currentConnectedPeripherals: [CBPeripheral] {
         get {
             guard let parser = parser , parser.connected else { return [CBPeripheral]() }
             return parser.peripheralArray
         }
     }
    
    public static let manager = GtyCentralManager()
    /**
     the parser for parse the peripheral
     */
    open var parser: GtyParserSession? {
        didSet {
            connecter.parser = parser
        }
    }
    
    open var autoConnect = false {
        didSet {
            connecter.autoConnect = autoConnect
            if autoConnect {
                self.reconnect()
            }
        }
    }
    
    open lazy var centerManager: CBCentralManager = {
        let bleQueue = DispatchQueue(label: "com.gtyfour.queue.ble", attributes: [])
        var centerManager = CBCentralManager(delegate: self.centralProxy, queue: bleQueue)
        return centerManager
    }()
    
    open lazy var centralProxy: CentralManagerDelegateProxy = {
        var centralProxy = CentralManagerDelegateProxy(stateDelegate: self, discoveryDelegate: self.scanner, connectionDelegate: self.connecter)
        return centralProxy
    }()
    
    fileprivate lazy var connecter: GtyConnecter = {
        var connecter = GtyConnecter()
        return connecter
    }()
    
    fileprivate lazy var scanner: GtyScanner = {
        var scanner = GtyScanner()
        return scanner
    }()
    
    fileprivate let reconnectPeripheralIdentifier = "reconnectPeripheralIdentifier"
    
    fileprivate let reconnectPeripheralIdentifierMultible = "reconnectPeripheralIdentifierMultible"
    
    override init() {
        super.init()
        _ = centerManager
    }
    
    open func scanWithServices(_ serviceUUIDStrs: [String]?, duration: TimeInterval, discoveryHandle: DiscoveryHandle?, completeHandle: ScanCompleteHandle?) {
        scanner.servicesUUIDStrs = serviceUUIDStrs
        scanner.centralManager = centerManager
        _ = scanner.scanWithDuration(duration, discoveryHandle: discoveryHandle, completeHandle: completeHandle)
    }
    /** 
        `stop scan peripheral`
     */
    open func stopScan() {
        scanner.stopScan()
    }
    /**
        `connec discovery`
     */
    open func connect(_ discovery: GtyDiscovery, duration: TimeInterval, success: @escaping ConnectSuccessHandle, fail: @escaping ConnectFailHandle) {
        connecter.centralManager = centerManager
        connecter.autoConnect = autoConnect
        connecter.discovery = discovery
        
        _ = connecter.connectWithDuration(duration, connectSuccess: { [weak self] (central, peripheral) in
            guard let `self` = self else { return }
                success(central, peripheral)
            UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.reconnectPeripheralIdentifier)
            }, failHandle: fail)
    }
    /**
        `connec discovery multible`
     */
    open func connectMultible(_ discovery: GtyDiscovery, duration: TimeInterval, success: @escaping ConnectSuccessHandle, fail: @escaping ConnectFailHandle) {
        connecter.centralManager = centerManager
        connecter.autoConnect = autoConnect
        connecter.discoverys.append(discovery)
        keyname = self.reconnectPeripheralIdentifierMultible + String(connecter.discoverys.count)
        _ = connecter.connectWithDurationMultible(duration, connectSuccess: { [weak self] (central, peripheral) in
            guard let `self` = self else { return }
                success(central, peripheral)
            UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.keyname)
//            print("peripheral.identifier.uuidString:\(peripheral.identifier.uuidString)")
//            print("self.keyname:\(String(describing: self.keyname))")
            self.keyname = ""
            }, failHandle: fail)
    }
    /*
        `connect discovery with identifier`
     */
    open func connect(identifier: String, duration: TimeInterval, success: ConnectSuccessHandle?, fail: ConnectFailHandle?, complete: ScanCompleteHandle?) {
        self.scanWithServices(nil, duration: duration, discoveryHandle: { [weak self] discovery in
            guard let `self` = self else { return }
            if discovery.peripheral.identifier.uuidString == identifier {
                self.stopScan()
                self.connecter.centralManager = self.centerManager
                self.connecter.discovery = discovery
                _ = self.connecter.connectWithDuration(duration, connectSuccess: { (manager, peripheral) in
                print(peripheral.identifier.uuidString)
                    UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.reconnectPeripheralIdentifier)
                    success?(manager, peripheral)
                }, failHandle: fail)
            }
            }, completeHandle: complete)
    }
    /*
     - param clearAutoConnect   remove `auto connect` when cancel connect
     */
    open func cancelConnect(clearAutoConnect: Bool) {
        if clearAutoConnect {
            UserDefaults.standard.removeObject(forKey: reconnectPeripheralIdentifier)
        }
        connecter.disConnect()
    }
    /*
     - param clearAutoConnect   remove `auto connect` when cancel connect
     */
    open func cancelConnectMultible(clearAutoConnect: Bool) {
        if clearAutoConnect {
            for i in 1 ..< connecter.discoverys.count{
              keyname = reconnectPeripheralIdentifierMultible + String(i)
              UserDefaults.standard.removeObject(forKey: keyname)
            }
            connecter.discoverys.removeAll()
        }
        connecter.disConnectMultible()
    }
    /*
     - param clearAutoConnect   remove `auto connect` when cancel connect
     */
    open func cancelConnectWithNumber(clearAutoConnect: Bool, _ peripheralNumber:Int) {
        if clearAutoConnect {
            keyname = reconnectPeripheralIdentifierMultible + String(peripheralNumber)
            UserDefaults.standard.removeObject(forKey: keyname)
            connecter.discoverys.remove(at: peripheralNumber)
        }
        connecter.disConnectMultible()
    }
    open func reconnectWithIdentifier(duration: TimeInterval, success: ConnectSuccessHandle?, fail: ConnectFailHandle?, complete: ScanCompleteHandle?) {
        self.scanWithServices(nil, duration: duration, discoveryHandle: { [weak self] discovery in
            guard let `self` = self else { return }
            let uuidStr = UserDefaults.standard.object(forKey: self.reconnectPeripheralIdentifier) as? String
            if discovery.peripheral.identifier.uuidString == uuidStr {
                self.stopScan()
                self.connecter.centralManager = self.centerManager
                self.connecter.discovery = discovery
                _ = self.connecter.connectWithDuration(duration, connectSuccess: { (manager, peripheral) in
                    UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.reconnectPeripheralIdentifier)
                    success?(manager, peripheral)
                    }, failHandle: fail)
            }
            }, completeHandle: complete)
    }
    open func reconnectWithIdentifierMultible(duration: TimeInterval, success: ConnectSuccessHandle?, fail: ConnectFailHandle?, complete: ScanCompleteHandle?) {
        self.scanWithServices(nil, duration: duration, discoveryHandle: { [weak self] discovery in
            guard let `self` = self else { return }
            for i in 1 ..< 6{
                self.keyname = self.reconnectPeripheralIdentifierMultible + String(i)
                let uuidStr = UserDefaults.standard.object(forKey: self.keyname) as? String
                if discovery.peripheral.identifier.uuidString == uuidStr {
                    self.connecter.centralManager = self.centerManager
                    self.connecter.discoverys.append(discovery)
                    self.keyname = self.reconnectPeripheralIdentifierMultible + String(self.connecter.discoverys.count)
                    _ = self.connecter.connectWithDurationMultible(duration, connectSuccess: { (manager, peripheral) in
                        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.keyname)
                        success?(manager, peripheral)
                        }, failHandle: fail)
                }
            }
            
            
            }, completeHandle: complete)
    }
    
    //MARK: - CentralManagerStateDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: GtyCentralStateNotify), object: central.state == .poweredOn)
        centralState?(central.state.rawValue)
        switch central.state {
        case .poweredOn:
            if autoConnect {
                connecter.connectLastPeripheral()
            }
        case .poweredOff:
            parser?.connected = false
        default:
            break
        }
    }
    
    //MARK: - Private Methods
    
    fileprivate func reconnect() {
        self.reconnectWithIdentifier(duration: Double.greatestFiniteMagnitude, success: nil, fail: nil, complete: nil)
        self.reconnectWithIdentifierMultible(duration: Double.greatestFiniteMagnitude, success: nil, fail: nil, complete: nil)
    }
    
    fileprivate class func strsToUuids(_ strs:[String]?) -> [CBUUID]?{
        guard let strs = strs else { return nil }
        let UUIDs = strs.reduce([CBUUID](), { (uuids, uuidStr) -> [CBUUID] in
            let uuid = CBUUID.init(string: uuidStr)
            return uuids + [uuid]
        })
        return UUIDs
    }
}
