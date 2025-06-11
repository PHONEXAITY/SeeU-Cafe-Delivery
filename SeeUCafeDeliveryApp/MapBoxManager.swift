//
//  MapBoxManager.swift
//  SeeUCafeDeliveryApp
//

import Foundation
import MapboxMaps
import CoreLocation
import SwiftUI

// MARK: - MapBox Configuration
class MapBoxManager: NSObject, ObservableObject {
    static let shared = MapBoxManager()
    
    private let accessToken = "pk.eyJ1IjoicHhkZXYiLCJhIjoiY21hODJrM2RnMTZhcDJscHB5NGRjOGJnMSJ9.yxKt5OcOiFuj4U21xQVhXw"
    
    @Published var currentLocation: CLLocation?
    @Published var deliveryLocations: [DeliveryLocation] = []
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
        ResourceOptionsManager.default.resourceOptions.accessToken = accessToken
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            print("Location access not authorized")
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func updateDeliveryLocations(from deliveries: [Delivery]) {
        deliveryLocations = deliveries.compactMap { delivery in
            guard let lat = delivery.customerLatitude,
                  let lng = delivery.customerLongitude else { return nil }
            
            return DeliveryLocation(
                id: delivery.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                delivery: delivery
            )
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapBoxManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Update location to backend if employee is on delivery
        updateLocationToBackend(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func updateLocationToBackend(location: CLLocation) {
        // TODO: Implement location update to backend
        // This should only happen when employee is actively on a delivery
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
}

// MARK: - Delivery Location Model
struct DeliveryLocation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let delivery: Delivery
}

// MARK: - MapBox Map View
struct MapBoxMapView: UIViewRepresentable {
    @ObservedObject var mapBoxManager = MapBoxManager.shared
    @Binding var selectedDelivery: Delivery?
    
    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        
        // Configure map style
        mapView.mapboxMap.style.uri = .streets
        
        // Set initial camera position to Luang Prabang
        let luangPrabangCoordinate = CLLocationCoordinate2D(latitude: 19.8845, longitude: 102.135)
        let cameraOptions = CameraOptions(
            center: luangPrabangCoordinate,
            zoom: 13.0
        )
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        // Add delivery markers
        addDeliveryMarkers(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        // Update markers when delivery locations change
        addDeliveryMarkers(to: uiView)
        
        // Center on current location if available
        if let currentLocation = mapBoxManager.currentLocation {
            let cameraOptions = CameraOptions(
                center: currentLocation.coordinate,
                zoom: 15.0
            )
            uiView.mapboxMap.setCamera(to: cameraOptions)
        }
    }
    
    private func addDeliveryMarkers(to mapView: MapView) {
        // Remove existing annotations
        mapView.annotations.removeAll()
        
        // Add delivery location markers
        for deliveryLocation in mapBoxManager.deliveryLocations {
            let pointAnnotation = PointAnnotation(coordinate: deliveryLocation.coordinate)
            
            // Customize marker based on delivery status
            let markerColor = getMarkerColor(for: deliveryLocation.delivery.status)
            
            // Add the annotation
            mapView.annotations.pointAnnotations.annotations.append(pointAnnotation)
        }
        
        // Add current location marker if available
        if let currentLocation = mapBoxManager.currentLocation {
            let currentLocationAnnotation = PointAnnotation(coordinate: currentLocation.coordinate)
            mapView.annotations.pointAnnotations.annotations.append(currentLocationAnnotation)
        }
    }
    
    private func getMarkerColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "pending", "preparing":
            return .systemBlue
        case "out_for_delivery":
            return .systemOrange
        case "delivered":
            return .systemGreen
        case "cancelled":
            return .systemRed
        default:
            return .systemGray
        }
    }
}

// MARK: - Enhanced Map View with Controls
struct EnhancedMapView: View {
    @StateObject private var mapBoxManager = MapBoxManager.shared
    @State private var selectedDelivery: Delivery?
    @State private var showingDeliveryDetail = false
    
    let deliveries: [Delivery]
    
    var body: some View {
        ZStack {
            // MapBox Map
            MapBoxMapView(selectedDelivery: $selectedDelivery)
                .onAppear {
                    mapBoxManager.updateDeliveryLocations(from: deliveries)
                    mapBoxManager.startLocationUpdates()
                }
                .onDisappear {
                    mapBoxManager.stopLocationUpdates()
                }
            
            // Map Controls
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Current location button
                        Button(action: centerOnCurrentLocation) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.blue)
                                .cornerRadius(22)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        
                        // Zoom to fit all deliveries
                        Button(action: zoomToFitDeliveries) {
                            Image(systemName: "map")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.orange)
                                .cornerRadius(22)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.trailing, 16)
                }
                
                Spacer()
                
                // Delivery info card if one is selected
                if let delivery = selectedDelivery {
                    DeliveryMapCard(delivery: delivery) {
                        showingDeliveryDetail = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showingDeliveryDetail) {
            if let delivery = selectedDelivery {
                DeliveryDetailView(delivery: DeliveryItem(from: delivery))
            }
        }
    }
    
    private func centerOnCurrentLocation() {
        // TODO: Implement center on current location
        print("Center on current location")
    }
    
    private func zoomToFitDeliveries() {
        // TODO: Implement zoom to fit all deliveries
        print("Zoom to fit deliveries")
    }
}

// MARK: - Delivery Map Card
struct DeliveryMapCard: View {
    let delivery: Delivery
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(Color(delivery.status.deliveryStatusColor))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(delivery.order.orderId)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let customerName = delivery.order.user?.fullName {
                        Text(customerName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if let address = delivery.deliveryAddress {
                        Text(address)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(delivery.status.deliveryStatusDisplayText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(delivery.status.deliveryStatusColor))
                    
                    Text("\(Int(delivery.order.totalPrice).formatted()) LAK")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Navigation Helper
struct NavigationHelper {
    static func openInMaps(latitude: Double, longitude: Double, destinationName: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Try Apple Maps first
        let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(latitude),\(longitude)&dirflg=d")
        
        if let url = appleMapsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to Google Maps
            let googleMapsURL = URL(string: "https://maps.google.com/?daddr=\(latitude),\(longitude)&directionsmode=driving")
            
            if let url = googleMapsURL {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Extensions
extension DeliveryItem {
    init(from delivery: Delivery) {
        let orderItems = delivery.order.orderDetails?.map { detail in
            OrderItem(
                name: detail.itemName,
                quantity: detail.quantity,
                price: Int(detail.price)
            )
        } ?? []
        
        // Parse delivery status
        let status: DeliveryStatus
        switch delivery.status.lowercased() {
        case "pending", "preparing":
            status = .preparing
        case "out_for_delivery":
            status = .outForDelivery
        case "delivered":
            status = .delivered
        case "cancelled":
            status = .cancelled
        default:
            status = .preparing
        }
        
        // Parse estimated time
        let estimatedTime: Date
        if let timeString = delivery.estimatedDeliveryTime {
            let formatter = ISO8601DateFormatter()
            estimatedTime = formatter.date(from: timeString) ?? Date()
        } else {
            estimatedTime = Date().addingTimeInterval(3600) // 1 hour from now
        }
        
        self.init(
            id: delivery.id,
            orderID: delivery.order.orderId,
            customerName: delivery.order.user?.fullName ?? "ລູກຄ້າ",
            customerPhone: delivery.order.user?.phone ?? "",
            address: delivery.deliveryAddress ?? "",
            status: status,
            items: orderItems,
            totalAmount: Int(delivery.order.totalPrice),
            estimatedTime: estimatedTime,
            latitude: delivery.customerLatitude ?? 19.8845,
            longitude: delivery.customerLongitude ?? 102.135
        )
    }
}

extension Color {
    init(_ colorName: String) {
        switch colorName {
        case "blue":
            self = .blue
        case "orange":
            self = .orange
        case "green":
            self = .green
        case "red":
            self = .red
        default:
            self = .gray
        }
    }
}
