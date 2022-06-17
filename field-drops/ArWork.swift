//
//  ArWork.swift
//  field-drops
//
//  Created by Bill Moriarty on 6/15/22.
//

import Foundation
import RealityKit
import AVFoundation
import Combine

class ArWork {
    
    let material = SimpleMaterial(color: .green, isMetallic: false)
    let mesh = MeshResource.generateBox(width: 0.05, height: 0.05, depth: 0.01, cornerRadius: 10)
    var modelEntity: ModelEntity
    var anchorEntity: AnchorEntity
    var soundPlayer =  AVAudioPlayer()
    var soundIsPlaying: Bool = false
    
    var animUpdateSubscription: Cancellable!
    
    init(material: SimpleMaterial, mesh: MeshResource, anchorEntity: AnchorEntity, name: String, soundURL: URL, position: simd_float3) {
        
        self.modelEntity = ModelEntity(mesh: mesh, materials: [material])
        self.modelEntity.physicsBody?.mode = .dynamic
        self.modelEntity.generateCollisionShapes(recursive: true)
        self.modelEntity.name = name
        self.modelEntity.position = position
        self.anchorEntity = anchorEntity
        self.soundPlayer = try! AVAudioPlayer(contentsOf: soundURL)
        self.anchorEntity.addChild(modelEntity)
        
        print("ArWork created")
        
    }
    
    func animate(entity: HasTransform,
                 duration: TimeInterval,
                 loop: Bool)
    
    {
        
        let rotation = simd_mul(
            simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0)),
            entity.transform.rotation
        )
        
        var transf = entity.transform
        transf.rotation = rotation
        
        entity.move(to: transf, relativeTo: entity.parent, duration: 3, timingFunction: AnimationTimingFunction.easeInOut )
        
        guard animUpdateSubscription == nil
        else { return }
        
        animUpdateSubscription = arView.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self,
                                                        on : entity,
                                                        { anim in
            if self.soundIsPlaying && self.soundPlayer.volume>0 && (self.soundPlayer.isPlaying==true) {
                self.animate(entity: entity, duration: duration, loop: loop)
            }
        })
    }
    
    
    func actOnSound() {
        
        if self.soundIsPlaying == false {
            // start and fade in sound
            self.soundIsPlaying.toggle()
            
            self.soundPlayer.stop()
            self.soundPlayer.volume = 0
            self.soundPlayer.play()
            
            self.animate(entity: self.modelEntity, duration: 3, loop: true)
            self.soundPlayer.setVolume(1, fadeDuration: TimeInterval(2))
            
        }
        else if self.soundIsPlaying == true {
            // fade out to 'stop' sound
            self.soundPlayer.setVolume(0, fadeDuration: TimeInterval(2))
            self.soundIsPlaying.toggle()
        }
        
    } // actOnSound
    
    func actOnTap(hitEntity: Entity) {
        if hitEntity.name == self.modelEntity.name {
            self.actOnSound()
        }
        else {
            if self.soundIsPlaying {
                self.actOnSound()
            }
        }
    }
}
