import CoreLocation
import GoogleMaps
import SwiftUI
import UIKit

struct MapViewWrapper: UIViewRepresentable {
  @ObservedObject var viewModel: VetMapViewModel

  func makeUIView(context: Context) -> GMSMapView {
    let camera = GMSCameraPosition.camera(
      withLatitude: viewModel.cameraLatitude,
      longitude: viewModel.cameraLongitude,
      zoom: viewModel.zoomLevel
    )
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.delegate = context.coordinator
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = true
    mapView.settings.compassButton = true
    return mapView
  }

  func updateUIView(_ mapView: GMSMapView, context: Context) {
    // 1. Update Camera if needed
    if viewModel.shouldAnimateCamera {
      let camera = GMSCameraPosition.camera(
        withLatitude: viewModel.cameraLatitude,
        longitude: viewModel.cameraLongitude,
        zoom: viewModel.zoomLevel
      )
      mapView.animate(to: camera)

      DispatchQueue.main.async {
        viewModel.shouldAnimateCamera = false
      }
    }

    // 2. Update Markers
    mapView.clear()

    for clinic in viewModel.clinics {
      let marker = GMSMarker()
      marker.position = CLLocationCoordinate2D(
        latitude: clinic.lat,
        longitude: clinic.lng
      )
      marker.title = clinic.name
      marker.snippet = clinic.address
      marker.icon = renderMarkerImage(rating: clinic.rating)
      marker.userData = clinic
      marker.map = mapView
    }
  }

  func renderMarkerImage(rating: Double?) -> UIImage {
    let text = rating.map { String(format: "%.1f", $0) } ?? "-"
    let color = UIColor.systemBlue

    let label = UILabel()
    label.text = text
    label.textColor = .white
    label.font = UIFont.boldSystemFont(ofSize: 12)
    label.textAlignment = .center
    label.backgroundColor = color
    label.layer.cornerRadius = 10
    label.layer.masksToBounds = true
    label.layer.borderColor = UIColor.white.cgColor
    label.layer.borderWidth = 2

    label.frame = CGRect(x: 0, y: 0, width: 36, height: 26)  // Pill shape

    // Add a tiny triangle at bottom to look like a pin
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 32))
    label.center = CGPoint(x: 18, y: 13)
    container.addSubview(label)

    let path = UIBezierPath()
    path.move(to: CGPoint(x: 13, y: 24))
    path.addLine(to: CGPoint(x: 18, y: 32))  // Tip
    path.addLine(to: CGPoint(x: 23, y: 24))
    path.close()

    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path.cgPath
    shapeLayer.fillColor = color.cgColor
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 2
    container.layer.insertSublayer(shapeLayer, at: 0)  // Behind label

    let renderer = UIGraphicsImageRenderer(bounds: container.bounds)
    return renderer.image { ctx in
      container.layer.render(in: ctx.cgContext)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, GMSMapViewDelegate {
    var parent: MapViewWrapper

    init(_ parent: MapViewWrapper) {
      self.parent = parent
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
      if let clinic = marker.userData as? VetClinic {
        parent.viewModel.selectedClinic = clinic
      }
      return false
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
      parent.viewModel.selectedClinic = nil
    }
  }
}
