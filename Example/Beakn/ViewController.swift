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
        guard #available(iOS 9.0, *) else {
            print("Beakn doesn't support version prior to iOS 9.0")
            return
        }
        
        BeaknManager.sharedManager.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard #available(iOS 9.0, *) else {
            print("Beakn doesn't support version prior to iOS 9.0")
            return
        }
        
        guard !BeaknManager.sharedManager.monitoring() else {
            print("already monitoring for iBeacons")
            return
        }
        
        do {
            try BeaknManager.sharedManager.startMonitoringForBeakns([Beakn(uuid: kBeaconID, identifier: "Test iBeacon", major: .None, minor: .None)])
            print("Started monitoring for iBeacons")
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
        print("Device entered iBeacon region with identifier  \(beakn.identifier)")
    }
    
    func exited(beakn: Beakn) {
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