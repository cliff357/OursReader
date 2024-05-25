//
//  PeerDevice.swift
//  OursReader
//
//  Created by Autotoll Developer on 8/5/2024.
//

import Foundation
import MultipeerConnectivity

struct PeerDevice: Identifiable, Hashable {
    let id = UUID()
    let peerId: MCPeerID
}
