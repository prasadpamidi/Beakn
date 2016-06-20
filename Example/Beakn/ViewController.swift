//
//  ViewController.swift
//  Beakn
//
//  Created by Prasad Pamidi on 12/08/2015.
//  Copyright (c) 2015 Prasad Pamidi. All rights reserved.
//

import UIKit
import Beakn

let kBeaconID = "1BD36CEF-2FBA-4E8C-9B86-4C3C34507A8E"

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BeaknManager.sharedManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !BeaknManager.sharedManager.monitoring() else {
            print("already monitoring for iBeacons")
            return
        }
        
        do {
            try BeaknManager.sharedManager.startMonitoringForBeakns(beakns: [Beakn(uuid: kBeaconID, identifier: "Test iBeacon", major: .none, minor: .none)])
        } catch BeaknErrorDomain.AuthorizationError(let msg) {
            print(msg)
        } catch BeaknErrorDomain.InitializationError(let msg) {
            print(msg)
        } catch BeaknErrorDomain.InvalidBeaknInfo {
            print("Invalid Beakn info provided")
        } catch BeaknErrorDomain.InvalidUUIDString {
            print("Invalid UUID string provided")
        } catch BeaknErrorDomain.RegionMonitoringError(let msg) {
            print(msg)
        } catch {
            print("Unknown error occurred")
        }
    }
}

//MARK: - BeaknDelegate methods
extension ViewController: BeaknDelegate {
    func initializationFailed(error: NSError) {
         print("Unable to initialize BeaknManager due to error \(error)")
    }
    
    func entered(beakn:  Beakn) {
        let notification = UILocalNotification()
        notification.alertBody = "Entered iBeacon region"
        UIApplication.shared().presentLocalNotificationNow(notification)
        print("Device entered iBeacon region with identifier  \(beakn.identifier)")
    }
    
    func exited(beakn: Beakn) {
        let notification = UILocalNotification()
        notification.alertBody = "Exited iBeacon region"
        UIApplication.shared().presentLocalNotificationNow(notification)

        print("Device exited iBeacon region with identifier \(beakn.identifier)")
    }
    
    func monitoringFailedForRegion(beakn: Beakn, error: NSError) {
        print("Monitoring failed due to error \(error)")
    }
    
    func rangingComplete(beakns: [Beakn]) {
        //TODO: haven't implemented the ranging functionality yet
    }
    
    func rangingFailed(beakn: Beakn, error: NSError) {
        //TODO: haven't implemented the ranging functionality yet
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
