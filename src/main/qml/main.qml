import QtQuick 2.9
import QtQuick.Window 2.2

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.11

import QtQml.StateMachine 1.11 as DSM

Window {
  title: qsTr("PomoOut")
  visible: true

  width: 580
  height: 600

  color: "gray"

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 10

    Label {
      text: "<b>Timers Settings</b>"

      Layout.alignment: Qt.AlignHCenter
    }

    RowLayout {

      GridLayout {
        columns: 2

        Label { text: "Short Break" }

        SpinBox {
          id: shortBreakSpinBox

          from: 1
          value: 5
          to: 25

          Layout.minimumWidth: 75
          Layout.fillWidth: true

          textFromValue: function(value, locale) {
            return qsTr("%1 m").arg(value);
          }
        }

        Label { text: "Long Break" }

        SpinBox {
          id: longBreakSpinBox

          from: 1
          value: 15
          to: 60

          Layout.minimumWidth: 75
          Layout.fillWidth: true

          textFromValue: function(value, locale) {
            return qsTr("%1 m").arg(value);
          }
        }

        Label { text: "Focus Time" }

        SpinBox {
          id: focusTimeSpinBox

          from: 1
          value: 20
          to: 50

          Layout.minimumWidth: 75
          Layout.fillWidth: true

          editable: true

          textFromValue: function(value, locale) {
            return qsTr("%1 m").arg(value);
          }
        }
      }

      GridLayout {
        columns: 2

        SpinBox {
          id: clockFrequencySpinBox

          from: 1
          value: 1
          to: 1000

          textFromValue: function(value, locale) {
            return qsTr("%1 Hz").arg(value);
          }

          Layout.minimumWidth: 180
        }

        Label { text: "Clock Frequency" }

        SpinBox {
          id: stepsPerTickSpinBox

          from: 1
          value: 1
          to: 60

          textFromValue: function(value, locale) {
            return qsTr("%1 step").arg(value);
          }

          Layout.fillWidth: true
        }

        Label { text: "Steps per Tick" }

        Layout.alignment: Qt.AlignTop
      }
    }

    Label {
      text: "<b>Scheduler Settings</b>"

      Layout.alignment: Qt.AlignHCenter
    }

    GridLayout {
      columns: 2

      Label { text: "Focuses before Long Break" }

      SpinBox {
        id: focusesBeforeLongBreakSpinBox

        from: 1
        value: 2
        to: 10

        Layout.minimumWidth: 160

        textFromValue: function(value, locale) {
          if (value > 1) {
            return qsTr("%1 times").arg(value)
          }

          return qsTr("1 time")
        }
      }

      Label { text: "Planned Cycles" }

      SpinBox {
        id: plannedCyclesSpinBox

        from: 1
        value: 2
        to: 10

        Layout.minimumWidth: 160

        textFromValue: function(value, locale) {
          if (value > 1) {
            return qsTr("%1 cycles").arg(value)
          }

          return qsTr("1 cycle")
        }
      }

    }

    Label {
      text: "<b>Work Time!</b>"

      Layout.alignment: Qt.AlignHCenter
    }

    Item {
      id: focussing

      property int timeLimit: focusTimeSpinBox.value
      property int focusesBeforeLongBreak: focusesBeforeLongBreakSpinBox.value
      property int totalTime: timeLimit * focusesBeforeLongBreak

      property string label: "Focuses"
    }

    Item {
      id: atShortBreak

      property int timeLimit: shortBreakSpinBox.value
      property int totalTime: timeLimit * (focussing.focusesBeforeLongBreak - 1)
      property string label: "Short-breaking"
    }

    Item {
      id: atLongBreak

      property int timeLimit: longBreakSpinBox.value
      property string label: "Long-breaking"
    }

    Item {
      id: cycle

      property int totalTime: (focussing.totalTime + atShortBreak.totalTime + atLongBreak.timeLimit)
    }

    Item {
      id: stateMachine

      signal fullCycleCompleted
      signal focusCompleted

      property int completedFocuses: 0
      property int focusesBeforeLongBreak: focussing.focusesBeforeLongBreak

      property var initialState: focussing
      property var currentState: focussing

      function transistion() {
        currentState = nextState()
      }

      function nextState() {
        switch (currentState) {
          case focussing:
            completedFocuses += 1
            focusCompleted()
            return completedFocuses < focusesBeforeLongBreak ? atShortBreak : atLongBreak;

          case atShortBreak:
            return focussing

          case atLongBreak:
            completedFocuses = 0
            fullCycleCompleted()
            return focussing

          default:
            assert(bogus)
        }
      }

      function reset() {
        currentState = initialState
        completedFocuses = 0
      }
    }

    TimeAccumulator {
      id: totalTime
      limit: cycle.totalTime * plannedCyclesSpinBox.value * 60
      enabled: overflows === 0
    }

    TimeAccumulator {
      id: cycleTime
      limit: cycle.totalTime * 60
      coordinated: totalTime
    }

    TimeAccumulator {
      id: currentStateTime
      limit: stateMachine.currentState.timeLimit * 60
      coordinated: cycleTime
      onOverflow: stateMachine.transistion()
    }

    Timer {
      id: clockSource

      property int step: stepsPerTickSpinBox.value
      property bool active: true

      interval: 1000 / clockFrequencySpinBox.value
      running: active && totalTime.overflows === 0
      repeat: true

      onTriggered: currentStateTime.forward(step)

      function pauseContinue () { active = !active }

      function restartCurrent () { currentStateTime.restart() }

      function resetTimers () { currentStateTime.reset() }
    }

    Timer {
      id: realTime

      running: totalTime.overflows === 0
      interval: 1000
      repeat: true

      property date eta: makeTime()
      onTriggered: update()

      function update() {
        eta = makeTime()
      }

      function makeTime() {
        return new Date((new Date()).getTime() + totalTime.remaining*1000)
      }
    }

    RowLayout {

      Label {
        text: "<b>State:</b> " + stateMachine.currentState.label

        Layout.fillWidth: true
      }

      Label {
        text: "<b>Focuses remaining:</b> " + (stateMachine.focusesBeforeLongBreak - stateMachine.completedFocuses)
      }
    }

    TimeProgressBar {
        acc: currentStateTime
    }

    RowLayout {
      TimeLabel {
        timestamp: cycleTime.limit
        prefix: "<b>Cycle Duration:</b> "

        Layout.fillWidth: true
      }

      Label {
        text: qsTr("<b>Cycles remaining:</b> %1").arg(plannedCyclesSpinBox.value - cycleTime.overflows)
      }
    }

    TimeProgressBar {
        acc: cycleTime
    }

    RowLayout {
      TimeLabel {
        timestamp: totalTime.limit
        prefix: "<b>Workday duration:</b> "

        Layout.fillWidth: true
      }

      Label {
        text: qsTr("<b>ETA:</b> %1").arg(Qt.formatDateTime(realTime.eta, "yyyy/MM/dd HH:mm:ss"))
      }
    }

    TimeProgressBar {
        acc: totalTime
    }

    RowLayout {

      Button {
        text: "Restart current"
        onClicked: currentStateTime.restart()
        enabled: totalTime.overflows === 0
      }

      Button {
        text: clockSource.running ? "Pause" : "Continue"
        onClicked: clockSource.pauseContinue()
        enabled: totalTime.overflows === 0

        Layout.minimumWidth : 100
      }

      Button {
        text: "Reset Timers"

        onClicked: {
          stateMachine.reset()
          currentStateTime.reset()
        }
      }

      Layout.alignment: Qt.AlignHCenter
    }
  }

  Window {
    id: splash

    title: "Stop! Wait a minute..."
    color: "black"

    flags: Qt.Popup

    visible:
        switch (stateMachine.currentState) {
            case atShortBreak:
            case atLongBreak:
                return true;
            default:
                return false;
        }

    width: Screen.width
    height: 100

    x: 0
    y: Screen.height/2

    ColumnLayout {
      anchors.centerIn: parent

      Label {
        text: stateMachine.currentState.label
        color: "white"
      }

      TimeProgressBar {
        acc: currentStateTime
        color: "white"
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: splash.hide()
    }
  }
}
