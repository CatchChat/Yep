
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

def pods
    pod 'Kanna', '1.0.2'
    pod 'Navi'
    pod 'Appsee'
    pod 'Alamofire'
    pod 'DeviceGuru'
    pod '1PasswordExtension'
    pod 'KeyboardMan'
    pod 'Ruler'
    pod 'Proposer'
    pod 'FXBlurView'
    pod 'Kingfisher'
    pod 'TPKeyboardAvoiding'
    pod 'pop'
    pod 'Base64'
    pod 'SocketRocket'
    pod 'RealmSwift'
    pod 'MonkeyKing', '0.0.2'
    pod 'JPush'
    pod 'Fabric'
end

target 'Yep' do
    pods

    target 'YepTests' do
        inherit! :search_paths
    end
end

target 'FayeClient' do
    pod 'SocketRocket'
    pod 'Base64'
end

target 'OpenGraph' do
    pod 'Alamofire'
    pod 'Kanna', '1.0.2'
end

target 'Remote' do
    pod 'RealmSwift'
    pod 'Alamofire'
end

target 'Persistence' do
    pod 'RealmSwift'
end

# make sure 'Alamofire', 'Kanna' allow app extension api only

post_install do |installer|
    installer.pods_project.targets.each do |target|
        case target
        when 'Alamofire', 'Kanna'
            target.build_configurations.each do |config|
                config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
            end
        end
    end
end

