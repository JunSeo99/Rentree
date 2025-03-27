# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
  
target 'Rentree' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
#  pod 'Alamofire'
  pod 'RxKeyboard', '2.0.0'
  pod 'ReactorKit'
  pod 'SnapKit'
  pod 'Tabman'
  pod 'Then'

  pod 'RxDataSources'
  pod 'RxGesture'
  pod 'Reusable'
  pod 'Moya/RxSwift'
  pod "Starscream"
  pod 'Kingfisher'
  
  post_install do |installer|
      installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
              end
          end
      end
  end
  # Pods for Rentree

end
