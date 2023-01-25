//
//  ViewController.swift
//  HeartRate
//
//  Created by Mobile Programming on 25/01/23.
//

import UIKit
import CoreBluetooth

let heartRateServiceCBUUID = CBUUID(string: "0x6CDFA8F8-EB5F-4517-832E-AFB7D7AD5E69")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")

class ViewController: UIViewController {
    
    @IBOutlet weak var connectView: UIVisualEffectView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblHeartRate: UILabel!
    @IBOutlet weak var deviceView: UIView?
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var deviceNameTextLabel: UILabel?
    @IBOutlet weak var layoutHeight: NSLayoutConstraint!
    
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    fileprivate var timer: Timer?
    var timerCount:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        layoutHeight.constant = 0
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        deviceView?.isHidden = false
        self.timer = Timer.scheduledTimer(timeInterval: Double(1), target: self, selector: #selector(continuousRipples), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.timer?.invalidate()
    }
    
    @objc func continuousRipples() {
        if timerCount == 30{
            let alertController = UIAlertController(title: "ALERT", message:"Please ensure Heart Rate Monitor is On and Bluetooth is active on your iOS device", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default,handler: { action in
                self.timer?.invalidate()
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            timerCount += 1
        }
        let pathFrame: CGRect = CGRect(x: -25, y: -25, width: 50, height: 50)
        
        let maxSize = min(self.parentView.bounds.width,self.parentView.bounds.height)
        let rippleEndScale = Float(maxSize - (pathFrame.width)) / Float(pathFrame.width)
        
        let path = UIBezierPath(roundedRect: pathFrame, cornerRadius: 50)
        let shapePosition = self.parentView.convert(self.view.center, from: nil)
        
        let circleShape = CAShapeLayer()
        circleShape.path = path.cgPath
        circleShape.position = shapePosition
        circleShape.fillColor = UIColor.clear.cgColor
        circleShape.opacity = 0
        circleShape.zPosition = -1
        circleShape.strokeColor = UIColor.white.cgColor
        circleShape.lineWidth = CGFloat(0.5)
        circleShape.zPosition = 1
        self.parentView.layer.insertSublayer(circleShape, at: 0)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(caTransform3D:CATransform3DIdentity)
        scaleAnimation.toValue = NSValue(caTransform3D:CATransform3DMakeScale(CGFloat(rippleEndScale), 1, 1))
        let alphaAnimation = CABasicAnimation(keyPath:"opacity")
        alphaAnimation.fromValue = 1
        alphaAnimation.toValue = 0
        
        let animation = CAAnimationGroup()
        animation.animations = [scaleAnimation, alphaAnimation]
        animation.duration = 3.5
        animation.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeOut)
        circleShape.add(animation, forKey:nil)
    }
    
    @IBAction func connectAction(_ sender: UIButton) {
        self.timer?.invalidate()
        centralManager.connect(heartRatePeripheral)
    }
    
    func showDevice(_ peripheral: CBPeripheral) -> Void {
        deviceNameTextLabel?.text = "Heart Rate Monitor"
        layoutHeight.constant = 157
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        case .unsupported:
            print("Unsupported")
        case .unauthorized:
            print("Unauthorized")
        case .poweredOff:
            print("PoweredOff")
        case .poweredOn:
            print("PoweredOn")
            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            
        default:
            print("Not support")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        heartRatePeripheral.delegate = self
        heartRatePeripheral = peripheral
        centralManager.stopScan()
        self.showDevice(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case heartRateMeasurementCharacteristicCBUUID:
            let bpm = heartRate(from: characteristic)
            print(bpm)
            self.lblHeartRate.text = "\(bpm)"
            self.lblTitle.text = "Heart Rate"
            self.deviceView?.isHidden = true
            self.layoutHeight.constant = 0
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
      guard let characteristicData = characteristic.value else { return -1 }
      let byteArray = [UInt8](characteristicData)

      let firstBitValue = byteArray[0] & 0x01
      if firstBitValue == 0 {
        return Int(byteArray[1])
      } else {
        return (Int(byteArray[1]) << 8) + Int(byteArray[2])
      }
    }
    
}
