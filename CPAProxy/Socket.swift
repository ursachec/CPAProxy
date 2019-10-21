//
//  Socket.swift
//  CPAProxy
//
//  Created by Chris Ballinger on 10/20/19.
//

import Foundation
import Network

@objc(CPASocketDelegate)
public protocol SocketDelegate: NSObjectProtocol {
    @objc(socket:didConnectToHost:port:)
    func socket(_ socket: Socket, didConnectTo host: String, port: UInt16)
    @objc(socketDidDisconnect:withError:)
    func socketDidDisconnect(_ socket: Socket, error: Error)
    @objc(socket:didReadData:withTag:)
    func socket(_ socket: Socket, didRead data: Data, tag: Int)
    @objc(socket:didWriteDataWithTag:)
    func socket(_ socket: Socket, didWriteData tag: Int)
    @objc(socket:didReceiveTrust:completionHandler:)
    func socket(_ socket: Socket, didReceiveTrust trust: SecTrust, completion: @escaping (_ shouldTrustPeer: Bool) -> Void)
}

@objc(CPASocketError)
public enum SocketError: Int, Error {
    case badConfig
}

extension SocketDelegate {
    func socket(_ socket: Socket, didWriteData tag: Int) {}
}

@objc(CPASocket)
public final class Socket: NSObject {
    
    public weak var delegate: SocketDelegate?
    public var delegateQueue: DispatchQueue
    
    private let socketQueue: DispatchQueue
    private var connection: NWConnection?
    
    @objc(initWithDelegate:delegateQueue:socketQueue:)
    public init(delegate: SocketDelegate? = nil,
                            delegateQueue: DispatchQueue = .main,
                            socketQueue: DispatchQueue? = nil) {
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        self.socketQueue = socketQueue ?? DispatchQueue(label: "CPASocket")
        super.init()
    }
    
    @objc(connectToHost:onPort:error:)
    public func connect(to host: String, port: UInt16) throws {
        guard let port = NWEndpoint.Port(rawValue: port) else {
            throw SocketError.badConfig
        }
        
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(options.securityProtocolOptions, { [weak self] (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
            let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
            var error: CFError?
            if let self = self, let delegate = self.delegate {
                delegate.socket(self, didReceiveTrust: trust, completion: { (shouldTrustPeer) in
                    sec_protocol_verify_complete(shouldTrustPeer)
                })
            } else if SecTrustEvaluateWithError(trust, &error) {
                sec_protocol_verify_complete(true)
            } else {
                sec_protocol_verify_complete(false)
            }
            
        }, socketQueue)
        connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: NWParameters(tls: options))
    }
    
    @objc(writeData:withTimeout:tag:)
    public func write(data: Data, timeout: TimeInterval, tag: Int) {
        connection?.send(content: data, completion: .contentProcessed({ (error) in
            self.delegate?.socket(self, didWriteData: tag)
        }))
    }
    
    @objc(readDataWithTimeout:tag:)
    public func readData(timeout: TimeInterval, tag: Int) {
        connection?.receiveMessage(completion: { (data, context, success, error) in
            guard let data = data else {
                return
            }
            self.delegate?.socket(self, didRead: data, tag: tag)
        })
    }
}

extension Socket {
    @objc(cpa_writeString:withTimeout:tag:)
    public func write(string: String, timeout: TimeInterval, tag: Int) {
        guard let data = string.data(using: .utf8) else { return }
        write(data: data, timeout: timeout, tag: tag)
    }
}
