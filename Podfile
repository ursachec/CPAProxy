source 'https://cdn.cocoapods.org/'

use_modular_headers!

target 'CPAProxy (macOS)' do
	platform :osx, '10.14'
    pod 'CPAProxy', :path => './CPAProxy.podspec'
end

target 'CPAProxy (iOS)' do
	platform :ios, '12.0'
    pod 'CPAProxy', :path => './CPAProxy.podspec'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 8.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '8.0'
      end
    end
  end
end