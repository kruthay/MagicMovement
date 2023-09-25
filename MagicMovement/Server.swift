//
//  Server.swift
//  MagicTracker
//
//  Created by Kruthay Donapati on 8/27/23.
//

import Foundation
import Network
import SwiftUI


class Server: ObservableObject {
    
    var listener: NWListener?
    var connection: NWConnection?
    var queue = DispatchQueue.global(qos: .userInitiated)
    /// New data will be place in this variable to be received by observers
   @Published var messageReceived: String = ""
    /// When there is an active listening NWConnection this will be `true`
    @Published private(set) var isReady: Bool = false
    /// Default value `true`, this will become false if the UDPListener ceases listening for any reason
    @Published var listening: Bool = true
    

    func startStopListener() {
            if let listener = self.listener {
                    self.listener = nil
                    self.stop(listener: listener)
            } else {
                    self.listener = self.start()
            }
    }
    
    func start() -> NWListener? {
        let params = NWParameters.udp
        params.allowFastOpen = true
        params.allowLocalEndpointReuse = true
        let listener = try? NWListener(using: params)
        listener?.service = NWListener.Service (type: "_mouse._udp")
        listener?.stateUpdateHandler = { update in
            switch update {
            case .ready:
                self.isReady = true
                
                print("Listener connected to port")
            case .failed, .cancelled:
                // Announce we are no longer able to listen
                DispatchQueue.main.async {
                    self.listening = false
                    self.isReady = false
                }
                print("Listener disconnected from port ")
                             
            default:
                print("Listener connecting to port ...")
            }
        }
        listener?.newConnectionHandler = { connection in
            print("Listener receiving new message")
            self.createConnection(connection: connection)
        }
        listener?.start(queue: self.queue)
        return listener
    }
    

    
    func createConnection(connection: NWConnection) {
        self.connection = connection
        self.connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("Listener ready to receive message - \(connection)")
                self.receive()
            case .cancelled, .failed:
                print("Listener failed to receive message - \(connection)")
                // Cancel the listener, something went wrong
                DispatchQueue.main.async {
                self.listener?.cancel()
                // Announce we are no longer able to listen
                    self.listening = false
                }
            default:
                print("Listener waiting to receive message - \(connection)")
            }
        }
        self.connection?.start(queue: .global())
    }
    
    func receive() {
        self.connection?.receiveMessage { data, context, isComplete, error in
            if let unwrappedError = error {
                print("Error: NWError received in \(#function) - \(unwrappedError)")
                return
            }
            guard isComplete, let data = data else {
                print("Error: Received nil Data with context - \(String(describing: context))")
                return
            }
            DispatchQueue.main.async {
                if let newString = String(data: data, encoding: .utf8) {
                    self.messageReceived = newString
                }
                
            }

            if self.listening {
                self.receive()
            }
        }
    }
    
    func cancel() {
        self.listening = false
        self.connection?.cancel()
    }
    
    func stop(listener: NWListener) {
            print("will stop")
            listener.stateUpdateHandler = nil
            listener.newConnectionHandler = nil
            listener.cancel()
            print("did stop")
    }
}
