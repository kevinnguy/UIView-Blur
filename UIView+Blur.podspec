Pod::Spec.new do |s|
  s.name             = "UIView+Blur"
  s.version          = "1.1.0"
  s.summary          = "FORKED: Add a dynamic blur effect to any UIView"
  s.homepage         = "https://github.com/kevinnguy/UIView-Blur"
  s.license          = 'MIT'
  s.author           = { "kn" => "Kevin Nguy" }
  s.source           = { :git => "https://github.com/kevinnguy/UIView-Blur.git", :tag => :master }

  s.platform     = :ios
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'UIView+Blur'
end
