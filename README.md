# Beakn

[![CI Status](https://travis-ci.org/prasadpamidi/Beakn.svg?branch=master)](https://travis-ci.org/prasadpamidi/Beakn)
[![Version](https://img.shields.io/cocoapods/v/Beakn.svg?style=flat)](http://cocoapods.org/pods/Beakn)
[![License](https://img.shields.io/cocoapods/l/Beakn.svg?style=flat)](http://cocoapods.org/pods/Beakn)
[![Platform](https://img.shields.io/cocoapods/p/Beakn.svg?style=flat)](http://cocoapods.org/pods/Beakn)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

* To be able to use the library, please follow below mentioned steps

    1. Import Beakn and adopt the library protocol

        {% highlight swift %}
            import Beakn

            class ViewController: UIViewController, BeaknProtocol
        {% endhighlight %}

    2. Assign your class as a delegate to the library 

        {% highlight swift %}
            BeaknManager.sharedManager.delegate = self
        {% endhighlight %}
   
    3. Implement delegate methods
        {% highlight swift %}
            extension ViewController: BeaknDelegate {
                func initializationFailed(error: NSError) {
                    print("Unable to initialize BeaknManager due to error \(error)")
                }

                func entered(beakn:  Beakn) {
                    let notification = UILocalNotification()
                    notification.alertBody = "Entered iBeacon region"
                    UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                    print("Device entered iBeacon region with identifier  \(beakn.identifier)")
                }

                func exited(beakn: Beakn) {
                    let notification = UILocalNotification()
                    notification.alertBody = "Exited iBeacon region"
                    UIApplication.sharedApplication().presentLocalNotificationNow(notification)

                    print("Device exited iBeacon region with identifier \(beakn.identifier)")
                }

                func monitoringFailedForRegion(beakn: Beakn, error: NSError) {
                    print("Monitoring failed due to error \(error)")
                }

                func rangingComplete(beakns: [Beakn]) {
                }

                func rangingFailed(beakn: Beakn, error: NSError) {
                }
            }
        {% endhighlight %}
    4. Request for iBeacon Region monitoring
    {% highlight swift %}
        do {
            try BeaknManager.sharedManager.startMonitoringForBeakns([Beakn(uuid: kBeaconID, identifier: "Test iBeacon", major: .None, minor: .None)])
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
    {% endhighlight %}

## Requirements
You will have to enable location service capability for your app
You will have to add NSLocationAlwaysDescription key with appropriate description in the App's info.plist file

## Installation

Beakn is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Beakn"
```



## Author

Prasad Pamidi, pamidi.dev@gmail.com

## License

Beakn is available under the MIT license. See the LICENSE file for more info.
