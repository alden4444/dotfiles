import QtQuick
import Quickshell
import "../../components"

// Minute-precision clock. SystemClock only ticks as often as `precision` asks for.
StyledText {
    id: root

    text: Qt.formatDateTime(clock.date, "ddd, MMM d HH:mm")
    font.features: { "tnum": 1 }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
