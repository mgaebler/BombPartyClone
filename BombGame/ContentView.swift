import SwiftUI
import AVFoundation
import CoreHaptics

enum GameState {
    case idle
    case active
    case finished
}

class HapticManager {
    private var engine: CHHapticEngine?

    init() {
        prepareHaptics()
    }

    private func prepareHaptics() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    func playExplosionHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var events = [CHHapticEvent]()

        // Create a strong, continuous haptic event
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 1.0)
        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}

class SoundPlayer {
    var player: AVAudioPlayer?

    func playSound(sound: String, type: String) {
        if let path = Bundle.main.path(forResource: sound, ofType: type) {
            do {
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                player?.play()
            } catch {
                print("Could not find and play the sound file.")
            }
        }
    }
    
    func stopSound() {
        player?.stop()
        player = nil
    }
}


struct ContentView: View {
    @State private var gameState: GameState = .idle

    var body: some View {
        VStack {
            switch gameState {
            case .idle:
                StartScreen(gameState: $gameState)
            case .active:
                ActionScreen(gameState: $gameState)
            case .finished:
                EndScreen(gameState: $gameState)
            }
        }
    }
}

struct StartScreen: View {
    @Binding var gameState: GameState

    var body: some View {
        VStack {
            Image(systemName: "flame.fill") // Replace with your explosion image
                .resizable()
                .frame(width: 100, height: 100)
                .padding()
            Text("Tick Tack Boom")
                .font(.largeTitle)
                .padding()

            Button(action: {
                gameState = .active
            }) {
                Text("Start Game")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
        }
    }
}

struct ActionScreen: View {
    @Binding var gameState: GameState
    @State private var timerValue: Int = 0
    @State private var targetTime: Int = Int.random(in: 20...45)
//    @State private var targetTime: Int = 3
    @State private var timer: Timer?
    @State private var bounce = false
    @State private var animateBackground = false
//    let bgSound = SoundPlayer()
    let tickSound = SoundPlayer()

    var body: some View {
        VStack {
            Image(systemName: "flame.fill") // Replace with your bomb image
                .resizable()
                .frame(width: 200, height: 200)
                .padding()
                .offset(y: bounce ? -10 : 10)
                .animation(
                    Animation
                        .easeInOut(duration: 0.25)
                        .repeatForever(autoreverses: true),
                    value: bounce
                )
                .onAppear {
                    bounce.toggle()
                }

//            Text("\(timerValue)")
//                .font(.largeTitle)
//                .padding()
        }
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        .background(animateBackground ? Color.red : Color.blue)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            startTimer()
            withAnimation(Animation.easeInOut(duration: 1)
                .repeatForever(autoreverses: true)) {
                    animateBackground.toggle()
                }
//            bgSound.playSound(sound: "bg_sound", type: "mp3")
            tickSound.playSound(sound: "watch", type: "mp3")
        }
        .onDisappear {
            timer?.invalidate()
//            bgSound.stopSound()
            
        }
    }

    func startTimer() {
        timerValue = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.timerValue < self.targetTime {
                self.timerValue += 1
            } else {
                self.gameState = .finished
                tickSound.stopSound()
                timer.invalidate()
            }
        }
    }
}

struct EndScreen: View {
    @Binding var gameState: GameState
    let soundPlayer = SoundPlayer()
    let hapticManager = HapticManager()

    var body: some View {
        VStack {
            Text("Boom!")
                .font(.largeTitle)
                .padding()

            Image(systemName: "flame.fill") // Replace with your explosion image
                .resizable()
                .frame(width: 200, height: 200)
                .padding()
                .onAppear {
                    performExplosionAnimation()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.red)
    }

    func performExplosionAnimation() {
        // Trigger vibration
        hapticManager.playExplosionHaptic()
        soundPlayer.playSound(sound: "blast", type: "mp3")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // back to title screen
            self.gameState = .idle
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
