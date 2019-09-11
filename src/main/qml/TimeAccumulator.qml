import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.11

import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    property int limit
    property int elapsed: 0
    property int remaining: limit - elapsed
    property int overflows: 0
    property bool enabled: true

    property var coordinated: Item {
      id: nullObject

      function forward(step) { return true }
      function backward(step) { return true }
      function reset() { return true }
      function restart() { return true }
    }

    signal overflow

    function forward(step) {
        if (!enabled)
          return false

        var was_overflow = (elapsed + step) >= limit;
        var commited_step = Math.min(step, limit - elapsed)
        var remaining_step = step - commited_step

        if (!coordinated.forward(commited_step)) {
          return false
        }

        elapsed += commited_step

        if (was_overflow) {
            overflows += 1
            overflow()
            elapsed = 0
        }

        if (remaining_step) {
          return forward(remaining_step)
        }

        return true
    }

    function next() {
      forward(remaining)
    }

    function backward(step) {
        elapsed -= step
        coordinated.backward(step)
    }

    function restart() {
        backward(elapsed)
    }

    function reset() {
        elapsed = 0
        overflows = 0
        coordinated.reset()
    }
}
