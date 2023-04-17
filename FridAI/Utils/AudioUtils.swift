//
//  AudioUtils.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/14/23.
//

import AVFoundation
import Foundation

func decodeWavFile(_ url: URL) throws -> [Float] {
    let data = try Data(contentsOf: url)
    let floats = stride(from: 44, to: data.count, by: 2).map {
        data[$0 ..< $0 + 2].withUnsafeBytes {
            let short = Int16(littleEndian: $0.load(as: Int16.self))
            return max(-1.0, min(Float(short) / 32767.0, 1.0))
        }
    }
    return floats
}

func decodeWavFile2(_ url: URL) throws -> [Float] {
    let file = try! AVAudioFile(forReading: url)
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)

    guard let format else {
        return [Float]()
    }
    let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
    try! file.read(into: buf)
    let floats = Array(UnsafeBufferPointer(start: buf.floatChannelData?[0], count: Int(buf.frameLength)))
    return floats
}
