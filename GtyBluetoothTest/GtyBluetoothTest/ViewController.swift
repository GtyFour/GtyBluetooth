//
//  ViewController.swift
//  MatataBLETest
//
//  Created by 高天元 on 2019/10/11.
//  Copyright © 2019 高天元. All rights reserved.
//

import UIKit
import CoreBluetooth

//public let ERR_DATA_LOST:Int = 10001
//public let ERR_DATA_DISMATCH:Int = 10002
//public let ERR_DATA_UNLINK:Int = 10003
//public let ALL_DATA_CORRECT:Int = 0
class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var WriteBtn: UIButton!
    @IBOutlet weak var DisconnectBtn: UIButton!
    @IBOutlet weak var ScanBtn: UIButton!
    @IBOutlet weak var CycTestBtn: UIButton!
    @IBOutlet weak var CycTestStopBtn: UIButton!
    @IBOutlet weak var CycTestCountAllLabel: UILabel!
    @IBOutlet weak var CycTestCountErrLabel: UILabel!
    @IBOutlet weak var CycTestStartTimeLabel: UILabel!
    @IBOutlet weak var CycTestEndTimeLabel: UILabel!
    @IBOutlet weak var CycTimeCellTextField: UITextField!
    var bleList = [GtyDiscovery]()
    let centralManager = GtyCentralManager.manager
    let parser = CBleParser()
    let receiverCenter = ReceiveDataCenter()
    public var expression = [UInt8]()
    public var CycTestData = [UInt8]()
    var stop_cyc:Bool = false
    var CycTestCountAll:Int = 0
    var CycTestCountCorrect:Int = 0
    var CycTestCountErr:Int = 0
    var CycTestCountErrLost:Int = 0
    var CycTestCountErrDismatch:Int = 0
    var CycTimeCell:Int = 300000
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
        
        CycTestBtn.isEnabled = true
        CycTestStopBtn.isEnabled = false
    }

    @IBAction func scanBtn(_ sender: UIButton) {
        self.bleList.removeAll()
        ScanPeripherals()
    }
    @IBAction func CycTestBtn(_ sender: UIButton) {
        
        CycTestBtn.isEnabled = false
        CycTestStopBtn.isEnabled = true
        CycTestCountAll = 0
        CycTestCountCorrect = 0
        CycTestCountErr = 0
        CycTestCountErrLost = 0
        CycTestCountErrDismatch = 0
        stop_cyc = false
        CycTimeCell = Int(self.CycTimeCellTextField.text!)!
        print(CycTimeCell)
        DispatchQueue.global().async {
            while true {
                if self.stop_cyc{
                    self.CycTestData.removeAll()
                    break
                }
                self.InitCycTestData()
                self.receiverCenter.setSendData(Data(self.CycTestData))
                self.parser.writeDataWithResponse(Data(self.CycTestData))
              switch self.receiverCenter.recivedDataCheck() {
              case 0:
                  print("[send:\([UInt8](self.receiverCenter.DataSent))]\n[recive:\([UInt8](self.receiverCenter.DataRecived))]\n++++++ALL_DATA_CORRECT+++++++")
                self.CycTestCountCorrect = self.CycTestCountCorrect + 1
                  break
              case 10001:
              print("[send:\([UInt8](self.receiverCenter.DataSent))]\n[recive:\([UInt8](self.receiverCenter.DataRecived))]\n======ERR_DATA_DATALOST=========")
                  self.CycTestCountErrLost = self.CycTestCountErrLost + 1
                  break
              case 10002:
                print("ERR_DATA_DISMATCH")
                  self.CycTestCountErrDismatch = self.CycTestCountErrDismatch + 1
                  break
              case 10003:
              print("ERR_DATA_DISMATCH")
                  self.CycTestCountErrDismatch = self.CycTestCountErrDismatch + 1
                  break
              default:
              print("NOTHING")
                  break
              }
              self.CycTestCountErr = self.CycTestCountErrLost + self.CycTestCountErrDismatch
                
              self.CycTestCountAll = self.CycTestCountCorrect + self.CycTestCountErr
                DispatchQueue.main.async { // Correct
                    self.CycTestCountAllLabel.text = String(self.CycTestCountAll)
                    self.CycTestCountErrLabel.text = String(self.CycTestCountErr)
                }
                
                usleep(useconds_t(self.CycTimeCell))
            }
        }
        
//        print("[CycTestCountAll:\(CycTestCountAll)][CycTestCountErr:\(CycTestCountErr)]")
        
    }
    @IBAction func CycTestStopBtn(_ sender: UIButton) {
        stop_cyc = true
        CycTestBtn.isEnabled = true
        CycTestStopBtn.isEnabled = false
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
            if (discovery.peripheral.name == "BotForBlueTest"){
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
      
    func InitCycTestData(){
        CycTestData.removeAll()
        for _ in 1 ..< 21{
            CycTestData.append(UInt8(arc4random_uniform(255)))
        }
//        print("CycTestData:\(CycTestData)")
    }
}

