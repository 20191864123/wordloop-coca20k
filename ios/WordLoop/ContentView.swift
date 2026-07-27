import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WordStore
    @State private var resetTarget: ResetTarget?
    @State private var isShowingResetConfirmation = false

    private enum ResetTarget {
        case currentList
        case all
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                listPicker
                progressHeader

                if let error = store.loadError {
                    statusView(
                        title: "词库无法读取",
                        message: error,
                        systemImage: "exclamationmark.triangle"
                    )
                } else if store.currentWords.isEmpty {
                    completedView
                } else {
                    wordList
                }
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.91))
            .navigationTitle("COCA 20K")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    resetMenu
                }
            }
            .confirmationDialog(
                resetTitle,
                isPresented: $isShowingResetConfirmation,
                titleVisibility: .visible
            ) {
                switch resetTarget {
                case .currentList:
                    Button("恢复 List \(store.selectedList) 的 1,000 个词", role: .destructive) {
                        store.restoreCurrentList()
                    }
                case .all:
                    Button("恢复全部 20,000 个词", role: .destructive) {
                        store.restoreAll()
                    }
                case nil:
                    EmptyView()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这会把已删除的单词重新放回列表。")
            }
        }
    }

    private var listPicker: some View {
        HStack(spacing: 12) {
            Button {
                if store.selectedList > 1 {
                    store.selectedList -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 34, height: 34)
            }
            .disabled(store.selectedList == 1)

            Picker("选择单词组", selection: $store.selectedList) {
                ForEach(1...20, id: \.self) { list in
                    Text("List \(list)").tag(list)
                }
            }
            .pickerStyle(.menu)
            .font(.title3.weight(.semibold))
            .tint(.primary)
            .frame(maxWidth: .infinity)

            Button {
                if store.selectedList < 20 {
                    store.selectedList += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 34, height: 34)
            }
            .disabled(store.selectedList == 20)
        }
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var progressHeader: some View {
        VStack(spacing: 7) {
            HStack {
                Text("剩余 \(store.remainingInCurrentList)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("已删除 \(store.completedInCurrentList) / 1,000")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(store.completedInCurrentList), total: 1_000)
                .tint(Color(red: 0.12, green: 0.42, blue: 0.29))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.82))
    }

    private var wordList: some View {
        List {
            ForEach(store.currentWords) { word in
                WordRow(
                    number: store.displayNumber(for: word),
                    word: word
                ) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.markKnown(word)
                    }
                }
                .listRowInsets(
                    EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 10)
                )
                .listRowBackground(Color.white)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        store.markKnown(word)
                    } label: {
                        Label("认识，删除", systemImage: "checkmark")
                    }
                    .tint(Color(red: 0.12, green: 0.42, blue: 0.29))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var completedView: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color(red: 0.12, green: 0.42, blue: 0.29))

            Text("List \(store.selectedList) 已完成")
                .font(.title2.weight(.bold))

            Text("这一组的 1,000 个词已经全部删除。可以进入下一组，或从右上角恢复本组。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if store.selectedList < 20 {
                Button("进入 List \(store.selectedList + 1)") {
                    store.selectedList += 1
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.12, green: 0.42, blue: 0.29))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statusView(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(title)
                .font(.title2.weight(.bold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resetMenu: some View {
        Menu {
            Button {
                resetTarget = .currentList
                isShowingResetConfirmation = true
            } label: {
                Label("恢复当前 List", systemImage: "arrow.uturn.backward")
            }

            Button {
                resetTarget = .all
                isShowingResetConfirmation = true
            } label: {
                Label("恢复全部 20,000 词", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var resetTitle: String {
        switch resetTarget {
        case .currentList:
            return "恢复当前 List？"
        case .all:
            return "恢复全部词汇？"
        case nil:
            return ""
        }
    }
}

private struct WordRow: View {
    let number: Int
    let word: Word
    let onKnown: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(number)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                Text(word.word)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                if !word.phonetic.isEmpty {
                    Text("[\(word.phonetic)]")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, alignment: .leading)

            Text(word.meaning)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onKnown) {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.12, green: 0.42, blue: 0.29))
                    .padding(5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("认识，删除 \(word.word)")
        }
        .contentShape(Rectangle())
    }
}
