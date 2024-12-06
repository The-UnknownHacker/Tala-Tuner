import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import AVFoundation

class AudioEngine: ObservableObject {
    private var engine = AudioKit.AudioEngine()
    private var tracker: PitchTap!
    private let session = AVAudioSession.sharedInstance()
    
    @Published var pitch: Float = 0.0
    @Published var amplitude: Float = 0.0
    @Published var currentNote: String = "−"
    @Published var tuningStatus: TuningStatus = .none
    @Published var centsDeviation: Float = 0.0
    
    enum TuningStatus {
        case none, flat, inTune, sharp
    }
    
    func start() throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers])
        try session.setActive(true)
        
        guard let input = engine.input else {
            throw AudioError.microphoneAccess
        }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: session.sampleRate, channels: 1)
        engine.output = input
        
        do {
            try engine.start()
            tracker = PitchTap(input) { pitch, amp in
                DispatchQueue.main.async {
                    self.pitch = pitch[0]
                    self.amplitude = amp[0]
                    self.updateNote()
                }
            }
            tracker.start()
        } catch {
            print("Error starting engine: \(error.localizedDescription)")
        }
    }

    
    func stop() {
        tracker?.stop()
        engine.stop()
    }
    
    private func updateNote() {
        // Only process if the amplitude is sufficient
        guard amplitude > 0.1 else {
            currentNote = "−"
            tuningStatus = .none
            centsDeviation = 0.0
            return
        }
        
        let frequency = Double(pitch)
        let (note, cents) = calculateNoteAndCents(fromFrequency: frequency)
        currentNote = note
        centsDeviation = cents
        
        // Update tuning status based on cents deviation
        tuningStatus = cents < -5 ? .flat :
                      cents > 5 ? .sharp :
                      .inTune
    }
    
    private func calculateNoteAndCents(fromFrequency frequency: Double) -> (note: String, cents: Float) {
        let a4Frequency = 440.0
        let halfStepsFromA4 = 12 * log2(frequency / a4Frequency)
        let roundedHalfSteps = round(halfStepsFromA4)
        let cents = Float(100 * (halfStepsFromA4 - roundedHalfSteps))
        let midiNoteNumber = Int(roundedHalfSteps) + 69
        
        // Extract note name
        let (noteName, _) = midiNoteToNoteName(midiNoteNumber)
        return (noteName, cents)
    }

    
    private func midiNoteToNoteName(_ midiNote: Int) -> (note: String, octave: Int) {
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let noteIndex = midiNote % 12
        let octave = (midiNote / 12) - 1
        let noteName = noteNames[noteIndex]
        return (noteName, octave)
    }

}

enum AudioError: Error {
    case microphoneAccess
}
