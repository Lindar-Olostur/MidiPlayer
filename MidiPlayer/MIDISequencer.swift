//
//  MIDISequencer.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 28.11.2025.
//

import AudioKit
import AVFoundation
import AudioToolbox
import Observation

@Observable
class MIDISequencer {
    // AudioKit компоненты
    let engine = AudioEngine()
    let instrument = MIDISampler()
    
    // AudioToolbox для секвенсера (более надёжно)
    private var musicPlayer: MusicPlayer?
    private var musicSequence: MusicSequence?
    private var auGraph: AUGraph?
    
    // Состояние
    var isPlaying: Bool = false
    var currentBeat: Double = 0
    var midiInfo: MIDIFileInfo?
    
    // ABC данные
    var abcTunes: [ABCTune] = []
    var selectedTuneIndex: Int = 0
    
    // Диапазон воспроизведения (в тактах)
    var startMeasure: Int = 1
    var endMeasure: Int = 1
    
    // Настройки
    var tempo: Double = 120 {
        didSet {
            updateTempo()
        }
    }
    var isLooping: Bool = true
    
    // Таймер для отслеживания позиции
    private var positionTimer: Timer?
    
    // Вычисляемые свойства
    var beatsPerMeasure: Int {
        midiInfo?.beatsPerMeasure ?? 4
    }
    
    var startBeat: Double {
        Double((startMeasure - 1) * beatsPerMeasure)
    }
    
    var endBeat: Double {
        Double(endMeasure * beatsPerMeasure)
    }
    
    var totalMeasures: Int {
        midiInfo?.totalMeasures ?? 1
    }
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        engine.output = instrument
        
        do {
            try engine.start()
            print("AudioKit engine started successfully")
        } catch {
            print("Failed to start AudioKit engine: \(error)")
        }
    }
    
    // MARK: - Load MIDI File
    
    func loadMIDIFile(named filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mid") else {
            print("MIDI file not found: \(filename).mid")
            return
        }
        loadMIDIFile(url: url)
    }
    
    func loadMIDIFile(url: URL) {
        // Парсим информацию о MIDI для визуализации
        midiInfo = MIDIParser.parse(url: url)
        
        guard let info = midiInfo else {
            print("Failed to parse MIDI file")
            return
        }
        
        // Загружаем через AudioToolbox
        createSequenceFromMIDIFile(url: url)
        
        // Устанавливаем параметры
        tempo = info.tempo
        startMeasure = 1
        endMeasure = info.totalMeasures
        
        print("MIDI loaded: \(info.allNotes.count) notes, \(info.totalMeasures) measures")
    }
    
    // MARK: - Load ABC File
    
    func loadABCFile(named filename: String) {
        print("Looking for ABC file: \(filename).abc")
        
        // Попробуем найти все .abc файлы в bundle
        if let resourcePath = Bundle.main.resourcePath {
            print("Resource path: \(resourcePath)")
            if let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                let abcFiles = files.filter { $0.hasSuffix(".abc") }
                print("ABC files in bundle: \(abcFiles)")
            }
        }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "abc") else {
            print("ABC file not found: \(filename).abc")
            return
        }
        print("Found ABC file at: \(url.path)")
        loadABCFile(url: url)
    }
    
    func loadABCFile(url: URL) {
        guard let tunes = ABCParser.parseFile(url: url), !tunes.isEmpty else {
            print("Failed to parse ABC file")
            return
        }
        
        abcTunes = tunes
        selectedTuneIndex = 0
        
        loadTune(at: 0)
        
        print("ABC loaded: \(tunes.count) tunes")
    }
    
    func loadTune(at index: Int) {
        guard index >= 0 && index < abcTunes.count else { return }
        
        selectedTuneIndex = index
        let tune = abcTunes[index]
        
        // Конвертируем в MIDIFileInfo
        midiInfo = ABCParser.toMIDIFileInfo(tune)
        
        // Создаём секвенс из нот
        createSequenceFromNotes(tune.notes)
        
        // Устанавливаем параметры
        tempo = 120 // Стандартный темп для рилов, можно настроить
        startMeasure = 1
        endMeasure = midiInfo?.totalMeasures ?? 1
        
        print("Loaded tune: \(tune.title) - \(tune.notes.count) notes")
    }
    
    // MARK: - Create Music Sequence
    
    private func createSequenceFromMIDIFile(url: URL) {
        cleanupSequence()
        
        var sequence: MusicSequence?
        NewMusicSequence(&sequence)
        guard let seq = sequence else { return }
        
        let status = MusicSequenceFileLoad(seq, url as CFURL, .midiType, MusicSequenceLoadFlags())
        guard status == noErr else {
            print("Failed to load MIDI: \(status)")
            return
        }
        
        setupSequence(seq)
    }
    
    private func createSequenceFromNotes(_ notes: [MIDINote]) {
        cleanupSequence()
        
        var sequence: MusicSequence?
        NewMusicSequence(&sequence)
        guard let seq = sequence else { return }
        
        // Создаём трек
        var track: MusicTrack?
        MusicSequenceNewTrack(seq, &track)
        guard let musicTrack = track else { return }
        
        // Добавляем ноты
        for note in notes {
            var noteMessage = MIDINoteMessage(
                channel: note.channel,
                note: note.pitch,
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(note.duration)
            )
            MusicTrackNewMIDINoteEvent(musicTrack, note.startBeat, &noteMessage)
        }
        
        setupSequence(seq)
    }
    
    private func setupSequence(_ sequence: MusicSequence) {
        // Создаём AUGraph для воспроизведения
        var graph: AUGraph?
        NewAUGraph(&graph)
        guard let audioGraph = graph else { return }
        
        // Sampler node
        var samplerNode = AUNode()
        var samplerDesc = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_MIDISynth,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        AUGraphAddNode(audioGraph, &samplerDesc, &samplerNode)
        
        // Output node
        var outputNode = AUNode()
        #if os(iOS)
        let outputSubType = kAudioUnitSubType_RemoteIO
        #else
        let outputSubType = kAudioUnitSubType_DefaultOutput
        #endif
        var outputDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: outputSubType,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        AUGraphAddNode(audioGraph, &outputDesc, &outputNode)
        
        AUGraphOpen(audioGraph)
        AUGraphConnectNodeInput(audioGraph, samplerNode, 0, outputNode, 0)
        AUGraphInitialize(audioGraph)
        AUGraphStart(audioGraph)
        
        // Привязываем к секвенсу
        MusicSequenceSetAUGraph(sequence, audioGraph)
        
        self.musicSequence = sequence
        self.auGraph = audioGraph
        
        // Создаём плеер
        var player: MusicPlayer?
        NewMusicPlayer(&player)
        guard let pl = player else { return }
        
        MusicPlayerSetSequence(pl, sequence)
        MusicPlayerPreroll(pl)
        
        self.musicPlayer = pl
        
        // Устанавливаем темп
        updateTempo()
    }
    
    private func cleanupSequence() {
        if let player = musicPlayer {
            MusicPlayerStop(player)
            DisposeMusicPlayer(player)
            musicPlayer = nil
        }
        
        if let graph = auGraph {
            AUGraphStop(graph)
            DisposeAUGraph(graph)
            auGraph = nil
        }
        
        if let sequence = musicSequence {
            DisposeMusicSequence(sequence)
            musicSequence = nil
        }
    }
    
    private func updateTempo() {
        guard let sequence = musicSequence else { return }
        
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        
        if let track = tempoTrack {
            // Очищаем старые события темпа
            MusicTrackClear(track, 0, 0.001)
            
            // Добавляем новый темп (функция принимает Float64 напрямую)
            MusicTrackNewExtendedTempoEvent(track, 0, tempo)
        }
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard let player = musicPlayer else { return }
        
        MusicPlayerSetTime(player, startBeat)
        currentBeat = startBeat
        
        MusicPlayerStart(player)
        isPlaying = true
        startPositionTimer()
    }
    
    func pause() {
        guard let player = musicPlayer else { return }
        MusicPlayerStop(player)
        isPlaying = false
        stopPositionTimer()
    }
    
    func stop() {
        guard let player = musicPlayer else { return }
        MusicPlayerStop(player)
        MusicPlayerSetTime(player, startBeat)
        currentBeat = startBeat
        isPlaying = false
        stopPositionTimer()
    }
    
    func rewind() {
        guard let player = musicPlayer else { return }
        MusicPlayerSetTime(player, startBeat)
        currentBeat = startBeat
    }
    
    func setPosition(_ beat: Double) {
        guard let player = musicPlayer else { return }
        let clampedBeat = max(startBeat, min(beat, endBeat))
        MusicPlayerSetTime(player, clampedBeat)
        currentBeat = clampedBeat
    }
    
    // MARK: - Position Timer
    
    private func startPositionTimer() {
        stopPositionTimer()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
    }
    
    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }
    
    private func updatePosition() {
        guard let player = musicPlayer, isPlaying else { return }
        
        var time: MusicTimeStamp = 0
        MusicPlayerGetTime(player, &time)
        currentBeat = time
        
        // Проверяем конец диапазона
        if currentBeat >= endBeat {
            if isLooping {
                MusicPlayerSetTime(player, startBeat)
                currentBeat = startBeat
            } else {
                stop()
            }
        }
    }
    
    deinit {
        stopPositionTimer()
        cleanupSequence()
        engine.stop()
    }
}
