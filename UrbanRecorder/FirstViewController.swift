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
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var isRecording = false
    var isPlaying = false
    
    var recNow = " "
    
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
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.openURL(url)
        })
    }
    
    
    @IBAction func record(){
        if !isRecording {
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(AVAudioSession.Category.playAndRecord)
            try! session.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let dt = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm:ss", options: 0, locale: Locale(identifier: "jp_JP"))
            let date = formatter.string(from: dt)
            print(date)
            
            recNow = date
            audioRecorder = try! AVAudioRecorder(url: getURL(date), settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            isRecording = true
            
            label.text = "録音中"
            recordButton.setTitle("STOP", for: .normal)
            playButton.isEnabled = false
        }else{
            
            audioRecorder.stop()
            isRecording = false
            
            label.text = "待機中"
            recordButton.setTitle("REC", for: .normal)
            playButton.isEnabled = true
            
        }
    }
    
    @IBAction func play(){
        if !isPlaying {
            
            audioPlayer = try! AVAudioPlayer(contentsOf: getURL(recNow))
            audioPlayer.delegate = self
            audioPlayer.play()
            
            isPlaying = true
            
            label.text = "再生中"
            playButton.setTitle("STOP", for: .normal)
            recordButton.isEnabled = false
        }else{
            
            audioPlayer.stop()
            isPlaying = false
            
            label.text = "待機中"
            playButton.setTitle("PLAY", for: .normal)
            recordButton.isEnabled = true
            
        }
    }
    
    @IBAction func upload(){
        guard let fileData:Data = NSData(contentsOf: getURL(recNow)) as Data? else {
            print("error")
            return
        }
        let folder = "/" + recNow
        let file = folder + "/" + recNow + ".m4a"
        saveFile(filePathName: file, folderPathName: folder, fileData: fileData)
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
    
    func getURL(_ date: String) -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        print(docsDirect)
        let url = docsDirect.appendingPathComponent(date + ".m4a")
        return url
    }
    
    func saveFile(filePathName: String, folderPathName: String, fileData: Data) {
        guard let client = DropboxClientsManager.authorizedClient else {
            print("client error")
            return
        }
        
        _ = client.files.createFolderV2(path: folderPathName)
        let _ = client.files.upload(path: filePathName, mode: .add, autorename: false, clientModified: nil, mute: false, input: fileData).response { response, error in
            if let metadata = response {
                print("Uploaded file name: \(metadata.name)")
            } else {
                print(error!)
            }
        }
    }
}

