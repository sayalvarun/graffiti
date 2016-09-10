//
//  RequestManager.swift
//  graffiti
//
//  Created by Varun Sayal on 9/10/16.
//  Copyright © 2016 ___varun___. All rights reserved.
//


import Darwin
import UIKit
import CoreLocation

class RequestManager: NSObject,CLLocationManagerDelegate {
    
    var config : NSURLSessionConfiguration?
    var session: NSURLSession?
    let locationManager = CLLocationManager()
    
    class var sharedInstance : RequestManager {
        struct Static {
            static var token : dispatch_once_t = 0
            static var sharedInstance : RequestManager? = nil
        }
        
        dispatch_once(&Static.token) {
            Static.sharedInstance = RequestManager()
        }
        return Static.sharedInstance!
    }
    
    override init() {
        super.init()
        config = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: config!)
        
        // Get in use gps permissions
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func getDoodle(action: (doodle: Doodle) -> Void, semaphore: dispatch_semaphore_t) {
        let todoEndpoint: String = "http://varunsayal.com:5000/doodle"
        guard let url = NSURL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return 
        }
        let urlRequest = NSURLRequest(URL: url)
        let task = self.session!.dataTaskWithRequest(urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }

            do{
                let json = try NSJSONSerialization.JSONObjectWithData(responseData, options: .AllowFragments)
                
                let entries = json["entries"]
                
                for entry in entries as! [Dictionary<String, AnyObject>]
                {
                    let doodleID = entry["id"] as! Int32
                    let payload = entry["payload"] as! String
                    
                    guard let decodedData = NSData(base64EncodedString: payload, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) else{
                        print("Error: Decoding from base64")
                        return
                    }
                    
                    let headeroffset = 6 // constant 6 bytes are prepended to payload
                    let realDecodedData = NSData(bytes: decodedData.bytes+headeroffset, length:decodedData.length-headeroffset)
                    
                    if let image = UIImage(data: realDecodedData, scale: 1.0)
                    {
                        action(doodle: Doodle(id: doodleID, image: image))
                    }else{
                        print("Error: Could not make image")
                    }

                }
            }catch{
                print("Error making to json: \(error)")
            }
            
            dispatch_semaphore_signal(semaphore)
            
        }
        task.resume()
    }
    
    func tagDoodle(doodle: NSData){
        
        // Set up base URL
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "varunsayal.com"
        urlComponents.port = 5000
        urlComponents.path = "/tag"
        
        guard let gpslocation = self.locationManager.location?.coordinate else{
            print("Error: Could not get GPS coordinates")
            return
        }
        // Grab lat long
        let lat = gpslocation.latitude
        let long = gpslocation.longitude
        
        // Create list of url components
        let latQuery = NSURLQueryItem(name: "lat", value: String(lat))
        let longQuery = NSURLQueryItem(name: "long", value: String(long))
        urlComponents.queryItems = [latQuery, longQuery]
        
        guard let tagUrl = urlComponents.URL else {
            print("Error: cannot create URL")
            return
        }
        
        let doodleRequest = NSMutableURLRequest(URL: tagUrl)
        doodleRequest.HTTPMethod = "POST"
        
        doodleRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        doodleRequest.HTTPBody = doodle
        
        let task = self.session!.dataTaskWithRequest(doodleRequest) {
            (data, response, error) in
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            guard error == nil else {
                print("error calling POST on /todos/1")
                print(error)
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                print(responseData)
            })
        }
        task.resume()
    }


}
