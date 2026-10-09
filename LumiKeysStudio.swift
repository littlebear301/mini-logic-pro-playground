import SwiftUI
import AVFoundation

// MARK: - Audio Synth Engine
final class LumiSynth: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    @Published var isPlaying = false

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        do {
            try engine.start()
        } catch {
            print("Audio engine failed: \(error)")
        }
    }

    func playNote(frequency: Double, duration: Double = 0.3) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (t / duration) // fade out
            let wave = sin(2 * Double.pi * frequency * t) * envelope
            channel[i] = Float(wave * 0.2)
        }

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
}

// MARK: - Note Data
struct NoteInfo {
    let name: String
    let frequency: Double
    let octave: Int
    let isBlackKey: Bool
}

// MARK: - Generate all 88 keys (A0 to C8)
func generateLumiKeys() -> [NoteInfo] {
    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let blackKeyIndices = [1, 3, 6, 8, 10] // C#, D#, F#, G#, A#
    
    var keys: [NoteInfo] = []
    var frequency = 27.5 // A0
    
    // Start from C-1 to get to A0
    let semitoneRatio = pow(2.0, 1.0 / 12.0)
    var currentFreq = 27.5
    
    // Generate 88 keys
    for i in 0..<88 {
        let noteIndex = i % 12
        let octave = (i / 12) - 1 + 1 // Adjust octave labeling
        let noteName = noteNames[noteIndex]
        let isBlack = blackKeyIndices.contains(noteIndex)
        
        keys.append(NoteInfo(name: noteName, frequency: currentFreq, octave: octave, isBlackKey: isBlack))
        currentFreq *= semitoneRatio
    }
    
    return keys
}

// MARK: - Piano Key View
struct PianoKeyView: View {
    let note: NoteInfo
    let synth: LumiSynth
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            synth.playNote(frequency: note.frequency)
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            VStack(spacing: 2) {
                Text(note.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                if note.octave >= 0 {
                    Text("\(note.octave)")
                        .font(.system(size: 8))
                }
            }
            .foregroundColor(note.isBlackKey ? .white : .black)
            .frame(width: note.isBlackKey ? 35 : 50, height: note.isBlackKey ? 120 : 180)
            .background(note.isBlackKey ? Color.black : Color.white)
            .border(Color.gray.opacity(0.5))
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
    }
}

// MARK: - Main Lumi Keys Studio View
struct LumiKeysStudioView: View {
    @StateObject private var synth = LumiSynth()
    @State private var showingHelp = false
    
    let lumiKeys = generateLumiKeys()
    
    var whiteKeys: [NoteInfo] {
        lumiKeys.filter { !$0.isBlackKey }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("🎹 Lumi Keys Studio Edition")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Text("88 Full-Size Keys")
                        .font(.caption)
                    Spacer()
                    Button(action: { showingHelp.toggle() }) {
                        Text("?")
                            .font(.headline)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            
            // Piano Keyboard
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .bottomLeading) {
                    // White keys background
                    HStack(spacing: 0) {
                        ForEach(whiteKeys, id: \.name) { key in
                            PianoKeyView(note: key, synth: synth)
                                .frame(maxWidth: 50)
                        }
                    }
                    
                    // Black keys overlay
                    HStack(spacing: 0) {
                        ForEach(lumiKeys, id: \.name) { key in
                            if key.isBlackKey {
                                PianoKeyView(note: key, synth: synth)
                                    .offset(x: 25, y: 60)
                            } else {
                                Spacer()
                                    .frame(width: 50)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
            
            // Control Panel
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Label("Record", systemImage: "circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        Label("Play", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        Label("Add Track", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Text("Octave -")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        Text("Octave +")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
        }
        .background(Color.black)
        .alert("Lumi Keys Studio", isPresented: $showingHelp) {
            Button("OK") { }
        } message: {
            Text("Click any key to play a note. Use Octave buttons to shift the keyboard range. Full 88-key layout like a professional piano!")
        }
    }
}

#Preview {
    LumiKeysStudioView()
        .preferredColorScheme(.dark)
}
