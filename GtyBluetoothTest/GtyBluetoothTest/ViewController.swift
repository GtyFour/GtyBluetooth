//
//  ViewController.swift
//  MatataBLETest
//
//  Created by 高天元 on 2019/10/11.
//  Copyright © 2019 高天元. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var WriteBtn: UIButton!
    @IBOutlet weak var DisconnectBtn: UIButton!
    @IBOutlet weak var ScanBtn: UIButton!
    
    var bleList = [GtyDiscovery]()
    let centralManager = GtyCentralManager.manager
    let parser = CBleParser()
    let receiverCenter = ReceiveDataCenter()
    public var expression = [UInt8]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        parser.dataComingMonitor = receiverCenter
        centralManager.parser = parser
        centralManager.cancelConnect(clearAutoConnect: true)
        
        ScanBtn.addTarget(self, action: #selector(scanBtn), for: .touchUpInside)
        WriteBtn.addTarget(self, action: #selector(writeBtn), for: .touchUpInside)
        DisconnectBtn.addTarget(self, action: #selector(disconnectBtn), for: .touchUpInside)
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    @IBAction func scanBtn(_ sender: UIButton) {
        self.bleList.removeAll()
        ScanPeripherals()
    }
    
    @IBAction func writeBtn(_ sender: UIButton) {
        expression.removeAll()
        expression.append(UInt8(0))
        expression.append(UInt8(1))
        self.parser.writeDataWithResponseWithNumber(Data(expression), peripheralNumber: 0)
        //change 0 to any number, to send data at other peripheral
    }
    
    @IBAction func disconnectBtn(_ sender: UIButton) {
        self.disconnectPeripherals()
        self.countPeripherals()
    }
    func countPeripherals(){
        print(self.centralManager.currentConnectedPeripherals)
    }
    func ScanPeripherals() {
        centralManager.scanWithServices(nil, duration: 1, discoveryHandle: { discovery in
             if (discovery.RSSI >= -70){
                           print(discovery)
                           self.bleList.insert(discovery, at: 0)
                       }
        }, completeHandle: {
            self.tableView.reloadData()
            print("scan finish")
        })
    }
    func checkBluetoothStatus() -> Bool{
        if centralManager.centralStatus != 5{
            print("设备蓝牙不可用")
            return false
        }else{
            print("设备蓝牙可用")
            return true
        }
    }
    func disconnectPeripherals(){
        self.centralManager.cancelConnect(clearAutoConnect: true)
    }
    //MARK: - gtybluetooth相关
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI : NSNumber!){
        
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        //self.setState(STATEMENT_DISCONNECTED)
    }
    
    //MARK: - tableView相关代理
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return bleList.count
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cellId = "BLECELL"
          var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellId)
          if cell == nil {
              cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: cellId)
          }
        if bleList[indexPath.row].peripheral.name != nil{
            cell!.textLabel!.text = bleList[indexPath.row].peripheral.name
        }else{
            cell!.textLabel!.text = "no name peripheral"
        }
          
          return cell!
      }
      
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            self.centralManager.connectMultible(bleList[indexPath.row], duration: 1, success: { (central, peripheral) in
                DispatchQueue.main.async {
                    print("connect success")
                }
                return
            }, fail: { (error) in
                DispatchQueue.main.async {
                    print("connect fail")
                }
                return
            })
        
      }
      
      
}

