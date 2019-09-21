//
//  WCSessionManager.swift
//  WatchConnectivity Framework
//
//  Created by Nick on 9/21/19.
//  Copyright © 2019 Nick. All rights reserved.
//

#if os(watchOS)
import WatchKit
#endif
import WatchConnectivity

// To remove redundancy
typealias MessageReceived = (session: WCSession, message: [String : Any], replyHandler: (([String : Any]) -> Void)?)

// Protocol to manage all watchOS delegations
protocol WatchOSDelegate: AnyObject {
    func messageReceived(tuple: MessageReceived)
}

// Protocol to manage all iOS delegations
protocol iOSDelegate: AnyObject {
    func messageReceived(tuple: MessageReceived)
}

class WCSessionManager: NSObject {

    // Singleton instance to be shared
    static let shared = WCSessionManager()
    
    // Disallow others from initializing this class
    private override init() {
        super.init()
    }
    
    // Delegates for each platform
    weak var watchOSDelegate: WatchOSDelegate?
    weak var iOSDelegate: iOSDelegate?

    // WC Default session if supported else nil
    fileprivate let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    // If device is avaliable
    var validSession: WCSession? {
        // isPaired and isWatchAppInstalled checks can only be performed on iOS platform and hence conditional compilation
        #if os(iOS)
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        else {
            return nil
        }
        
        #elseif os(watchOS)
        return session
        #endif
    }
    
    // Actually activate the session and set ourselves as the delegate
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
}

// MARK: WCSessionDelegate
extension WCSessionManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive: \(session)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate: \(session)")
        /**
         * This is to re-activate the session on the phone when the user has switched from one
         * paired watch to second paired one. Calling it like this assumes that you have no other
         * threads/part of your code that needs to be given time before the switch occurs.
         */
        self.session?.activate()
    }
    #endif

}

// MARK: Interactive Messaging
extension WCSessionManager {
    
    // 12: Live messaging, sesssion should be valid and reachable on both platforms
    private var validReachableSession: WCSession? {
        if let session = validSession, session.isReachable {
            return session
        } else {
            return nil
        }
    }
    
    // Send Messages
    func sendMessage(message: [String : AnyObject], replyHandler: (([String : Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendMessageData(data: Data, replyHandler: ((Data) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    // End Send Messages
    
    // Receivers
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleSession(session, didReceiveMessage: message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleSession(session, didReceiveMessage: message, replyHandler: replyHandler)
    }
    // End Receivers
    
    // Helper Method to handle receiving messages based on platform
    func handleSession(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil) {
        #if os(iOS)
        iOSDelegate?.messageReceived(tuple: (session, message, replyHandler))
        #elseif os(watchOS)
        watchOSDelegate?.messageReceived(tuple: (session, message, replyHandler))
        #endif
    }
}

