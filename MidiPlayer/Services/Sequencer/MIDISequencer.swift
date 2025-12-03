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
    
    // Оригинальные данные MIDI (без транспонирования)
    private var originalMIDIInfo: MIDIFileInfo?
    private var originalMIDIURL: URL?

    // Публичный доступ к оригинальным данным
    var originalTuneInfo: MIDIFileInfo? {
        return originalMIDIInfo
    }
    
    // ABC данные //TODO брать только первый
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
    
    // Транспонирование (в полутонах, -12 до +12)
    var transpose: Int = 0 {
        didSet {
            // Перезагружаем текущий трек с новым транспонированием
            if !abcTunes.isEmpty {
                reloadCurrentTune()
            } else if let originalInfo = originalMIDIInfo, let url = originalMIDIURL {
                // Для MIDI файлов пересоздаём с транспонированием
                reloadMIDIFile(originalInfo: originalInfo, url: url)
            }
        }
    }
    
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
        setupAudioSession()
        setupAudio()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Категория .playback позволяет воспроизводить звук даже в режиме "Без звука"
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            
            print("AVAudioSession configured successfully")
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
        #endif
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
        // Очищаем ABC данные при загрузке MIDI
        abcTunes = []
        selectedTuneIndex = 0
        
        // Парсим информацию о MIDI для визуализации
        guard let originalInfo = MIDIParser.parse(url: url) else {
            print("Failed to parse MIDI file")
            return
        }
        
        // Сохраняем оригинальные данные
        originalMIDIInfo = originalInfo
        originalMIDIURL = url
        
        // Применяем транспонирование
        reloadMIDIFile(originalInfo: originalInfo, url: url)
    }
    
    private func reloadMIDIFile(originalInfo: MIDIFileInfo, url: URL) {
        let wasPlaying = isPlaying
        let currentPos = currentBeat
        
        // Сохраняем выделенную область
        let savedStartMeasure = startMeasure
        let savedEndMeasure = endMeasure
        
        if wasPlaying {
            pause()
        }
        
        // Применяем транспонирование к нотам для отображения
        let transposedNotes = originalInfo.allNotes.map { note in
            MIDINote(
                pitch: UInt8(max(0, min(127, Int(note.pitch) + transpose))),
                velocity: note.velocity,
                startBeat: note.startBeat,
                duration: note.duration,
                channel: note.channel
            )
        }
        
        // Обновляем midiInfo с транспонированными нотами
        let minPitch = transposedNotes.map { $0.pitch }.min() ?? originalInfo.minPitch
        let maxPitch = transposedNotes.map { $0.pitch }.max() ?? originalInfo.maxPitch
        
        let trackInfo = MIDITrackInfo(
            notes: transposedNotes,
            minPitch: minPitch,
            maxPitch: maxPitch,
            totalBeats: originalInfo.totalBeats
        )
        
        midiInfo = MIDIFileInfo(
            tracks: [trackInfo],
            allNotes: transposedNotes,
            totalBeats: originalInfo.totalBeats,
            beatsPerMeasure: originalInfo.beatsPerMeasure,
            totalMeasures: originalInfo.totalMeasures,
            tempo: originalInfo.tempo,
            minPitch: minPitch,
            maxPitch: maxPitch
        )
        
        // Создаём секвенс с транспонированными нотами
        createSequenceFromNotes(transposedNotes)
        
        // Устанавливаем параметры
        tempo = originalInfo.tempo
        
        // Восстанавливаем выделенную область
        startMeasure = min(savedStartMeasure, originalInfo.totalMeasures)
        endMeasure = min(savedEndMeasure, originalInfo.totalMeasures)
        
        // Восстанавливаем позицию
        if currentPos > 0 {
            setPosition(min(currentPos, endBeat))
        }
        
        if wasPlaying {
            play()
        }
        
        print("MIDI reloaded with transpose \(transpose): \(transposedNotes.count) notes")
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
        // Очищаем MIDI данные при загрузке ABC
        originalMIDIInfo = nil
        originalMIDIURL = nil
        midiInfo = nil
        
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

        // Сохраняем оригинальные данные (без транспонирования) для определения тональности
        let originalMIDIInfo = ABCParser.toMIDIFileInfo(tune, transpose: 0)
        self.originalMIDIInfo = originalMIDIInfo
        self.originalMIDIURL = nil // Для ABC файлов URL не нужен

        // Конвертируем в MIDIFileInfo (с учётом транспонирования для отображения)
        midiInfo = ABCParser.toMIDIFileInfo(tune, transpose: transpose)

        // Создаём секвенс из нот
        createSequenceFromNotes(tune.notes)

        // Устанавливаем параметры
        tempo = 120 // Стандартный темп для рилов, можно настроить
        startMeasure = 1
        endMeasure = midiInfo?.totalMeasures ?? 1

        print("Loaded tune: \(tune.title) - \(tune.notes.count) notes, transpose: \(transpose)")
    }
    
    /// Перезагружает текущую мелодию (при смене транспонирования)
    private func reloadCurrentTune() {
        let wasPlaying = isPlaying
        let currentPos = currentBeat
        
        // Сохраняем выделенную область
        let savedStartMeasure = startMeasure
        let savedEndMeasure = endMeasure
        
        if wasPlaying {
            pause()
        }
        
        if !abcTunes.isEmpty {
            loadTune(at: selectedTuneIndex)
        }
        
        // Восстанавливаем выделенную область
        startMeasure = min(savedStartMeasure, totalMeasures)
        endMeasure = min(savedEndMeasure, totalMeasures)
        
        // Восстанавливаем позицию
        if currentPos > 0 {
            setPosition(min(currentPos, endBeat))
        }
        
        if wasPlaying {
            play()
        }
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
        
        // Добавляем ноты с транспонированием
        for note in notes {
            // Применяем транспонирование
            let transposedPitch = max(0, min(127, Int(note.pitch) + transpose))
            
            var noteMessage = MIDINoteMessage(
                channel: note.channel,
                note: UInt8(transposedPitch),
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(note.duration)
            )
            MusicTrackNewMIDINoteEvent(musicTrack, note.startBeat, &noteMessage)
        }
        
        setupSequence(seq)
    }
    
    private func setupSequence(_ sequence: MusicSequence) {
        // Убедимся что аудио сессия активна
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        // Создаём AUGraph для воспроизведения
        var graph: AUGraph?
        var status = NewAUGraph(&graph)
        guard status == noErr, let audioGraph = graph else {
            print("Failed to create AUGraph: \(status)")
            return
        }
        
        // Sampler node - используем Sampler (работает на iOS)
        var samplerNode = AUNode()
        var samplerDesc = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_Sampler,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        status = AUGraphAddNode(audioGraph, &samplerDesc, &samplerNode)
        if status != noErr {
            print("Failed to add sampler node: \(status)")
        }
        
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
        status = AUGraphAddNode(audioGraph, &outputDesc, &outputNode)
        if status != noErr {
            print("Failed to add output node: \(status)")
        }
        
        status = AUGraphOpen(audioGraph)
        if status != noErr {
            print("Failed to open AUGraph: \(status)")
        }
        
        status = AUGraphConnectNodeInput(audioGraph, samplerNode, 0, outputNode, 0)
        if status != noErr {
            print("Failed to connect nodes: \(status)")
        }
        
        status = AUGraphInitialize(audioGraph)
        if status != noErr {
            print("Failed to initialize AUGraph: \(status)")
        }
        
        status = AUGraphStart(audioGraph)
        if status != noErr {
            print("Failed to start AUGraph: \(status)")
        }
        
        // Привязываем к секвенсу
        status = MusicSequenceSetAUGraph(sequence, audioGraph)
        if status != noErr {
            print("Failed to set AUGraph to sequence: \(status)")
        }
        
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
        
        // Если текущая позиция за пределами диапазона или в самом конце - начинаем сначала
        if currentBeat < startBeat || currentBeat >= endBeat {
            MusicPlayerSetTime(player, startBeat)
            currentBeat = startBeat
        } else {
            // Продолжаем с текущей позиции
            MusicPlayerSetTime(player, currentBeat)
        }
        
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
