#
# Be sure to run `pod lib lint CLPhotoLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CLPhotoLib'
  s.version          = '1.0.0'
  s.summary          = '图片视频选择器<支持原图、GIF、LivePhoto>、支持图片视频编辑'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ClaudeLi/CLPhotoLib'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'claudeli@yeah.net' => 'claudeli@yeah.net' }
  s.source           = { :git => 'https://github.com/ClaudeLi/CLPhotoLib.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'CLPhotoLib/Classes/**/*.{h,m}'

  s.resource     = 'CLPhotoLib/Assets/CLPhotoLib.bundle'
  # s.resource_bundles = {
  #   'CLPhotoLib' => ['CLPhotoLib/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
    s.dependency 'CLProgressFPD'
end
