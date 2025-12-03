//
//  MIDIParser.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 28.11.2025.
//

import Foundation
import AudioToolbox

// MARK: - Модели данных

struct MIDINote: Identifiable, Equatable {
    let id = UUID()
    let pitch: UInt8          // MIDI номер ноты (0-127)
    let velocity: UInt8       // Громкость (0-127)
    let startBeat: Double     // Начало в битах
    let duration: Double      // Длительность в битах
    let channel: UInt8        // MIDI канал
    
    var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = Int(pitch) % 12
        return "\(noteNames[note])\(octave)"
    }
    
    var endBeat: Double {
        startBeat + duration
    }
}

struct MIDITrackInfo {
    let notes: [MIDINote]
    let minPitch: UInt8
    let maxPitch: UInt8
    let totalBeats: Double
}

struct MIDIFileInfo {
    let tracks: [MIDITrackInfo]
    let allNotes: [MIDINote]
    let totalBeats: Double
    let beatsPerMeasure: Int      // Обычно 4
    let totalMeasures: Int
    let tempo: Double             // BPM
    let minPitch: UInt8
    let maxPitch: UInt8
    
    var measureCount: Int {
        Int(ceil(totalBeats / Double(beatsPerMeasure)))
    }
}

// MARK: - MIDI Parser

class MIDIParser {
    
    static func parse(url: URL, beatsPerMeasure: Int = 4) -> MIDIFileInfo? {
        var musicSequence: MusicSequence?
        var status = NewMusicSequence(&musicSequence)
        
        guard status == noErr, let sequence = musicSequence else {
            print("Failed to create MusicSequence")
            return nil
        }
        
        status = MusicSequenceFileLoad(sequence, url as CFURL, .midiType, MusicSequenceLoadFlags())
        
        guard status == noErr else {
            print("Failed to load MIDI file: \(status)")
            return nil
        }
        
        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)
        
        var allNotes: [MIDINote] = []
        var tracks: [MIDITrackInfo] = []
        var totalBeats: Double = 0
        var tempo: Double = 120.0
        
        // Получаем темп из темпо-трека
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        if let tempoTrack = tempoTrack {
            tempo = extractTempo(from: tempoTrack) ?? 120.0
        }
        
        for i in 0..<trackCount {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequence, i, &track)
            
            guard let musicTrack = track else { continue }
            
            let notes = extractNotes(from: musicTrack)
            
            if !notes.isEmpty {
                let minPitch = notes.map { $0.pitch }.min() ?? 0
                let maxPitch = notes.map { $0.pitch }.max() ?? 127
                let trackEnd = notes.map { $0.endBeat }.max() ?? 0
                
                tracks.append(MIDITrackInfo(
                    notes: notes,
                    minPitch: minPitch,
                    maxPitch: maxPitch,
                    totalBeats: trackEnd
                ))
                
                allNotes.append(contentsOf: notes)
                totalBeats = max(totalBeats, trackEnd)
            }
        }
        
        // Сортируем по времени начала
        allNotes.sort { $0.startBeat < $1.startBeat }
        
        let minPitch = allNotes.map { $0.pitch }.min() ?? 0
        let maxPitch = allNotes.map { $0.pitch }.max() ?? 127
        let totalMeasures = Int(ceil(totalBeats / Double(beatsPerMeasure)))
        
        DisposeMusicSequence(sequence)
        
        return MIDIFileInfo(
            tracks: tracks,
            allNotes: allNotes,
            totalBeats: totalBeats,
            beatsPerMeasure: beatsPerMeasure,
            totalMeasures: totalMeasures,
            tempo: tempo,
            minPitch: minPitch,
            maxPitch: maxPitch
        )
    }
    
    private static func extractNotes(from track: MusicTrack) -> [MIDINote] {
        var notes: [MIDINote] = []
        var iterator: MusicEventIterator?
        NewMusicEventIterator(track, &iterator)
        
        guard let eventIterator = iterator else { return notes }
        
        var hasNext: DarwinBoolean = true
        
        while hasNext.boolValue {
            var timestamp: MusicTimeStamp = 0
            var eventType: MusicEventType = 0
            var eventData: UnsafeRawPointer?
            var eventDataSize: UInt32 = 0
            
            MusicEventIteratorGetEventInfo(eventIterator, &timestamp, &eventType, &eventData, &eventDataSize)
            
            if eventType == kMusicEventType_MIDINoteMessage {
                let noteMessage = eventData!.assumingMemoryBound(to: MIDINoteMessage.self).pointee
                
                let note = MIDINote(
                    pitch: noteMessage.note,
                    velocity: noteMessage.velocity,
                    startBeat: timestamp,
                    duration: Double(noteMessage.duration),
                    channel: noteMessage.channel
                )
                notes.append(note)
            }
            
            MusicEventIteratorNextEvent(eventIterator)
            MusicEventIteratorHasCurrentEvent(eventIterator, &hasNext)
        }
        
        DisposeMusicEventIterator(eventIterator)
        return notes
    }
    
    private static func extractTempo(from track: MusicTrack) -> Double? {
        var iterator: MusicEventIterator?
        NewMusicEventIterator(track, &iterator)
        
        guard let eventIterator = iterator else { return nil }
        
        var hasNext: DarwinBoolean = true
        var tempo: Double?
        
        while hasNext.boolValue {
            var timestamp: MusicTimeStamp = 0
            var eventType: MusicEventType = 0
            var eventData: UnsafeRawPointer?
            var eventDataSize: UInt32 = 0
            
            MusicEventIteratorGetEventInfo(eventIterator, &timestamp, &eventType, &eventData, &eventDataSize)
            
            if eventType == kMusicEventType_ExtendedTempo {
                let tempoEvent = eventData!.assumingMemoryBound(to: ExtendedTempoEvent.self).pointee
                tempo = tempoEvent.bpm
                break
            }
            
            MusicEventIteratorNextEvent(eventIterator)
            MusicEventIteratorHasCurrentEvent(eventIterator, &hasNext)
        }
        
        DisposeMusicEventIterator(eventIterator)
        return tempo
    }
}


