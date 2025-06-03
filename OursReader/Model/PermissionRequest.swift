//
//  PermissionRequest.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import Foundation
import MultipeerConnectivity

struct PermitionRequest: Identifiable {
    let id = UUID()
    let peerId: MCPeerID
    let onRequest: (Bool) -> Void
}
