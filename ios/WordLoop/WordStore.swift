import Foundation

@MainActor
final class WordStore: ObservableObject {
    @Published private(set) var words: [Word] = []
    @Published private(set) var knownWordIDs: Set<Int> = []
    @Published var selectedList: Int {
        didSet {
            UserDefaults.standard.set(selectedList, forKey: Keys.selectedList)
        }
    }
    @Published private(set) var loadError: String?

    private enum Keys {
        static let knownWordIDs = "knownWordIDs.v1"
        static let selectedList = "selectedList.v1"
    }

    init() {
        let savedList = UserDefaults.standard.integer(forKey: Keys.selectedList)
        selectedList = (1...20).contains(savedList) ? savedList : 1
        restoreProgress()
        loadWords()
    }

    var currentWords: [Word] {
        let range = idRange(for: selectedList)
        return words.filter { range.contains($0.id) && !knownWordIDs.contains($0.id) }
    }

    var remainingInCurrentList: Int {
        currentWords.count
    }

    var completedInCurrentList: Int {
        1_000 - remainingInCurrentList
    }

    var totalRemaining: Int {
        max(0, 20_000 - knownWordIDs.count)
    }

    func displayNumber(for word: Word) -> Int {
        word.id - ((selectedList - 1) * 1_000)
    }

    func markKnown(_ word: Word) {
        knownWordIDs.insert(word.id)
        persistProgress()
    }

    func restoreCurrentList() {
        knownWordIDs.subtract(idRange(for: selectedList))
        persistProgress()
    }

    func restoreAll() {
        knownWordIDs.removeAll()
        persistProgress()
    }

    private func idRange(for list: Int) -> ClosedRange<Int> {
        let lowerBound = ((list - 1) * 1_000) + 1
        return lowerBound...(lowerBound + 999)
    }

    private func loadWords() {
        guard let url = Bundle.main.url(
            forResource: "coca-20000",
            withExtension: "json"
        ) else {
            loadError = "App 内没有找到 COCA 20,000 词库。"
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedWords = try JSONDecoder().decode([Word].self, from: data)
            guard decodedWords.count == 20_000 else {
                loadError = "词库数量不正确：读取到 \(decodedWords.count) 条。"
                return
            }
            words = decodedWords
        } catch {
            loadError = "词库读取失败：\(error.localizedDescription)"
        }
    }

    private func restoreProgress() {
        let ids = UserDefaults.standard.array(forKey: Keys.knownWordIDs) as? [Int] ?? []
        knownWordIDs = Set(ids)
    }

    private func persistProgress() {
        UserDefaults.standard.set(knownWordIDs.sorted(), forKey: Keys.knownWordIDs)
    }
}
