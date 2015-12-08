//
//  ViewController.swift
//  Beakn
//
//  Created by Prasad Pamidi on 12/08/2015.
//  Copyright (c) 2015 Prasad Pamidi. All rights reserved.
//

import UIKit
import Beakn

class ViewController: UIViewController, BeaknDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 9.0, *) {
            BeaknManager.sharedManager.delegate = self
        } else {
            // Fallback on earlier versions
        }
        
        do {
            if #available(iOS 9.0, *) {
                try BeaknManager.sharedManager.startMonitoringForBeakns([Beakn(uuid: "", identifier: "", major: .None, minor: .None)])
            } else {
                // Fallback on earlier versions
            }
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
    
    func initializationFailed(error: NSError) {
        print("Unable to initialize BeaknManager due to error \(error)")
    }
    
    func entered(beakn:  Beakn) {
        print("Device entered region with identifier \(beakn.identifier)")
    }
    
    func exited(beakn: Beakn) {
        print("Device exited region with identifier \(beakn.identifier)")
    }
    
    func monitoringFailedForRegion(beakn: Beakn, error: NSError) {
        
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

