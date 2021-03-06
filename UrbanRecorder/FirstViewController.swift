//
//  FirstViewController.swift
//  UrbanRecorder
//
//  Created by Makoto Amano on 2020/06/14.
//  Copyright © 2020 Makoto Amano. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation
import SwiftyDropbox

class FirstViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    var isRecording = false
    var isPlaying   = false
    var now         = " "
    var nowDay      = " "
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: Selector(("signInButton:")),
            name:UIApplication.didFinishLaunchingNotification,
            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func signInButton(_ sender: UIButton) {
        if let _ = DropboxClientsManager.authorizedClient {
            DropboxClientsManager.unlinkClients()
        }
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: { (url: URL) -> Void in UIApplication.shared.openURL(url)})
    }
    
    @IBAction func record(){
        if !isRecording {
            
//          csv recording
            appDelegate.rec.rec()
            
//          audio recording
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(AVAudioSession.Category.playAndRecord)
            try! session.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            now = appDelegate.rec.date
            nowDay = appDelegate.rec.daydate
            audioRecorder = try! AVAudioRecorder(url: appDelegate.rec.getURL(now, ".m4a"), settings:settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            isRecording = true
            label.text = "recording"
            recordButton.setTitle("STOP", for: .normal)
            playButton.isEnabled = false
        }else{
            
            audioRecorder.stop()
            appDelegate.rec.stop()
            
            
            isRecording = false
            label.text = "waiting"
            recordButton.setTitle("REC", for: .normal)
            playButton.isEnabled = true
            
        }
    }
    
    @IBAction func play(){
        if !isPlaying {
            
            audioPlayer = try! AVAudioPlayer(contentsOf: appDelegate.rec.getURL(now, ".m4a"))
            audioPlayer.delegate = self
            audioPlayer.play()
            
            isPlaying = true
            
            label.text = "playing"
            playButton.setTitle("STOP", for: .normal)
            recordButton.isEnabled = false
        }else{
            
            audioPlayer.stop()
            isPlaying = false
            
            label.text = "waiting"
            playButton.setTitle("PLAY", for: .normal)
            recordButton.isEnabled = true
            
        }
    }
    
    @IBAction func upload(){
        label.text = "uploading"
        let folder = "/" + nowDay
        appDelegate.rec.saveFolder(folderPathName: folder)
        appDelegate.rec.saveCSV(date: now, arrData: appDelegate.rec.data)
        appDelegate.rec.uploadFile(date: now, daydate: nowDay, extensions: ".m4a")
        appDelegate.rec.uploadFile(date: now, daydate: nowDay, extensions: ".csv")
        label.text = "finish uploading"
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            audioPlayer.stop()
            isPlaying = false
            label.text = "待機中"
            playButton.setTitle("PLAY", for: .normal)
            recordButton.isEnabled = true
            
        }
    }
}

