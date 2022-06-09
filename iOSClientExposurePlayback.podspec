Pod::Spec.new do |spec|
spec.name         = "iOSClientExposurePlayback"
spec.version      = "3.3.100"
spec.summary      = "RedBeeMedia iOS SDK ExposurePlayback Module which combines both Exposure & Player"
spec.homepage     = "https://github.com/EricssonBroadcastServices"
spec.license      = { :type => "Apache", :file => "https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/LICENSE" }
spec.author             = { "EMP" => "jenkinsredbee@gmail.com" }
spec.documentation_url = "https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/README.md"
spec.platforms = { :ios => "11.0", :tvos => "12.0" }
spec.source       = { :git => "https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback.git", :tag => "v#{spec.version}" }
spec.source_files  = "Sources/iOSClientExposurePlayback/**/*.swift"
spec.dependency 'iOSClientExposure', '~>  3.1.0'
spec.dependency 'iOSClientPlayer', '~>  3.0.1'
end
