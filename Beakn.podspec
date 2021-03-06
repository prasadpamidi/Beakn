#
# Be sure to run `pod lib lint Beakn.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Beakn"
  s.version          = "1.1.0"
  s.summary          = "A pure Swift syntactic sugar library for iBeacon region monitoring."
  s.description      = <<-DESC
                        This is a cocoapod library written in Swift intended at handling the iBeacon monitoring for apps with minimum code. It is simple and intended to address one task to do perfectly that is iBeacon region monitoring
                       DESC

  s.homepage         = "https://github.com/prasadpamidi/Beakn"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Prasad Pamidi" => "pamidi.dev@gmail.com" }
  s.source           = { :git => "https://github.com/prasadpamidi/Beakn.git", :tag => "1.1.0" }
  s.social_media_url = 'http://twitter.com/mepamidi'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Beakn' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
