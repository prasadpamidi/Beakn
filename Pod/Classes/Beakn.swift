//
//  Beakn.swift
//  Pods
//
//  Created by Prasad Pamidi on 9/16/15.
//
//

import Foundation
import CoreLocation

// MARK: -  BeaknErrorDomain
/**
Beakn Error Domain and associated error messages

- InitializationError: Error happens due to an issue with initializing the BeaknManager class or CLLocationManager instance.
- AuthorizationError: Error happens due to an issue with authorization.
- RegionMonitoringError: Error happens due to an when library couldn't monitor the region.
- InvalidUUIDString: Error happens when the library is given an invalid region uuid string to monitor.
- InvalidBeaknInfo: Error happens when the library is provided with invalid region information
*/

public enum BeaknErrorDomain: ErrorType {
    case InitializationError(msg: String)
    case AuthorizationError(msg: String)
    case RegionMonitoringError(msg: String)
    case InvalidUUIDString
    case InvalidBeaknInfo
}


// MARK: -  BeaknProtocol

/**
    A protocol that the host app should implement to be able to interact with the BeaknManager library
*/
@objc public protocol BeaknDelegate: class {
    /**
     It will be called when there is an issue with the library/CLLocationManager initialization
     - Parameters:
     - error: The NSError object with description related to the error
    */
    func initializationFailed(error: NSError)
    
    /**
     It will be called when the device enters the monitored iBeacon region
     - Parameters:
     - beakn: The Beakn object that the device just entered
     */
    func entered(beakn:  Beakn)
    
    /**
     It will be called when the device exited the monitored iBeacon region
     - Parameters:
     - beakn: The Beakn object that the device just exited
     */
    func exited(beakn: Beakn)
    
    /**
     It will be called when there is an library couldn't monitor the requested region
     - Parameters:
     - error: The NSError object with description related to the error
     */
    func monitoringFailedForRegion(beakn: Beakn, error: NSError)
    
    // TODO: haven't implemented the ranging functionality yet
    func rangingComplete(beakns: [Beakn])
    func rangingFailed(beakn: Beakn, error: NSError)
}

// MARK: - BeaknProtocol
public protocol BeaknProtocol {
    var uuid: String {get set}
    var major: Int? {get set}
    var minor: Int? {get set}
    var identifier: String {get set}
}

// MARK: - Beakn structure
@objc public class Beakn: NSObject, NSCoding, BeaknProtocol  {
    //The unique uuid string for the region to be monitored
    public var uuid: String
    
    // The major value associated with the region, can be .None
    public var major: Int?
    
    // The minor value associated with the region, can be .None
    public var minor: Int?
    
    // The unique identifier string for the region to be used for comparing
    public var identifier: String
    
    /**
     Initializes a new Beakn with the provided uuid, identifier, major and minor information.
     
     - Parameters:
     - uuid: The unique uuid string for the region to be monitored
     - identifier: The unique identifier string for the region to be used for comparing
     - major: The major value associated with the region, can be .None
     - minor: The minor value associated with the region, can be .None
     
     - Returns: A Beakn object with the needed region information, this can be submitted to BeaknManager for monitoring.
     */
    public init (uuid: String, identifier: String, major: Int?, minor: Int?) {
        self.uuid = uuid
        
        if let amajor = major {
            self.major = amajor
        }
        
        if let aminor = minor {
            self.minor = aminor
        }
        
        self.identifier = identifier
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.uuid = aDecoder.decodeObjectForKey("uuid") as! String
        self.major = aDecoder.decodeObjectForKey("major") as? Int
        self.minor = aDecoder.decodeObjectForKey("minor") as? Int
        self.identifier = aDecoder.decodeObjectForKey("identifier") as! String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.uuid, forKey: "uuid")
        aCoder.encodeObject(self.major, forKey: "major")
        aCoder.encodeObject(self.minor, forKey: "minor")
        aCoder.encodeObject(self.identifier, forKey: "identifier")
    }
    
    override public var hashValue: Int { return "\(self.identifier)".hashValue }
    
    override public var description: String {
        return "UUID: \(uuid) - identifier: \(identifier) - Major: \(major) - Minor: \(minor)"
    }
    
    override public var debugDescription: String {
        return "UUID: \(uuid) - identifier: \(identifier) - Major: \(major) - Minor: \(minor)"
    }
}

// MARK: - Beakn extenstion for equatable  protocol
func == (lhs: Beakn, rhs: Beakn) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.identifier == rhs.identifier
}

// MARK: - BeaknManager
@available(iOS 9.0, *)
@objc public class BeaknManager: NSObject {
    // The shared instance of the BeaknManager class. Highly recommended to use this while interacting with the library
    public static let sharedManager = BeaknManager()
    
    // The delegate object that will be responsible to implement the methods of BeaknDelegate that the library will call for any events
    public weak var delegate:BeaknDelegate?
    
    // The CLLocationManager instance that is used for performing iBeacon region monitoring
    private var manager: CLLocationManager
    
    // This instance variable holds the status of whether the library is monitoring any regions or not
    private var isMonitoring: Bool = false
    
    // It holds all the beakn objects that were requested by the host app to monitor
    private var repository: [String: Beakn] = [:]
    
    /**
     It holds the actual beakn objects that are actually monitored by this library
     
     - The difference between repository and monitoredRegions is that, not all the regions requested by the host app can be monitored. Some requests might fail due to various error.
     */
    private var monitoredRegions: [String: Beakn] = [:]
    
    // It holds all the beakn regions that app is currently located
    private var reachableRegions: [String: Beakn] = [:]
    
    /**
     Initializes a new BeaknManager with the provided uuid, identifier, major and minor information.
     
     - Returns: A BeaknManager object with the associated CLLocationManager initialized.
     */
    private override init() {
        manager = CLLocationManager()
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            manager.requestAlwaysAuthorization()
        }
        
        super.init()
        manager.delegate = self
    }
    
    /**
     Starts monitoring the list of iBeacons regions.
     
     - Parameter beakns:   The array to Beakn objects.
     
     - Throws: `BeaknErrorDomain` ErrorType if the monitoring for the region doesn't happen.
     
     - Returns: .None.
     */
    public func startMonitoringForBeakns(beakns: [Beakn]) throws {
        try beakns.forEach { (beakn) -> () in
            try startMonitoringForBeakn(beakn)
        }
    }
    
    /**
     Starts monitoring the given of iBeacon regions.
     
     - Parameter beakn:   The Beakn object with region information.
     
     - Throws: `BeaknErrorDomain` ErrorType if the monitoring for the region doesn't happen.
     
     - Returns: .None.
     */
    public func startMonitoringForBeakn(beakn: Beakn) throws {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services not enabled")
            throw BeaknErrorDomain.AuthorizationError(msg: "Location services not enabled")
        }
        
        guard CLLocationManager.authorizationStatus() == .AuthorizedAlways else {
            switch CLLocationManager.authorizationStatus() {
            case .Denied:
                print("User denied location services")
                throw BeaknErrorDomain.AuthorizationError(msg: "User denied location services")
            case .Restricted:
                print("App is prevented from accessing Location Services")
                throw BeaknErrorDomain.AuthorizationError(msg: "App is prevented from accessing Location Services")
            default:
                print("App doesn't have authorization to monitor regions")
                throw BeaknErrorDomain.AuthorizationError(msg: "App doesn't have authorization to monitor regions")
            }
        }
        
        guard CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion) else {
            print("Region monitoring not available on this device")
            throw BeaknErrorDomain.RegionMonitoringError(msg: "Region monitoring not available on this device")
        }
        
        guard let auuid = NSUUID(UUIDString: beakn.uuid) else {
            throw BeaknErrorDomain.InvalidUUIDString
        }
        
        let region:CLBeaconRegion!
        
        switch (beakn.major, beakn.minor) {
        case (.None, .None):
            region = CLBeaconRegion(proximityUUID: auuid, identifier: beakn.identifier)
        case (.Some(let major), .None):
            region = CLBeaconRegion(proximityUUID: auuid, major: UInt16(major), identifier: beakn.identifier)
        case (.Some(let major), .Some(let minor)):
            region = CLBeaconRegion(proximityUUID: auuid, major: UInt16(major), minor: UInt16(minor), identifier: beakn.identifier)
        default:
            print("Invalid Beakn Info provided")
            throw BeaknErrorDomain.InvalidBeaknInfo
        }
        
        region.notifyEntryStateOnDisplay = false
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        repository[beakn.identifier] = beakn
        manager.startMonitoringForRegion(region)
    }
    
    /**
     Verifies if the given Beakn object is already monitored.
     
     - Parameter beakn:   The Beakn object with region information.
     
     - Returns: A Bool value representing whether the region is monitored or not.
     */
    public func isMonitoringBeakn(beakn: Beakn) -> Bool {
        guard isMonitoring else {
            return false
        }
        
        return (monitoredRegions[beakn.identifier] != nil)
    }
    
    /**
     Verifies if the library is monitoring any regions.
     
     - Returns: A Bool value representing whether the region is monitored or not.
     */
    public func monitoring() -> Bool {
        return isMonitoring
    }
    
    
    /**
     Stops monitoring for the given set of beakn regions.
     
     - Parameter beakns:   The array Beakn objects with appropriate region information.
    */
    public func stopMonitoringForBeakns(beakns: [Beakn]) {
        guard isMonitoring else {
            return
        }
        
        beakns.forEach { (beakn) -> () in
            stopMonitoringForBeakn(beakn)
        }
    }
    
    /**
     Stops monitoring for a given beakn region.
     
     - Parameter beakns:   The array Beakn objects with appropriate region information.
     */
    public func stopMonitoringForBeakn(beakn: Beakn) {
        guard isMonitoring, let _ = monitoredRegions[beakn.identifier], region = manager.monitoredRegions.filter({$0.identifier == beakn.identifier}).first else {
            return
        }
        
        manager.stopMonitoringForRegion(region)
        monitoredRegions[beakn.identifier] = nil
        reachableRegions[beakn.identifier] = nil
    }
    
    /**
     Stops monitoring all the beakn regions currently monitored by this library.
     */
    public func stopMonitoring() {
        guard isMonitoring && monitoredRegions.count > 0 else {
            return
        }
        
        stopMonitoringForBeakns(Array(monitoredRegions.values))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.manager = aDecoder.decodeObjectForKey("manager") as! CLLocationManager
        super.init()
        
        self.isMonitoring = aDecoder.decodeBoolForKey("isMonitoring")
        self.repository = aDecoder.decodeObjectForKey("repository") as! [String: Beakn]
        self.monitoredRegions = aDecoder.decodeObjectForKey("monitoredRegions") as! [String: Beakn]
        self.reachableRegions = aDecoder.decodeObjectForKey("reachableRegions") as! [String: Beakn]
        self.delegate = aDecoder.decodeObjectForKey("delegate") as? BeaknDelegate
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeBool(self.isMonitoring, forKey: "isMonitoring")
        aCoder.encodeObject(self.repository, forKey: "repository")
        aCoder.encodeObject(self.monitoredRegions, forKey: "monitoredRegions")
        aCoder.encodeObject(self.delegate, forKey: "delegate")
        aCoder.encodeObject(self.manager, forKey: "manager")
        aCoder.encodeObject(self.reachableRegions, forKey: "reachableRegions")
    }
    
    deinit {
        //not doing anything
    }
}

// MARK: - CoreLocation, CLBeakn delegate methods
@available(iOS 9.0, *)
extension BeaknManager: CLLocationManagerDelegate {
    public func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            if status == .AuthorizedAlways {
                //do nothing
            } else if status == .AuthorizedWhenInUse {
                //alert user
                print("User granted only when in use authorization")
            } else if status == .Denied {
                //alert user
                print("User denied location access")
            }
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        guard let handler = delegate else {
            print("No delegate available to report \(error)")
            return
        }
        
        print("Unable to start location manager \(error)")
        handler.initializationFailed(error)
    }
  
    public func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        guard let aregion = region as? CLBeaconRegion, beakn = repository[aregion.identifier] else {
            return
        }
        
        isMonitoring = true
        monitoredRegions[aregion.identifier] = beakn
        manager.requestStateForRegion(aregion)
    }
    
    public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        guard let aregion = region as? CLBeaconRegion, beakn = repository[aregion.identifier], handler = delegate else {
            return
        }
        
        print("Monitoring failed for Beakn region \(beakn) due to error \(error)")
        handler.monitoringFailedForRegion(beakn, error: error)
    }
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let aregion = region as? CLBeaconRegion else {
            return
        }
        
        guard let beakn = monitoredRegions[aregion.identifier] else {
            print("Region doesn't belong in the current monitored regions")
            return
        }
        
        guard let handler = delegate else {
            print("Handler not available to report Beakn entry event \(region.identifier)")
            return
        }
        
        guard reachableRegions[aregion.identifier] == nil else {
            print("Entered event received for \(region.identifier) earlier")
            return
        }
        
        reachableRegions[region.identifier] = beakn
        handler.entered(beakn)
    }
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let aregion = region as? CLBeaconRegion, beakn = monitoredRegions[aregion.identifier], handler = delegate else {
            print("Handler not available to report Beakn exit event \(region.identifier)")
            return
        }
        
        guard let _ = reachableRegions[aregion.identifier] else {
            print("Device exited region \(region.identifier) earlier")
            return
        }
        
        reachableRegions[region.identifier] = .None
        handler.exited(beakn)
    }
}

// MARK: - Extension for Double to allow comparisions between them
extension Double {
    func compare(aValue: Double) -> NSComparisonResult {
        var result = NSComparisonResult.OrderedSame
        if self > aValue {
            result = NSComparisonResult.OrderedAscending
        } else if self < aValue {
            result = NSComparisonResult.OrderedDescending
        } else if self == aValue {
            result = NSComparisonResult.OrderedSame
        }
        
        return result
    }
}

// MARK: - Extension for CLBeacon to allow comparision
extension CLBeacon {
    func compareByDistanceWith(beakn: CLBeacon) -> NSComparisonResult {
        var result = NSComparisonResult.OrderedSame
        if beakn.proximity == .Unknown && self.proximity != .Unknown {
            result = NSComparisonResult.OrderedAscending
        } else if self.proximity.rawValue > beakn.proximity.rawValue {
            result = NSComparisonResult.OrderedDescending
        }else if self.proximity == beakn.proximity {
            if self.accuracy < 0 && beakn.accuracy > 0 {
                result =  NSComparisonResult.OrderedDescending
            } else if self.accuracy > 0 && beakn.accuracy < 0 {
                result = NSComparisonResult.OrderedAscending
            }else {
                result =  self.accuracy.compare(beakn.accuracy)
            }
        }
        
        return result
    }
    
    func beakn() -> Beakn {
        return Beakn(uuid: proximityUUID.UUIDString,identifier: "\(proximityUUID.UUIDString)", major: major.integerValue, minor: minor.integerValue)
    }
}

// MARK: -  Extension for CLBeaconRegion
extension CLBeaconRegion {
    func beaknInfo() -> Beakn {
        return Beakn(uuid: proximityUUID.UUIDString, identifier: identifier, major: major?.integerValue, minor: minor?.integerValue)
    }
}