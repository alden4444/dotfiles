import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string date: Qt.formatDateTime(clock.date, "ddd, d MMM")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}