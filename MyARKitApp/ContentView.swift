//
//  ContentView.swift
//  MyARKitApp
//
//  Created by Jonathan Davies on 4/1/23.
//

import SwiftUI
import UIKit
import ARKit
import RealityKit

struct ContentView: View {
    @State private var text = ""
    @State private var textStyle = TextStyles.normal
    @StateObject private var selectedNode = SelectedNode()

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(text: $text)
                            .edgesIgnoringSafeArea(.all)
                            .environmentObject(selectedNode)

            VStack {
                Spacer()
                TextField("Enter text to display in 3D", text: $text)
                    .padding(.horizontal, 16)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.bottom, 16)
        }
    }
    enum TextStyles: String, CaseIterable {
        case normal = "Normal"
        case bold = "Bold"
        case italic = "Italic"
        case boldItalic = "Bold Italic"

        var font: UIFont {
            switch self {
            case .normal:
                return UIFont.systemFont(ofSize: 1)
            case .bold:
                return UIFont.boldSystemFont(ofSize: 1)
            case .italic:
                return UIFont.italicSystemFont(ofSize: 1)
            case .boldItalic:
                return UIFont(descriptor: UIFont.boldSystemFont(ofSize: 1).fontDescriptor.withSymbolicTraits(.traitItalic)!, size: 1)
            }
        }
    }
    func applyTextStyle(geometry: SCNText, style: TextStyles) {
        geometry.font = style.font
    }
}

class SelectedNode: ObservableObject {
    @Published var node: SCNNode?
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var text: String
    @EnvironmentObject var selectedNode: SelectedNode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        uiView.session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
        uiView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        let textGeometry = SCNText(string: text, extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: 1)
        textGeometry.flatness = 0.01
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.1, 0.1, 0.1)
        textNode.position = SCNVector3(-0.5 * Float(text.count) * 0.1, -0.5, -2)
        
        uiView.scene.rootNode.addChildNode(textNode)
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        var arViewContainer: ARViewContainer
        var lastPanLocation: CGPoint?

        init(_ arViewContainer: ARViewContainer) {
            self.arViewContainer = arViewContainer
        }

        @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .began {
                let location = gesture.location(in: arViewContainer.arv)
                let hitTestResults = arViewContainer.uiView.hitTest(location, options: nil)
                arViewContainer.selectedNode.node = hitTestResults.first?.node
            } else if gesture.state == .changed {
                arViewContainer.selectedNode.node?.scale = SCNVector3(gesture.scale * 0.1, gesture.scale * 0.1, gesture.scale * 0.1)
            } else if gesture.state == .ended {
                arViewContainer.selectedNode.node = nil
            }
        }

        @objc func drag(_ gesture: UIPanGestureRecognizer) {
            let location = gesture.location(in: arViewContainer.uiView)

            if gesture.state == .began {
                let hitTestResults = arViewContainer.uiView.hitTest(location, options: nil)
                arViewContainer.selectedNode.node = hitTestResults.first?.node
                lastPanLocation = location
            } else if gesture.state == .changed {
                guard let lastLocation = lastPanLocation, let node = arViewContainer.selectedNode.node else { return }
                let deltaX = Float(location.x - lastLocation.x) * 0.01
                let deltaY = Float(location.y - lastLocation.y) * 0.01
                node.localTranslate(by: SCNVector3(deltaX, -deltaY, 0))
                lastPanLocation = location
            } else if gesture.state == .ended {
                arViewContainer.selectedNode.node = nil
                lastPanLocation = nil
            }
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
