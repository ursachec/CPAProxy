![CPAProxy logo](http://i.imgur.com/PiF7CWK.png?1)

CPAProxy is an Objective-C library that eases the use of Tor on iOS. It provides APIs to setup and communicate with a Tor client running on a separate thread of an application's main process.

## How to get started

- Download CPAProxy
- Read this documentation

## Usage

### ⨀ First steps

```objc
// Get resource paths for the torrc and geoip files from the main bundle
NSString *torrcPath = [[NSBundle mainBundle] pathForResource:@"torrc" ofType:nil];
NSString *geoipPath = [[NSBundle mainBundle] pathForResource:@"geoip" ofType:nil];

// Initialize a CPAProxyManager
CPAConfiguration *configuration = [CPAConfiguration configurationWithTorrcPath:torrcPath geoipPath:geoipPath];
self.cpaProxyManager = [CPAProxyManager proxyWithConfiguration:configuration];

```

Before doing anything with *CPAProxy*, you have to create a *CPAConfiguration* and a *CPAProxyManager*.

The CPAConfiguration requires paths to a torrc and a geoip file, which can be loaded from your main bundle provided you have added the CPAProxyDependencies folder to your project (recommended). 

Torrc is a configuration file used by the Tor process and is documented in length at [https://www.torproject.org/docs/tor-manual.html](https://www.torproject.org/docs/tor-manual.html). The GeoIP data is used by Tor to keep a per-country count of how many client addresses have contacted it so that it can help the bridge authority guess which countries have blocked access to it.

### ⨀  Running Tor

```objc
[self.cpaProxyManager setupWithSuccess:^(NSString *SOCKSHost, NSUInteger SOCKSPort) {

    // Use the Tor SOCKS Proxy hostname and port
    [self handleCPAProxySetupWithSOCKSHost:SOCKSHost SOCKSPort:SOCKSPort];
    
} failure:nil];
```

After you have initialized an instance of CPAProxyManager, call `-setupWithSuccess:failure:`. This will create a new thread that runs a Tor process using information from the proxy manager's configuration. On success, a SOCKS hostname and port are returned that can be used to proxy requests. In addition to the block callback, you can also listen for the `CPAProxyDidFinishSetupNotification` notification to react to a successful setup.

### ⨀  Sending a request over Tor with NSURLSessionDataTask

```

- (void)handleCPAProxySetupWithSOCKSHost:(NSString *)SOCKSHost SOCKSPort:(NSUInteger)SOCKSPort
{
    // Create a NSURLSessionConfiguration that uses the newly setup SOCKS proxy
    NSDictionary *proxyDict = @{
        (NSString *)kCFStreamPropertySOCKSProxyHost : SOCKSHost, 
        (NSString *)kCFStreamPropertySOCKSProxyPort : @(SOCKSPort)
    };
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.connectionProxyDictionary = proxyDict;
    
    // Create a NSURLSession with the configuration
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    // Send an HTTP GET Request using NSURLSessionDataTask
    NSURL *URL = [NSURL URLWithString:@"https://check.torproject.org"];
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithURL:URL];
    [dataTask resume];
}

```

After you have been notified that a CPAProxyManager setup has been completed, you can use the SOCKS proxy to anonymize your requests. For example, you could create an ephemeral *NSURLSessionConfiguration*, set *kCFStreamPropertySOCKSProxyHost* and *kCFStreamPropertySOCKSProxyPort* on its *connectionProxyDictionary*, and use *NSURLSessions* with the configuration to send *NSURLSessionTasks* over Tor.

## System Requirements

CPAProxy supports iOS 5.0+ and the architectures __armv7__, __armv7s__, __arm64__ and __i386__.

## Installation

 1. Get the source code by adding CPAProxy as a git submodule:
```git submodule add https://github.com/ursachec/CPAProxy.git External/CPAProxy```
 2. In Finder, navigate to *External/CPAProxy* and drag __CPAProxy.xcodeproj__ into your XCode project.
 3. In Finder, navigate to *External/CPAProxy/CPAProxyDependencies* and drag __torrc__ and __geoip__ into your XCode project
 4. In XCode, select your main project and then the __target__ you want to add CPAProxy to.
 5. Under *"Build Phases"* select *"Link Binary with Libraries"* and add __libCPAProxy.a__ and __libz.dylib__.
 6. Under *"Build Settings"* search for *"Other Linker Flags"* and add a new entry with the value __-ObjC__.
 7. Under *"Build Settings"* search for *"Header Search Paths"* and add a new entry with the value __External/CPAProxy__ and select __non-recursive__.

 The CPAProxy dependencies are prebuilt to allow a fast initial installation. For actual releases, you should build the dependecies yourself by running __build-all.sh__ under the *script* folder.

## Caveats

- Security implications of running Tor on iOS seem to be unknown so far, so CPAProxy is not recommended to be used in applications that want to guarantee the anonymity of users
- This product is produced independently from the Tor® anonymity software and carries no guarantee from The Tor Project about quality, suitability or anything else
- This project is still in the early stages of development, so things will be broken and not function correctly here and there 

## More info

- [The Tor Project's documentation](https://www.torproject.org/docs/documentation.html.en)
- [Selected Papers in Anonymity](http://freehaven.net/anonbib/topic.html#Anonymous_20communication)
- [Apple's URL Loading System Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html#//apple_ref/doc/uid/10000165i)
- [Apple's CFSocket Reference](https://developer.apple.com/library/mac/documentation/CoreFOundation/Reference/CFSocketRef/Reference/reference.html)
- [Apple's NSURLSession Class Reference](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/Introduction/Introduction.html)
