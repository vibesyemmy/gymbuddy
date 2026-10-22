import AVFoundation
import UIKit

/// Spoken and haptic cues. Audio ducks your music instead of stopping it.
final class CueSpeaker {
    private let synthesizer = AVSpeechSynthesizer()

    func prepare() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? session.setActive(true)
    }

    func say(_ text: String) {
        synthesizer.speak(AVSpeechUtterance(string: text))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func deactivateSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
