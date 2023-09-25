//
//  ContentView.swift
//  MagicMovement
//
//  Created by Kruthay Donapati on 8/21/23.
//

import SwiftUI
import Foundation
import CoreGraphics
import Network
import Accessibility

struct ContentView: View {
    @State private var receivedMessage: Int = 0
    @State private var simulatedMousePosition: CGPoint = .zero
    @State private var lastMovedPoint : CGPoint = CGPoint(x: 0, y: 0)
    @State private var liftBeforePoint : CGPoint = CGPoint(x: 800, y: 600)
    @ObservedObject var server : Server = Server()
    @State var message : String = ""
    
    var body: some View {
        VStack {
            Text("Received Message: \(receivedMessage)")
                .padding()
            Text("Simulated Mouse X: \(Int(simulatedMousePosition.x)), Y: \(Int(simulatedMousePosition.y))")
                .padding()
            Text(server.listening == true ? "Listening" : "Not Listening")
            Text(message)
            Button("Restart") {
                server.startStopListener()
            }
            
        }
        .onReceive(server.$messageReceived) { msg in
            message = msg
            if msg == "lifted" {
                liftBeforePoint =  NSEvent.mouseLocation
                print("Lifted", liftBeforePoint)
            }  else if msg == "tapped" {
                leftClick()
                leftClick()
            }
            else {
                processReceivedMessage(message: msg)
            }
        }
        .onAppear() {
            server.startStopListener()
        }
        
    }
       

    
    func leftClick() {
            let position = NSEvent.mouseLocation // use your own CGPoint location here
            if let eventDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position , mouseButton: .left) {
               print("LeftClicked")
                eventDown.post(tap: .cghidEventTap)
            } else {
                print("Couldn't Create Event")
            }
            if let eventUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position , mouseButton: .left) {
                print("LeftReleased")
                eventUp.post(tap: .cghidEventTap)
            } else {
                print("Down event couldn't create")
            }
            
            
            //            usleep(50_000) // there's no need to sleep, it turns out
            
    }

    func rightClick() {
        DispatchQueue.main.async {
            let source = CGEventSource.init(stateID: .hidSystemState)
            let position = self.liftBeforePoint // use your own CGPoint location here
            let eventDown = CGEvent(mouseEventSource: source, mouseType: .rightMouseDown, mouseCursorPosition: position , mouseButton: .right)
            let eventUp = CGEvent(mouseEventSource: source, mouseType: .rightMouseUp, mouseCursorPosition: position , mouseButton: .right)
            eventDown?.post(tap: .cghidEventTap)
            //            usleep(50_000)   // there's no need to sleep, it turns out
            eventUp?.post(tap: .cghidEventTap)
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
        
//        var mouseLoc = NSEvent.mouseLocation
        var mouseLoc = liftBeforePoint
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x + point.x, y: mouseLoc.y + point.y)
        CGDisplayMoveCursorToPoint(0, newLoc)
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
