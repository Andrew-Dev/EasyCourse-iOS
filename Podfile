# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'EasyCourse' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for EasyCourse

    # UI
    pod 'XLPagerTabStrip'
    pod 'JGProgressHUD'
    pod 'JVFloatLabeledTextField'
    pod 'DKImagePickerController',
        :git => 'https://github.com/zhangao0086/DKImagePickerController.git',
        :branch => 'master'
    pod 'MWPhotoBrowser'
    pod 'LDONavigationSubtitleView'
    pod 'ImageScrollView'
    pod 'MXPagerView'

    # Util
    pod 'AsyncSwift'
    pod 'CryptoSwift'

    # Storage
    pod 'RealmSwift'
    pod 'KeychainSwift'
    #pod 'Cache'

    # Network
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'Socket.IO-Client-Swift'
    pod 'FacebookCore'
    pod 'FacebookLogin'
    pod 'FacebookShare'

    post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end
    end

end
