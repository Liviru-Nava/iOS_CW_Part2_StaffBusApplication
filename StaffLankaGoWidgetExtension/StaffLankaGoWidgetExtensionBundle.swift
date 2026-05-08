//
//  StaffLankaGoWidgetExtensionBundle.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//


import SwiftUI
import WidgetKit

// Widget Extension Bundle Entry Point
// This file is the entry point for your Widget Extension target.
// It declares all widgets — including the Live Activity — that belong to this extension.
// If you already have other widgets (e.g. for the home screen), add them here alongside
// the Live Activity widget.

@main
struct StaffLankaGoWidgetExtensionBundle: WidgetBundle {

    var body: some Widget {
        // Register the Live Activity widget so the system knows about it
        StaffLankaGoLiveActivityWidget()

        // Add any other home screen widgets here if you have them, for example:
        // StaffLankaRouteStatusWidget()
        // StaffLankaNextBusWidget()
    }
}
