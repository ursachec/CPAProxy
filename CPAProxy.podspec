Pod::Spec.new do |s|
  s.name            = "CPAProxy"
  s.version         = "2.0.0"
  s.summary         = "CPAProxy is a thin Objective-C wrapper around Tor."
  s.author          = "Claudiu-Vlad Ursache <claudiu.vlad.ursache@gmail.com>"

  s.homepage        = "https://github.com/ursachec/CPAProxy"
  s.license         = { :type => 'MIT', :file => 'LICENSE.md' }
  s.source          = { :git => "https://github.com/ursachec/CPAProxy.git", :branch => "master"}
  s.prepare_command = <<-CMD
    bash ./scripts/build-all.sh
  CMD

  s.module_name = 'CPAProxyPod'

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.14"

  s.preserve_paths = 'LICENSE.md'

  # s.ios.resource_bundles = {"CPAProxy" => ["CPAProxyDependencies/geoip", "CPAProxyDependencies/geoip6", "CPAProxyDependencies/torrc"]}
  # s.osx.resource_bundles = {"CPAProxy" => ["CPAProxyDependencies/geoip", "CPAProxyDependencies/geoip6", "CPAProxyDependencies/torrc"]}

  s.requires_arc = true
end