//
//  DriverLocationPickerSheet.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-23.
//

import SwiftUI
import MapKit

struct DriverLocationPickerSheet: View {
    let sheetTitle: String
    let onConfirm: (String, CLLocationCoordinate2D) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [PickerSearchResult] = []
    @State private var isSearching: Bool = false
    @FocusState private var searchFocused: Bool
    
    @State private var pinnedCoordinate: CLLocationCoordinate2D? = nil
    @State private var pinnedLabel: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            PickerMapView(
                region: $mapRegion,
                pendingPin: pinnedCoordinate.map {
                    PickerSearchResult(title: pinnedLabel.isEmpty ? "Selected" : pinnedLabel, subtitle: "pending", coordinate: $0)
                },
                onTap: { coord in pinOnMap(coord) }
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchHeader
                    .padding(.top, safeTopPadding())
                
                if !searchResults.isEmpty {
                    searchResultsList
                }
                
                Spacer()
                
                if pinnedCoordinate != nil {
                    confirmBanner
                        .padding(.bottom, safeBottomPadding() + 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: pinnedCoordinate != nil)
        }
        .onAppear { searchFocused = true }
    }
    
    private var searchHeader: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(searchFocused ? Color.brandAccent : Color.textTertiary)
                
                TextField("Search location...", text: $searchQuery)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .tint(Color.brandAccent)
                    .focused($searchFocused)
                    .onChange(of: searchQuery) { _, q in searchLocations(query: q) }
                
                if isSearching {
                    ProgressView().tint(Color.brandAccent).scaleEffect(0.8)
                } else if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(searchFocused ? Color.brandAccent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 16)
    }
    
    private var searchResultsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(searchResults) { result in
                    Button {
                        selectSearchResult(result)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.brandAccent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 56)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .frame(maxHeight: 280)
    }
    
    private var confirmBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(sheetTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                Text(pinnedLabel.isEmpty ? "Location selected" : pinnedLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                if let coord = pinnedCoordinate {
                    let finalName = pinnedLabel.isEmpty ? "Selected Location" : pinnedLabel
                    onConfirm(finalName, coord)
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                    Text("Confirm").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(LinearGradient.brand)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.statusActive.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }
    
    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        req.region = mapRegion
        MKLocalSearch(request: req).start { resp, _ in
            DispatchQueue.main.async {
                self.isSearching = false
                guard let items = resp?.mapItems else { return }
                self.searchResults = items.prefix(8).map { item in
                    PickerSearchResult(
                        title: item.name ?? "Unknown",
                        subtitle: item.placemark.title ?? "",
                        coordinate: item.placemark.coordinate
                    )
                }
            }
        }
    }
    
    private func selectSearchResult(_ result: PickerSearchResult) {
        withAnimation {
            mapRegion = MKCoordinateRegion(center: result.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            pinnedCoordinate = result.coordinate
            pinnedLabel = result.title
            searchQuery = ""
            searchResults = []
            searchFocused = false
        }
    }
    
    private func pinOnMap(_ coord: CLLocationCoordinate2D) {
        withAnimation {
            pinnedCoordinate = coord
            pinnedLabel = "Pinned Location"
            searchQuery = ""
            searchResults = []
            searchFocused = false
        }
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(loc) { marks, _ in
            if let mark = marks?.first, let name = mark.name ?? mark.locality {
                DispatchQueue.main.async {
                    if self.pinnedCoordinate?.latitude == coord.latitude && self.pinnedCoordinate?.longitude == coord.longitude {
                        self.pinnedLabel = name
                    }
                }
            }
        }
    }
    
    private func safeTopPadding() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 44
    }
    private func safeBottomPadding() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 34
    }
}

struct PickerSearchResult: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D
}

struct PickerMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var pendingPin: PickerSearchResult?
    var onTap: (CLLocationCoordinate2D) -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.setRegion(region, animated: false)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(tap)
        context.coordinator.mapView = map
        return map
    }
    
    func updateUIView(_ map: MKMapView, context: Context) {
        let threshold = 0.001
        if abs(map.region.center.latitude - region.center.latitude) > threshold || abs(map.region.center.longitude - region.center.longitude) > threshold {
            map.setRegion(region, animated: true)
        }
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        if let pin = pendingPin { map.addAnnotation(PickerAnnotation(item: pin)) }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var onTap: (CLLocationCoordinate2D) -> Void
        weak var mapView: MKMapView?
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) { self.onTap = onTap }
        
        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let map = mapView else { return }
            let pt = g.location(in: map)
            onTap(map.convert(pt, toCoordinateFrom: map))
        }
        
        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ann = annotation as? PickerAnnotation else { return nil }
            let v = map.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: ann, reuseIdentifier: "pin")
            v.annotation = ann; v.canShowCallout = true; v.animatesWhenAdded = true
            v.markerTintColor = UIColor(Color.brandAccent)
            v.glyphImage = UIImage(systemName: "plus")
            return v
        }
    }
}

class PickerAnnotation: NSObject, MKAnnotation {
    let item: PickerSearchResult
    var coordinate: CLLocationCoordinate2D { item.coordinate }
    var title: String? { item.title }
    init(item: PickerSearchResult) { self.item = item }
}
