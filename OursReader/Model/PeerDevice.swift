//
//  PeerDevice.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import Foundation
import MultipeerConnectivity

struct PeerDevice: Identifiable, Hashable {
    let id = UUID()
    let peerId: MCPeerID
}
