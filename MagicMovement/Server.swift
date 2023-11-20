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
    
    private(set) var isReady: Bool = false
    
    private var liftBeforePoint : CGPoint = CGPoint(x: 800, y: 600)
    

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
        params.includePeerToPeer = true
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
                    self.processTheMessage(message: newString)
                }
                
            }

            if self.listening {
                self.receive()
            }
        }
    }
    
    func processTheMessage(message: String){
        if message == "lifted" {
            liftBeforePoint =  NSEvent.mouseLocation
            print("Lifted", liftBeforePoint)
        }  else if message == "tapped" {
            leftClick()
        } else if message == "rightClicked" {
            rightClick()
        }
        else {
            processReceivedMessage(message: message)
        }
        
    }
    
    
    func leftClick() {
        var mouseLoc = liftBeforePoint
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        
            if let eventDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: mouseLoc , mouseButton: .left) {
               print("LeftClicked")
                eventDown.post(tap: .cghidEventTap)
            } else {
                print("Couldn't Create Event")
            }
            if let eventUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: mouseLoc , mouseButton: .left) {
                print("LeftReleased")
                eventUp.post(tap: .cghidEventTap)
            } else {
                print("Down event couldn't create")
            }
            
        print("Left Event Done")
            
    }

    func rightClick() {
        var mouseLoc = liftBeforePoint
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        if let eventDown = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: mouseLoc , mouseButton: .right) {
           print("LeftClicked")
            eventDown.post(tap: .cghidEventTap)
        } else {
            print("Couldn't Create Event")
        }
        if let eventUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: mouseLoc , mouseButton: .right) {
            print("LeftReleased")
            eventUp.post(tap: .cghidEventTap)
        } else {
            print("Down event couldn't create")
        }
    }
    
    

    
    
    func processReceivedMessage(message: String) {
        let components = message.components(separatedBy: ",")
        if components.count == 2, let x = Double(components[0]), let y = Double(components[1]) {
            moveMousePointer(to: CGPoint(x: x*3, y: y*1.5))
//            CGDisplayMoveCursorToPoint(0, CGPoint(x:x, y: y))
//            lastMovedPoint = CGPoint(x:x, y: y)
        }
        else {
            print("Not Working")
        }
    }
    
    func moveMousePointer(to point: CGPoint) {
        var mouseLoc = liftBeforePoint
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x + point.x, y: mouseLoc.y + point.y)
        CGDisplayMoveCursorToPoint(0, newLoc)
        
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
