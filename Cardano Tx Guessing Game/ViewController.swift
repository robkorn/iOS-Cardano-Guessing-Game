//
//  ViewController.swift
//  Cardano Tx Guessing Game
//
//  Created by Robert on 2019-05-28.
//  Copyright © 2019 Robert Kornacki. All rights reserved.
//

import UIKit
import Starscream

class ViewController: UIViewController {
    
    var socket = WebSocket(url: URL(string: "wss://nodes.soshen.io/.../.../")!)

    var blockHash = ""
    var blockNum = ""
    var adaMoved : Int = 0
    var numOfInputs : Int = 0
    var score : Int = 0
    
    @IBOutlet weak var blockHashLbl: UILabel!
    @IBOutlet weak var blockNumLbl: UILabel!
    @IBOutlet weak var adaMovedLbl: UILabel!
    @IBOutlet weak var numInputsLbl: UILabel!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var submitButton : UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        waitForNewTx()
        socket.delegate = self
        socket.connect()
    }
    
    deinit {
        socket.disconnect(forceTimeout: 0)
        socket.delegate = nil
    }
    
    @IBAction func updateGuessNum () {
       numInputsLbl.text = String(Int(stepper.value))
    }
    
    @IBAction func submitGuess () {
        var alertTitle = ""
        var alertMess = ""
        
        if (numOfInputs == Int(stepper.value)) {
            alertTitle = "Congrats!"
            alertMess = "You got it right! You have just gained 5 points!"
            self.score += 5
        }
        else {
            alertTitle = "Incorrect!"
            alertMess = "There were \(String(numOfInputs)) inputs used in this transaction."
        }
        
        let alert = UIAlertController(title: alertTitle, message: alertMess, preferredStyle: .alert)
        let action = UIAlertAction(title: "Continue", style: .default, handler: {
            action in
            self.waitForNewTx()
        })
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func waitForNewTx () {
        stepper.value = 0
        numInputsLbl.text = "0"
        blockHashLbl.text = "Waiting For New Transaction..."
        blockNumLbl.text = "..."
        adaMovedLbl.text = "..."
        scoreLbl.text = String(score)
        submitButton.isEnabled = false
    }
    
    func transactionArrived () {
        submitButton.isEnabled = true
        blockHashLbl.text = blockHash
        blockNumLbl.text = blockNum
        adaMovedLbl.text = String(adaMoved)
    }
}


extension ViewController : WebSocketDelegate {
    public func websocketDidConnect(socket: WebSocketClient) {
       print("Socket Connected")
        let subAct = "sub transactionCreated"
        socket.write(string: subAct)
    }
    
    public func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
        
    }
    
    public func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        if let data = text.data(using: .utf16) {
            let jsonData = try? JSONSerialization.jsonObject(with: data)
            
            if let jsonDict = jsonData as? [String: Any] {
                let event = (jsonDict["event"] ?? "'event' is not supplied.") as! String
                if event != "transactionCreated" {
                   return
                }
                
                if let nestedData = jsonDict["data"] as? [String: Any]{
                    let blockHash = (nestedData["block_hash"] ?? "0x") as! String
                    let blockNum = (nestedData["block_num"] ?? "0") as! String
                    let inputAmounts = (nestedData["inputs_amount"] ?? ["0 inp"]) as! [String]
                    let inputCount = inputAmounts.count
                    let inputTotal = inputAmounts.reduce(0) {(acc, b) -> Int in
                        return acc + (Int(b) ?? 0)
                    }
                    print("Block Hash: \(blockHash)")
                    print("Block Num: \(blockNum)")
                    print("Total Ada Moved: \(inputTotal)")
                    print("Total Num Of Inputs: \(inputCount)")
                    
                    self.blockHash = blockHash
                    self.blockNum = blockNum
                    self.numOfInputs = inputCount
                    self.adaMoved = inputTotal
                    transactionArrived()
                }
            }
        }

    }
    
    public func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {

    }
    
}
