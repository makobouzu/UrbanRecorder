//
//  ForthViewController.swift
//  UrbanRecorder
//
//  Created by Makoto Amano on 2020/06/15.
//  Copyright © 2020 Makoto Amano. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ForthViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var LongtitudeLabel: UILabel!
    @IBOutlet weak var AddressLabel: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var locationManager: CLLocationManager!
    var address = " "
    var geoCoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        initMap()
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        guard let locationManager = locationManager else { return }
        
        locationManager.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedWhenInUse {
            locationManager.distanceFilter = 10
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ LocationManager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        let latitude = location?.coordinate.latitude
        let longitude = location?.coordinate.longitude
        let geoCode = CLLocation(latitude: latitude!, longitude: longitude!)
        geoCoder.reverseGeocodeLocation(geoCode, completionHandler:{( placemarks, error ) in
            if let placemark = placemarks?.first {
                let administrativeArea = placemark.administrativeArea == nil ? "" : placemark.administrativeArea!
                let locality = placemark.locality == nil ? "" : placemark.locality!
                let subLocality = placemark.subLocality == nil ? "" : placemark.subLocality!
                let thoroughfare = placemark.thoroughfare == nil ? "" : placemark.thoroughfare!
                let subThoroughfare = placemark.subThoroughfare == nil ? "" : placemark.subThoroughfare!
                let placeName = !thoroughfare.contains( subLocality ) ? subLocality : thoroughfare
                
                self.address = administrativeArea + ", " + locality + ", " + placeName + ", " + subThoroughfare
                
            }
        } )
        
        map.userTrackingMode = .follow
        
        print("latitude: \(latitude!)\nlongitude: \(longitude!)")
        print(address)
        latitudeLabel.text = String(latitude!)
        LongtitudeLabel.text = String(longitude!)
        AddressLabel.text = address
        
        appDelegate.rec.setLatitude(Double(latitude!))
        appDelegate.rec.setLongtitude(Double(longitude!))
        appDelegate.rec.setAddress(address)
    }
    
    func initMap() {
        var region:MKCoordinateRegion = map.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        map.setRegion(region,animated:true)
        
        map.showsUserLocation = true
        map.userTrackingMode = .follow
    }
    
    func updateCurrentPos(_ coordinate:CLLocationCoordinate2D) {
        var region:MKCoordinateRegion = map.region
        region.center = coordinate
        map.setRegion(region,animated:true)
    }
}

