//
//  UUIDs.swift
//  UrbanRecorder
//
//  Created by Makoto Amano on 2020/06/14.
//  Copyright © 2020 Makoto Amano. All rights reserved.
//

import Foundation

struct Bluetooth {
    static let kPeripheralName = "M5Stick-C_Env"
    /// サービスのUUID
    struct Service {
        static let kUUID: String = "3352"
    }
    /// サービスのキャラクタリスティックのUUID
    struct Characteristic {
        static let kUUID01 = "3353"
    }
}
