
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

def pods
    pod 'AsyncDisplayKit'
    pod 'Appsee'
    pod 'DeviceUtil'
    pod 'FXBlurView'
    pod 'TPKeyboardAvoiding'
    pod 'pop'
    pod 'SocketRocket'
    pod 'JPush'
    pod 'Fabric'
end

target 'Yep' do
    swift_version = '3.0'

    pods

    target 'YepTests' do
        inherit! :search_paths
    end
end

target 'FayeClient' do
    pod 'SocketRocket'
end

post_install do |installer|
    puts 'Allow app extension api only:'
    installer.pods_project.targets.each do |target|
        case target.name
        when 'SocketRocket'
            target.build_configurations.each do |config|
                config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
                puts 'X...' + target.name
            end
        else
            puts '....' + target.name
        end
    end
end

