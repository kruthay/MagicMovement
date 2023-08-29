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
    @ObservedObject var server : Server = Server()
    @State var message : String = ""
    var body: some View {
        VStack {
            Text("Received Message: \(receivedMessage)")
                .padding()
            Text("Simulated Mouse X: \(Int(simulatedMousePosition.x)), Y: \(Int(simulatedMousePosition.y))")
                .padding()
            Text(server.listening == true ? "Listening" : "Not Listening")
            Text(server.isReady == true ? "Is Ready" : "Not Ready")
            Text(message)
            
        }
        .onReceive(server.$messageReceived) { msg in
            message = msg
            receivedMessage += 1
            processReceivedMessage(message: msg)
        }
        
    }
    
    

    
    
    func processReceivedMessage(message: String) {
        let components = message.components(separatedBy: ",")
        if components.count == 2, let x = Double(components[0]), let y = Double(components[1]) {
            moveMousePointer(to: CGPoint(x: x, y: y))
//            CGDisplayMoveCursorToPoint(0, CGPoint(x:x, y: y))
        }
        else {
            print("Not Working")
        }
    }
    
    func moveMousePointer(to point: CGPoint) {
        var mouseLoc = NSEvent.mouseLocation
        print("**************")
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x + point.x, y: mouseLoc.y + point.y)

//        CGDisplayMoveCursorToPoint(0, newLoc)
        CGDisplayMoveCursorToPoint(0, point)
    }
    // Usage
 // Specify the target coordinates
    

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
