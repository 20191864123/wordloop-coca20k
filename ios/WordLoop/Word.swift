import Foundation

struct Word: Codable, Identifiable, Hashable {
    let id: Int
    let word: String
    let phonetic: String
    let meaning: String
}
