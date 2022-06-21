//
//  ContentView.swift
//  ARFunnyFace
//
//  Created by Dennis van Oosten on 21/06/2022.
//

import SwiftUI
import RealityKit
import ARKit

var arView: ARView!

struct ContentView : View {
    @State var propId: Int = 0
    
    func TakeSnapshot() {
      // 1
      arView.snapshot(saveToHDR: false) { (image) in
        // 2
        let compressedImage = UIImage(
          data: (image?.pngData())!)
        // 3
        UIImageWriteToSavedPhotosAlbum(
          compressedImage!, nil, nil, nil)
      }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(propId: $propId).edgesIgnoringSafeArea(.all)
            HStack{
                Spacer()
                
                Button(action: {
                    self.propId = self.propId <= 0 ? 0 : self.propId - 1
                }) {
                    Image("PreviousButton").clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: {
                  self.TakeSnapshot()
                }) {
                  Image("ShutterButton").clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: {
                  self.propId = self.propId >= 2 ? 2 : self.propId + 1
                }) {
                  Image("NextButton").clipShape(Circle())
                }
                
                Spacer()
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var propId: Int
    
    func makeUIView(context: Context) -> ARView {
        arView = ARView(frame: .zero)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        arView.scene.anchors.removeAll()
        
        let arConfiguration = ARFaceTrackingConfiguration()
        uiView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        switch(propId) {
          case 0: // Eyes
            let arAnchor = try! Experience.loadEyes()
            uiView.scene.anchors.append(arAnchor)
            break
                    
          case 1: // Glasses
            let arAnchor = try! Experience.loadGlasses()
            uiView.scene.anchors.append(arAnchor)
            break
                    
          case 2: // Mustache
            let arAnchor = try! Experience.loadMustache()
            uiView.scene.anchors.append(arAnchor)
            break
          
          default:
            break
        }
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
