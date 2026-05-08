//
//  DriverEditRouteStopsSheet.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-23.
//

import SwiftUI
import MapKit

struct DriverEditRouteStopsSheet: View {
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @Environment(\.dismiss) private var dismissSheet
    
    enum LocationPickerTarget: Identifiable {
        case startLocation
        case endLocation
        case newRouteStop
        var id: Int { hashValue }
    }
    
    @State private var activeLocationPickerTarget: LocationPickerTarget? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.statusWarning.opacity(0.12))
                                .frame(width: 88, height: 88)
                            Image(systemName: "map.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.statusWarning)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    Button(action: {
                        activeLocationPickerTarget = .startLocation
                    }) {
                        HStack {
                            Image(systemName: "location.fill").foregroundColor(.statusActive).frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Starting Location").font(.system(size: 11)).foregroundColor(.textSecondary)
                                Text(driverProfileViewModel.editingRouteStartLocation?.locationName ?? "Tap to set").font(.system(size: 15)).foregroundColor(.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.textTertiary)
                        }
                    }
                    
                    Button(action: {
                        activeLocationPickerTarget = .endLocation
                    }) {
                        HStack {
                            Image(systemName: "mappin").foregroundColor(.statusDanger).frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Ending Location").font(.system(size: 11)).foregroundColor(.textSecondary)
                                Text(driverProfileViewModel.editingRouteEndLocation?.locationName ?? "Tap to set").font(.system(size: 15)).foregroundColor(.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.textTertiary)
                        }
                    }
                } header: {
                    Text("Endpoints")
                }

                Section {
                    ForEach(Array(driverProfileViewModel.editingRouteStopsList.enumerated()), id: \.element.id) { index, stop in
                        HStack {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.brandAccent)
                                .frame(width: 24, alignment: .leading)
                            
                            Text(stop.stopDisplayName)
                                .font(.system(size: 15))
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .onDelete(perform: driverProfileViewModel.deleteStop)
                    .onMove(perform: driverProfileViewModel.moveStop)
                    
                    Button(action: {
                        activeLocationPickerTarget = .newRouteStop
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.brandAccent)
                            Text("Add New Stop").font(.system(size: 15, weight: .semibold)).foregroundColor(.brandAccent)
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } header: {
                    Text("Edit Your Stops")
                } footer: {
                    Text("Drag stops to reorder them or swipe left to remove a stop.")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Stops")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { driverProfileViewModel.cancelRouteEdits() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { driverProfileViewModel.saveRouteEdits() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.brandAccent)
                }
            }
            .environment(\.editMode, .constant(.active))
            .sheet(item: $activeLocationPickerTarget) { target in
                if target == .startLocation {
                    DriverLocationPickerSheet(sheetTitle: "Select Start Location") { name, coord in
                        driverProfileViewModel.editingRouteStartLocation = RouteLocationData(locationName: name, latitude: coord.latitude, longitude: coord.longitude)
                    }
                } else if target == .endLocation {
                    DriverLocationPickerSheet(sheetTitle: "Select End Location") { name, coord in
                        driverProfileViewModel.editingRouteEndLocation = RouteLocationData(locationName: name, latitude: coord.latitude, longitude: coord.longitude)
                    }
                } else if target == .newRouteStop {
                    DriverLocationPickerSheet(sheetTitle: "Select New Stop") { name, coord in
                        let newIndex = driverProfileViewModel.editingRouteStopsList.count
                        driverProfileViewModel.editingRouteStopsList.append(DriverProfileViewModel.RouteStopEntry(stopPositionIndex: newIndex, stopDisplayName: name, latitude: coord.latitude, longitude: coord.longitude))
                    }
                }
            }
        }
    }
}
