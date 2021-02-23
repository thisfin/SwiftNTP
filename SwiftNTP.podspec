Pod::Spec.new do |s|
    s.name      = 'SwiftNTP'
    s.version   = '0.0.1'
    s.summary   = 'Network Time Protocol implementation for Swift'
    s.homepage  = "https://github.com/thisfin/#{s.name}"
    s.license   = { :type => 'MIT', :file => 'LICENSE' }
    s.authors   = { 'liyi' => 'thisfin@gmail.com' }
    s.source    = { :git => "https://github.com/thisfin/#{s.name}.git", :tag => s.version.to_s }

    s.ios.deployment_target = '10.0'
    s.platform  = :ios, '10.0'
    s.source_files = 'Sources/**/*.swift'
    s.swift_version = '5.0'

    s.dependency 'CocoaAsyncSocket', '~> 7.6.5'
end
