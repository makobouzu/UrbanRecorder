//
//  Recording.swift
//  UrbanRecorder
//
//  Created by Makoto Amano on 2020/06/15.
//  Copyright © 2020 Makoto Amano. All rights reserved.
//

import Foundation
import SwiftyDropbox

class Record{
    var date: String
    var timestamp: Float
    var temperature: Float
    var humidity: Float
    var pressure: Float
    var latitude: Double
    var longitude: Double
    var address: String
    var person: Int
    var car: Int
    var bicycle: Int
    var data: [[String]]
    var timer            = Timer()
    var programStart     = Date()
    var recStart:TimeInterval
    

//  base func----------------------------------------------------------------------
    init(){
        date        = " "
        timestamp   = 0.0
        temperature = 0.0
        humidity    = 0.0
        pressure    = 0.0
        latitude    = 0.0
        longitude   = 0.0
        address     = " "
        person      = 0
        car         = 0
        bicycle     = 0
        data        = [["time", "temperature", "humidity", "pressure", "latitude", "longitude", "address", "person", "car", "bicycle"]]
        recStart    = 0.0
    }

    public func rec(){
        let dt               = Date()
        let formatter        = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm:ss", options: 0, locale: Locale(identifier: "jp_JP"))
        self.date            = formatter.string(from: dt)
        self.recStart        = Date().timeIntervalSince(programStart)
        
        createCSV()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
            self.updateCSV()
        })
    }
    
    public func stop(){
        timer.invalidate()
    }
    
    public func uploadFile(date: String, extensions: String){
        guard let fileData:Data = NSData(contentsOf: getURL(date, extensions)) as Data? else {
            print("data error")
            return
        }
        let folder = "/" + date
        let file = folder + "/" + date + extensions
        saveFile(filePathName: file, fileData: fileData)
    }
    
    public func getURL(_ date: String, _ extensions: String) -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let filename:String = date + extensions
        let url = docsDirect.appendingPathComponent(filename)
        return url
    }
    
    public func saveFolder(folderPathName: String){
        guard let client = DropboxClientsManager.authorizedClient else {
            print("client error")
            return
        }
        client.files.createFolderV2(path: folderPathName).response { response, error in
            if error != nil {
                print("error")
                return
            }
            guard response != nil else {
                print("no response")
                return
            }
        }
    }
    
    private func saveFile(filePathName: String, fileData: Data) {
        guard let client = DropboxClientsManager.authorizedClient else {
            print("client error")
            return
        }
        let _ = client.files.upload(path: filePathName, mode: .add, autorename: false, clientModified: nil, mute: false, input: fileData).response { response, error in
            if let metadata = response {
                print("Uploaded file name: \(metadata.name)")
            } else {
                print(error!)
            }
        }
    }
    
//  array func----------------------------------------------------------------------
    private func createArray() -> [String]{
        let elapsed = Date().timeIntervalSince(programStart) - recStart
        let elapsedTime = elapsed * 10
        timestamp = Float(floor(elapsedTime)/10)
        let array = [String(timestamp), String(temperature), String(humidity), String(pressure), String(latitude), String(longitude), String(address), String(person), String(car), String(bicycle)]
        return array
    }
    
    private func createCSV(){
        self.data.removeAll()
        self.data.append(["time", "temperature", "humidity", "pressure", "latitude", "longitude", "address", "person", "car", "bicycle"])
    }
    
    @objc public func updateCSV(){
        self.data.append(createArray())
    }
    
    public func saveCSV(date : String, arrData : [[String]]){
        let filePath = NSHomeDirectory() + "/Documents/" + date + ".csv"
        print(filePath)
        
        print(arrData)
        var fileStrData:String = ""
        for singleArray in arrData{
            for singleString in singleArray{
                fileStrData += "\"" + singleString + "\""
//                if singleString != singleArray[singleArray.count-1]{
                    fileStrData += ","
//                }
            }
            fileStrData += "\n"
        }
        print(fileStrData)
        
        do{
            try fileStrData.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
            print("Success to Write the File")
        }catch let error as NSError{
            print("Failure to Write File\n\(error)")
        }
    }
    
//  setter--------------------------------------------------------------------------
    public func setTimestamp(_ time: Float){
        timestamp = time
    }
    
    public func setTemperature(_ temp: Float){
        temperature = temp
    }
    
    public func setHumidity(_ humid: Float){
        humidity = humid
    }
    
    public func setPressure(_ press: Float){
        pressure = press
    }
    
    public func setLatitude(_ lat: Double){
        latitude = lat
    }
    
    public func setLongtitude(_ long: Double){
        longitude = long
    }
    
    public func setAddress(_ add: String){
        address = add
    }
    
    public func setPerson(_ per: Int){
        person = per
    }
    
    public func setCar(_ ca: Int){
        car = ca
    }
    
    public func setBicycle(_ bike: Int){
        bicycle = bike
    }
    
}
