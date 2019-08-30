import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.11

RowLayout {
  property TimeAccumulator acc
  property string color: "black"

  TimeLabel {
    timestamp: acc.elapsed
    color: parent.color
  }

  ProgressBar {
    from: 0
    value: acc.elapsed
    to: acc.limit

    Layout.fillWidth: true
  }

  TimeLabel {
    timestamp: acc.remaining
    color: parent.color
  }
}
