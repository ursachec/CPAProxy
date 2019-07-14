Pod::Spec.new do |s|
  s.name            = "CPAProxy"
  s.version         = "1.2.0"
  s.summary         = "CPAProxy is a thin Objective-C wrapper around Tor."
  s.author          = "Claudiu-Vlad Ursache <claudiu.vlad.ursache@gmail.com>"

  s.homepage        = "https://github.com/ursachec/CPAProxy"
  s.license         = { :type => 'MIT', :file => 'LICENSE.md' }
  s.source          = { :git => "https://github.com/ursachec/CPAProxy.git", :branch => "master"}
  s.prepare_command = <<-CMD
    export PLATFORM_TARGET="iOS"
    bash ./scripts/build-all.sh
    export PLATFORM_TARGET="macOS"
    bash ./scripts/build-all.sh
  CMD

  s.dependency 'CocoaAsyncSocket'

  s.ios.deployment_target = "8.0"
  s.ios.source_files = "CPAProxy/*.{h,m}", "CPAProxyDependencies-iOS/tor_cpaproxy.h"
  s.ios.private_header_files = "CPAProxyDependencies-iOS/tor_cpaproxy.h"
  s.ios.vendored_libraries  = "CPAProxyDependencies-iOS/*.a"
  s.ios.resource_bundles = {"CPAProxy" => ["CPAProxyDependencies-iOS/geoip", "CPAProxyDependencies-iOS/geoip6", "CPAProxyDependencies-iOS/torrc"]}

  s.osx.deployment_target = "10.10"
  s.osx.source_files = "CPAProxy/*.{h,m}", "CPAProxyDependencies-macOS/tor_cpaproxy.h"
  s.osx.private_header_files = "CPAProxyDependencies-macOS/tor_cpaproxy.h"
  s.osx.vendored_libraries  = "CPAProxyDependencies-macOS/*.a"
  s.osx.resource_bundles = {"CPAProxy" => ["CPAProxyDependencies-macOS/geoip", "CPAProxyDependencies-macOS/geoip6", "CPAProxyDependencies-macOS/torrc"]}

  s.libraries   = 'crypto', 'curve25519_donna', 'ed25519_donna', 'ed25519_ref10', 'event', 'event_core',
                  'event_extra', 'event_openssl', 'event_pthreads', 'keccak-tiny', 'lzma', 'or-trunnel', 'ssl',
                  'tor-app', 'tor-buf', 'tor-compress', 'tor-container', 'tor-crypt-ops', 'tor-ctime', 'tor-encoding',
                  'tor-err', 'tor-evloop', 'tor-fdio', 'tor-fs', 'tor-geoip', 'tor-intmath', 'tor-lock', 'tor-log', 'tor-malloc',
                  'tor-math', 'tor-memarea', 'tor-meminfo', 'tor-net', 'tor-osinfo', 'tor-process', 'tor-sandbox', 'tor-smartlist-core',
                  'tor-string', 'tor-term', 'tor-thread', 'tor-time', 'tor-tls', 'tor-trace', 'tor-version', 'tor-wallclock'
  s.requires_arc = true
end