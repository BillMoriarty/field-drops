//
//  ContentView.swift
//  field-drops
//
//  Created by Bill Moriarty on 6/15/22.
//

import SwiftUI
import RealityKit
import ARKit
import UIKit
import AVFoundation
import Dispatch
import Combine
import FocusEntity

var arView = ARView()
var arWork1: ArWork?
var arWork2: ArWork?
var arWork3: ArWork?
var arWork4: ArWork?

var tappedObject = Entity()

var arWorks = [ArWork]()

var anchorEntity = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2(0.2,0.2)))

var focusSquare: FocusEntity?



struct ContentView : View {
    
    init() {
        
        // shadow receiver
        let materialFloor = OcclusionMaterial(receivesDynamicLighting: true) //
        let meshFloor = MeshResource.generatePlane(width: 0.1, depth: 0.1, cornerRadius: 1.0)
        let modelEntityFloor = ModelEntity(mesh: meshFloor, materials: [materialFloor])
        modelEntityFloor.position = simd_make_float3(0.0, 0.01, 0.0)
        anchorEntity.addChild(modelEntityFloor)
        
        
        //first piece of art
        var material = SimpleMaterial(color: .green, isMetallic: false)
        if let belize_1_img = try? TextureResource.load(
            named: "belize_1") {
            material.baseColor = .texture(belize_1_img)
        }
        let mesh = MeshResource.generateBox(width: 0.05, height: 0.05, depth: 0.01, cornerRadius: 10)
        let name = "belize_1"
        let belize_1 = Bundle.main.path(forResource: "belize_1", ofType: "m4a")
        let soundUrl = URL(fileURLWithPath: belize_1!)
        arWork1 = ArWork(material: material, mesh: mesh, anchorEntity: anchorEntity, name: name, soundURL: soundUrl, position: simd_make_float3(0,0.1,0))
        
        
        //second piece of art
        var material2 = SimpleMaterial(color: .cyan, roughness: 1.0, isMetallic: false)
        if let rain_pa_img = try? TextureResource.load(
            named: "rain_pa") {
            material2.baseColor = .texture(rain_pa_img)
        }
        let mesh2 = MeshResource.generateBox(width: 0.05, height: 0.05, depth: 0.01, cornerRadius: 10)
        let name2 = "rain_pa"
        let soundFile2 = Bundle.main.path(forResource: "rain_pa", ofType: "m4a")
        let soundUrl2 = URL(fileURLWithPath: soundFile2!)
        arWork2 = ArWork(material: material2, mesh: mesh2, anchorEntity: anchorEntity, name: name2, soundURL: soundUrl2, position: simd_make_float3(0.0, 0.2, 0.0))
        
        
        //third piece of art
        var material3 = SimpleMaterial(color: .black, isMetallic: false)
        if let paddleboarding_img = try? TextureResource.load(
            named: "paddleboarding") {
            material3.baseColor = .texture(paddleboarding_img)
        }
        let mesh3 = MeshResource.generateBox(width: 0.05, height: 0.05, depth: 0.01, cornerRadius: 10)
        let name3 = "paddleboarding"
        let soundFile3 = Bundle.main.path(forResource: "paddleboarding", ofType: "m4a")
        let soundUrl3 = URL(fileURLWithPath: soundFile3!)
        arWork3 = ArWork(material: material3, mesh: mesh3, anchorEntity: anchorEntity, name: name3, soundURL: soundUrl3, position: simd_make_float3(0.0, 0.3, 0.0))
        
        //fourth piece of art
        var material4 = SimpleMaterial(color: .black, isMetallic: false)
        if let belize_2_img = try? TextureResource.load(
            named: "belize_2") {
            material4.baseColor = .texture(belize_2_img)
        }
        let mesh4 = MeshResource.generateBox(width: 0.05, height: 0.05, depth: 0.01, cornerRadius: 10)
        let name4 = "belize_2"
        let soundFile4 = Bundle.main.path(forResource: "belize_2", ofType: "m4a")
        let soundUrl4 = URL(fileURLWithPath: soundFile4!)
        arWork4 = ArWork(material: material4, mesh: mesh4, anchorEntity: anchorEntity, name: name4, soundURL: soundUrl4, position: simd_make_float3(0.0, 0.4, 0.0))
        
        arWorks.append(arWork1!)
        arWorks.append(arWork2!)
        arWorks.append(arWork3!)
        arWorks.append(arWork4!)
        
        let spotLight = SpotLight()
        spotLight.light.color = SpotLightComponent.Color(Color.gray)
        spotLight.light.intensity = 1000
        spotLight.light.innerAngleInDegrees = 70
        spotLight.light.outerAngleInDegrees = 120
        spotLight.light.attenuationRadius = 9.0
        spotLight.shadow = SpotLightComponent.Shadow()
        spotLight.position = simd_make_float3(0.0, 0.6, 0.0)
        spotLight.orientation = simd_quatf(angle: -.pi/1.5,
                                           axis: [1,0,0])
        
        anchorEntity.addChild(spotLight)
        
    }
    
    //    @State var text = String("hello")
    
    var body: some View {
        ZStack{
            ARViewContainer().edgesIgnoringSafeArea(.all)
            
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @State var showText = false
    
    func makeUIView(context: Context) -> ARView {
        
        arView = ARView(frame: .zero)
        
        arView.environment.sceneUnderstanding.options.insert(.receivesLighting)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        
        arView.addCoaching()
        
        focusSquare = FocusEntity(on: arView, style: .classic(color: UIColor.green))
        
        arView.enableTapGesture()
        
        return arView
        
    }
    
    // required
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
}

extension ARView {
    
    public struct Environment {
        public struct ImageBasedLight {
            public var resource: EnvironmentResource?
            public var intensityExponent: Float
        }
    }
    
    
    func enableTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender: )))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap( sender: UITapGestureRecognizer? = nil) {
        
        // if nothing is placed, place them at the focus square
        if !(anchorEntity.isAnchored) {
            
            let raycastQuery: ARRaycastQuery? = arView.makeRaycastQuery(from: self.center, allowing: .estimatedPlane, alignment: .horizontal)
            
            let results: [ARRaycastResult] = arView.session.raycast(raycastQuery!)
            
            guard let transf = results.first?.anchor?.transform else {
                return
            }
            
            let tmpAnchEntity = AnchorEntity(world: transf)
            
            anchorEntity.transform = tmpAnchEntity.transform
            
            arView.scene.anchors.append(anchorEntity)
            
            focusSquare?.destroy()
            
        }
        
        else {
            guard let touchInView = sender?.location(in: self) else {
                return
            }
            
            guard let hitEntity = self.entity(
                at: touchInView
            ) else {
                // no entity was hit
                return
            }
            
            setTappedObj(hitEntity: hitEntity)
        }
    }
}

func setTappedObj(hitEntity: Entity){
    tappedObject = hitEntity
    
    for art in arWorks {
        art.actOnTap(hitEntity: tappedObject)
    }
}


extension ARView: ARCoachingOverlayViewDelegate {
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = self.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }
    
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("did deactivate coachingOverlay")
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
