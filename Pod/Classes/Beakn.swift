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
public enum BeaknErrorDomain: ErrorType {
    case InitializationError(msg: String)
    case AuthorizationError(msg: String)
    case RegionMonitoringError(msg: String)
    case InvalidUUIDString
    case InvalidBeaknInfo
}

// MARK: -  BeaknProtocol
@objc public protocol BeaknDelegate: class {
    func initializationFailed(error: NSError)
    func entered(beakn:  Beakn)
    func exited(beakn: Beakn)
    func monitoringFailedForRegion(beakn: Beakn, error: NSError)
    
    //TODO: haven't implemented the ranging functionality yet
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
    public var uuid: String
    public var major: Int?
    public var minor: Int?
    public var identifier: String
    
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
@objc public class BeaknManager: NSObject, CLLocationManagerDelegate {
    public static let sharedManager = BeaknManager()
    public weak var delegate:BeaknDelegate?
    
    private var manager: CLLocationManager
    private var lastDetection: NSDate?
    private var isMonitoring: Bool = false
    private var repository: [String: Beakn] = [:]
    private var monitoredRegions: [String: Beakn] = [:]
    private var reachableRegions: [String: Beakn] = [:]
    
    private override init() {
        manager = CLLocationManager()
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            manager.requestAlwaysAuthorization()
        }
        
        super.init()
        manager.delegate = self
    }
    
    public func startMonitoringForBeakns(beakns: [Beakn]) throws {
        try beakns.forEach { (beakn) -> () in
            try startMonitoringForBeakn(beakn)
        }
    }
    
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
    
    public func isMonitoringBeakn(beakn: Beakn) -> Bool {
        guard isMonitoring else {
            return false
        }
        
        return (monitoredRegions[beakn.identifier] != nil)
    }
    
    public func monitoring() -> Bool {
        return isMonitoring
    }
    
    public func stopMonitoringForBeakns(beakns: [Beakn]) {
        guard isMonitoring else {
            return
        }
        
        beakns.forEach { (beakn) -> () in
            stopMonitoringForBeakn(beakn)
        }
    }
    
    public func stopMonitoringForBeakn(beakn: Beakn) {
        guard isMonitoring, let _ = monitoredRegions[beakn.identifier], region = manager.monitoredRegions.filter({$0.identifier == beakn.identifier}).first else {
            return
        }
        
        manager.stopMonitoringForRegion(region)
        monitoredRegions[beakn.identifier] = nil
        reachableRegions[beakn.identifier] = nil
    }
    
    public func stopMonitoring() {
        guard isMonitoring && monitoredRegions.count > 0 else {
            return
        }
        
        stopMonitoringForBeakns(Array(monitoredRegions.values))
    }
    
    // MARK: - CoreLocation, CLBeakn delegate methods
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
    
    public required init?(coder aDecoder: NSCoder) {
        self.manager = aDecoder.decodeObjectForKey("manager") as! CLLocationManager
        super.init()
        
        self.lastDetection = aDecoder.decodeObjectForKey("lastDetection") as? NSDate
        self.isMonitoring = aDecoder.decodeBoolForKey("isMonitoring")
        self.repository = aDecoder.decodeObjectForKey("repository") as! [String: Beakn]
        self.monitoredRegions = aDecoder.decodeObjectForKey("monitoredRegions") as! [String: Beakn]
        self.reachableRegions = aDecoder.decodeObjectForKey("reachableRegions") as! [String: Beakn]
        self.delegate = aDecoder.decodeObjectForKey("delegate") as? BeaknDelegate
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.lastDetection, forKey: "lastDetection")
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