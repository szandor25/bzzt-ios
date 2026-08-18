import SwiftUI

extension BZZTBackendPublicState {
    var room: BZZTRoom {
        BZZTRoom(code: roomCode, title: "BZZT! PARTY", settings: BZZTRoomSettings())
    }

    var bzztPlayers: [BZZTPlayer] {
        players.map { $0.bzztPlayer }
    }
}

extension BZZTBackendPlayer {
    var bzztPlayer: BZZTPlayer {
        BZZTPlayer(
            id: stableID(from: sessionID),
            name: nickname,
            avatar: avatar,
            score: score,
            isHost: isHost,
            isReady: ready
        )
    }
}

extension BZZTBackendRankingPlayer {
    var bzztPlayer: BZZTPlayer {
        BZZTPlayer(
            id: stableID(from: sessionID),
            name: nickname,
            avatar: avatar,
            score: score,
            isHost: false,
            isReady: true
        )
    }
}

extension BZZTBackendQuestion {
    func bzztQuestion(index: Int, total: Int, baseURL: URL) -> BZZTQuestion {
        BZZTQuestion(
            id: id,
            index: index,
            total: total,
            category: "BZZT!",
            text: text,
            options: answers.enumerated().map { offset, answer in
                BZZTAnswerOption(
                    id: answer.id,
                    letter: answer.label,
                    text: answer.text,
                    color: answerColor(for: offset)
                )
            },
            correctAnswerID: nil,
            timeLimit: timeLimit,
            explanation: "",
            audioURL: absoluteURL(from: audioURLPath, baseURL: baseURL),
            explanationAudioURL: nil
        )
    }

    private func answerColor(for index: Int) -> Color {
        switch index {
        case 0:
            Color(red: 1.0, green: 0.302, blue: 0.369)
        case 1:
            Color(red: 0.239, green: 0.482, blue: 1.0)
        case 2:
            Color(red: 1.0, green: 0.788, blue: 0.239)
        default:
            Color(red: 0.196, green: 0.835, blue: 0.514)
        }
    }
}

func absoluteURL(from path: String?, baseURL: URL) -> URL? {
    guard let path, !path.isEmpty else { return nil }
    if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
        return absoluteURL
    }

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
        return nil
    }
    components.path = path.hasPrefix("/") ? path : "/\(path)"
    components.query = nil
    return components.url
}

private func stableID(from string: String) -> UUID {
    let bytes = Array(string.utf8)
    var uuidBytes = Array(repeating: UInt8(0), count: 16)
    for (index, byte) in bytes.enumerated() {
        uuidBytes[index % 16] = uuidBytes[index % 16] &+ byte &+ UInt8(index & 0xFF)
    }

    return UUID(uuid: (
        uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
        uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
        uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
        uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
    ))
}
