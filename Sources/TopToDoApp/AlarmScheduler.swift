import AppKit
import Combine
import Foundation
import TopToDoCore

@MainActor
final class AlarmScheduler: ObservableObject {
    @Published var presentedAlarm: AlarmPresentation?

    private let store: TodoStore
    private var timers: [UUID: Timer] = [:]
    private var queuedAlarms: [AlarmPresentation] = []
    private var cancellables: Set<AnyCancellable> = []
    private let reminderSound = NSSound(named: NSSound.Name("Glass"))

    init(store: TodoStore) {
        self.store = store

        Publishers.CombineLatest(store.$todayItems, store.$taskPoolItems)
            .sink { [weak self] todayItems, taskPoolItems in
                self?.reschedule(for: todayItems + taskPoolItems)
            }
            .store(in: &cancellables)

        reschedule(for: store.todayItems + store.taskPoolItems)
    }

    func dismissPresentedAlarm() {
        presentedAlarm = nil
        presentNextAlarmIfNeeded()
    }

    private func reschedule(for items: [TodoItem]) {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()

        for item in items {
            guard let alarmAt = item.alarmAt else {
                continue
            }

            if alarmAt <= Date() {
                triggerAlarm(for: item)
                continue
            }

            let timer = Timer(fireAt: alarmAt, interval: 0, target: self, selector: #selector(handleTimer(_:)), userInfo: item.id, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            timers[item.id] = timer
        }
    }

    @objc private func handleTimer(_ timer: Timer) {
        guard let itemID = timer.userInfo as? UUID else {
            return
        }

        timers[itemID]?.invalidate()
        timers[itemID] = nil

        if let item = store.todayItems.first(where: { $0.id == itemID }) ?? store.taskPoolItems.first(where: { $0.id == itemID }) {
            triggerAlarm(for: item)
        }
    }

    private func triggerAlarm(for item: TodoItem) {
        clearAlarm(for: item.id)
        playReminderSound()

        let presentation = AlarmPresentation(taskID: item.id, taskTitle: item.title.trimmingCharacters(in: .whitespacesAndNewlines))
        if presentedAlarm == nil {
            presentedAlarm = presentation
        } else if !queuedAlarms.contains(presentation) {
            queuedAlarms.append(presentation)
        }
    }

    private func presentNextAlarmIfNeeded() {
        guard presentedAlarm == nil, !queuedAlarms.isEmpty else {
            return
        }

        presentedAlarm = queuedAlarms.removeFirst()
    }

    private func clearAlarm(for id: UUID) {
        if store.todayItems.contains(where: { $0.id == id }) {
            store.clearTodayAlarm(id: id)
        } else {
            store.clearTaskPoolAlarm(id: id)
        }
    }

    private func playReminderSound() {
        if reminderSound?.isPlaying == true {
            reminderSound?.stop()
        }

        if reminderSound?.play() != true {
            NSSound.beep()
        }
    }
}

struct AlarmPresentation: Identifiable, Equatable {
    let taskID: UUID
    let taskTitle: String

    var id: UUID {
        taskID
    }
}
