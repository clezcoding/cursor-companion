import SwiftUI
import AppKit

/// Über-Fenster für CursorCompanion mit Version, AppIcon und Attribution
public struct AboutView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.12))
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(white: 0.22), lineWidth: 1)
                    )

                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 54, height: 54)
            }

            VStack(spacing: 4) {
                Text("CursorCompanion")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Version 1.0.0 (Build 1)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Text("Native macOS Menubar App zur permanenten Überwachung deiner Cursor AI Pools.")
                .font(.system(size: 11.5))
                .foregroundColor(Color(white: 0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            VStack(spacing: 8) {
                HStack {
                    Text("Design & Craft:")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                    Text("Emil Kowalski Signature")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.8))
                }

                HStack {
                    Text("Architektur & Basis:")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                    Text("OpenUsage (MIT)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.8))
                }

                HStack {
                    Text("Datenschutz:")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                    Text("100% lokal & privat")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                }
            }
            .padding(12)
            .background(Color(white: 0.11))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button("GitHub Repository") {
                    if let url = URL(string: "https://github.com/clezcoding/cursor-companion") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))

                Text("·")
                    .foregroundColor(Color(white: 0.3))

                Button("OpenUsage Lizenz") {
                    if let url = URL(string: "https://github.com/leovp/OpenUsage") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.6))
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(Color(red: 0.08, green: 0.07, blue: 0.06))
    }
}
