Pod::Spec.new do |s|
  s.name             = 'SwiftAI'
  s.version          = '1.0.0'
  s.summary          = 'Comprehensive AI/ML framework for iOS with CoreML integration.'
  s.description      = <<-DESC
    SwiftAI is a comprehensive AI/ML framework for iOS applications. Features include
    CoreML integration, natural language processing, computer vision, on-device
    inference, model management, and easy-to-use APIs for machine learning tasks.
  DESC

  s.homepage         = 'https://github.com/muhittincamdali/SwiftAI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muhittin Camdali' => 'contact@muhittincamdali.com' }
  s.source           = { :git => 'https://github.com/muhittincamdali/SwiftAI.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'Foundation', 'CoreML', 'Vision', 'NaturalLanguage'
end
