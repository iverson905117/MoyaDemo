//
//  ReachabilityManager.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/11.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Reachability

class ReachabilityManager {
    
    static let shared = ReachabilityManager()
    var reachability: Reachability?
    
    var reachableHandler: ((Reachability.Connection) -> Void)?
    var unReachableHandler: (() -> Void)?
    var isReachable: Bool {
        return reachability!.connection != .unavailable
    }
    
    private init() {}

    
    /// Start notifier
    /// - Parameter hostName: Check the host connect enable
    func start(_ hostName: String? = nil) {
        stopNotifier()
        setupReachability(hostName)
        startNotifier(hostName)
    }
    
    private func startNotifier(_ hostName: String?) {
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable start notifier")
        }
    }
    
    private func stopNotifier() {
        reachability?.stopNotifier()
        reachability = nil
    }
    
    private func setupReachability(_ hostName: String? = nil) {
        if let hostName = hostName {
            reachability = try? Reachability(hostname: hostName)
        } else {
            reachability = try? Reachability()
        }
        
        // 切換網路環境會執行，但不算即時
        reachability?.whenReachable = { reachability in
            print("reachable: \(reachability.connection)")
            self.reachableHandler?(reachability.connection)
        }
        
        // 切換網路環境會執行，但不算即時
        reachability?.whenUnreachable = { reachability in
            print("unReachable hostName: \(hostName ?? "")")
            self.unReachableHandler?()
        }
    }
}
