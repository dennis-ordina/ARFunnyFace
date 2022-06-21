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
var robot: Experience.Robot!

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
                    self.propId = self.propId >= 3 ? 3 : self.propId + 1
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
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        robot = nil
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
            
            case 3: // Robot
                let arAnchor = try! Experience.loadRobot()
                uiView.scene.anchors.append(arAnchor)
                robot = arAnchor
                break
          
            default:
                break
        }
    }
    
    class ARDelegateHandler: NSObject, ARSessionDelegate {
        var arViewContainer: ARViewContainer
        var isLasersDone = true

        init(_ control: ARViewContainer) {
            arViewContainer = control
            super.init()
        }

        func session(_ session: ARSession,
          didUpdate anchors: [ARAnchor]) {

            guard robot != nil else { return }

            var faceAnchor: ARFaceAnchor?
            for anchor in anchors {
                if let a = anchor as? ARFaceAnchor {
                    faceAnchor = a
                }
            }
            
            let blendShapes = faceAnchor?.blendShapes
            let eyeBlinkLeft = blendShapes?[.eyeBlinkLeft]?.floatValue
            let eyeBlinkRight = blendShapes?[.eyeBlinkRight]?.floatValue
            let browInnerUp = blendShapes?[.browInnerUp]?.floatValue
            let browLeft = blendShapes?[.browDownLeft]?.floatValue
            let browRight = blendShapes?[.browDownRight]?.floatValue
            let jawOpen = blendShapes?[.jawOpen]?.floatValue
            
            robot.robotEyeLid1?.orientation = simd_mul(
              simd_quatf(
                angle: Deg2Rad(-120 + (90 * eyeBlinkLeft!)),
                axis: [1, 0, 0]),
              simd_quatf(
                angle: Deg2Rad((90 * browLeft!) - (30 * browInnerUp!)),
                axis: [0, 0, 1]))
            
            robot.robotEyeLid2?.orientation = simd_mul(
              simd_quatf(
                angle: Deg2Rad(-120 + (90 * eyeBlinkRight!)),
                axis: [1, 0, 0]),
              simd_quatf(
                angle: Deg2Rad((-90 * browRight!) - (-30 * browInnerUp!)),
                axis: [0, 0, 1]))
            
            robot.robotJaw?.orientation = simd_quatf(
              angle: Deg2Rad(-100 + (60 * jawOpen!)),
              axis: [1, 0, 0])
            
            if (self.isLasersDone == true && jawOpen! > 0.9) {
              self.isLasersDone = false
              
              robot.notifications.showLasers.post()
              
              robot.actions.lasersDone.onAction = { _ in
                self.isLasersDone = true
              }
            }

        }
        
        func Deg2Rad(_ value: Float) -> Float {
          return value * .pi / 180
        }
    }
    
    func makeCoordinator() -> ARDelegateHandler {
      ARDelegateHandler(self)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
