import SwiftUI

struct SettingsView: View {
    @Binding var settings: GameSettings
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.title)
                .bold()
                .foregroundStyle(GamePalette.ink)

            Form {
                Section("Feedback") {
                    Toggle("Sound Effects", isOn: $settings.soundEnabled)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                }

                Section("Controls") {
                    Toggle("Show Directional Pad", isOn: $settings.showsDirectionalPad)
                    Text("VoiceOver always enables the directional pad.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)

            Button("Done", action: onDone)
                .buttonStyle(PrimaryGameButtonStyle())
                .accessibilityIdentifier("settings.done")
        }
        .padding(24)
        .background(GamePalette.cream)
    }
}
