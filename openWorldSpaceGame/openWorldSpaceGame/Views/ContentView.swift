//
//  ContentView.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/10/23.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @State var rotateAngle: Angle = Angle(degrees: 0)
    @ObservedObject var scene = TestScene(fileNamed: "TestScene")!
    var body: some View {
        GeometryReader { geo in
            //            let scene = TestScene(fileNamed: "TestScene")
            VStack(alignment: .leading){
                SpriteView(scene: scene)
                    .popover(isPresented: $scene.showUpgradeScreen, content: {
                        VStack{
                            Button("do something") {
                                scene.isPaused = true
                            }.onDisappear() {
                                scene.isPaused = false
                            }
                            
                            Text("Player Exp: \(scene.player.exp)")
                        }.onAppear(){
                            scene.isPaused = true
                        }
                        .onDisappear(){
                            scene.isPaused = false
                        }
                    })
            }
            .ignoresSafeArea()
        }
    }
}

func calculateAngle(center: CGPoint, point: CGPoint) -> CGFloat {
    let deltaY = point.y - center.y
    let deltaX = point.x - center.x
    let angle = atan2(deltaY, deltaX) // Angle in radians
    return angle // Convert to degrees if necessary
}


#Preview {
    ContentView()
}
