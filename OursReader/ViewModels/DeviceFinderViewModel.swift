//
//  DeviceFinderViewModel.swift
//  OursReader
//
//  Created by Autotoll Developer on 8/5/2024.
//

import MultipeerConnectivity
import Combine

class DeviceFinderViewModel: NSObject, ObservableObject {
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let session: MCSession
    private let serviceType = "nearby-devices"

    @Published var permissionRequest: PermitionRequest?
    
    @Published var selectedPeer: PeerDevice? {
        didSet {
            connect()
        }
    }
    @Published var peers: [PeerDevice] = []
    @Published var isAdvertised: Bool = false {
        didSet {
            isAdvertised ? advertiser.startAdvertisingPeer() : advertiser.stopAdvertisingPeer()
        }
    }

    func send(message: String) {
        guard let data = message.data(using: .utf8) else {
            return
        }

        do {
            if let lastPeer = joinedPeer.last {
                if session.connectedPeers.contains(lastPeer.peerId) {
                    try session.send(data, toPeers: [lastPeer.peerId], with: .reliable)
                    print("send messsage completeed")
                } else {
                    print("Target peer is not connected")
                }
            }
        } catch {
            print("Failed to send message: \(error)")
        }
    }
    
    @Published var joinedPeer: [PeerDevice] = []
    
    override init() {
        let peer = MCPeerID(displayName: "Mac")//Storage.getString(Storage.Key.userName) ?? "iPhone")
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        
        advertiser = MCNearbyServiceAdvertiser(
            peer: peer,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
        
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
        session.delegate = self
        isAdvertised = true
     
    }

    func startBrowsing() {
        browser.startBrowsingForPeers()
    }
    
    func finishBrowsing() {
        browser.stopBrowsingForPeers()
    }
    
    func show(peerId: MCPeerID) {
        guard let first = peers.first(where: { $0.peerId == peerId }) else {
            return
        }
        
        // Avoid adding duplicate peers
        if !joinedPeer.contains(where: { $0.peerId == peerId }) {
            joinedPeer.append(first)
        } else {
            print("peer already joined")
        }
    }
    
    private func connect() {
        guard let selectedPeer else {
            return
        }
        
        if session.connectedPeers.contains(selectedPeer.peerId) {
            joinedPeer.append(selectedPeer)
        } else {
            browser.invitePeer(selectedPeer.peerId, to: session, withContext: nil, timeout: 60)
        }
        print("number of joined peer: \(joinedPeer.count)")
    }
}

extension DeviceFinderViewModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        permissionRequest = PermitionRequest(
            peerId: peerID,
            onRequest: { [weak self] permission in
                invitationHandler(permission, permission ? self?.session : nil)
            }
        )
        
    }
}

extension DeviceFinderViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            self.peers.append(PeerDevice(peerId: peerID)) // first go here
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.peers.removeAll(where: { $0.peerId == peerID })
        }
    }
    
}

extension DeviceFinderViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
               switch state {
               case .connected:
                   print("Connected to \(peerID.displayName)")
                   self.show(peerId: peerID)
                   
                   DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                       let pushToken = Storage.getString(Storage.Key.pushToken)
                       self.send(message: pushToken ?? "")
                   }
                   
               case .notConnected:
                   print("Disconnected from \(peerID.displayName)")
                   self.joinedPeer.removeAll(where: { $0.peerId == peerID })
               case .connecting:
                   print("Connecting to \(peerID.displayName)")
               @unknown default:
                   print("Unknown state for \(peerID.displayName)")
               }
           }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let last = joinedPeer.last else {
            return
        }
        
        guard last.peerId == peerID else {
            return
        }
        
        guard let message = String(data: data, encoding: .utf8) else {
            return
        }

        
        print("message received: \(message)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        //
    }
}
