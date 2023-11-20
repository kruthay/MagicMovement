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
    @ObservedObject var server : Server = Server()
    
    var body: some View {
        VStack {
            Text(server.listening == true ? "Listening" : "Not Listening")
            Button("Restart") {
                server.startStopListener()
            }
        }
        .onAppear() {
            server.startStopListener()
        }
        
    }
       
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
