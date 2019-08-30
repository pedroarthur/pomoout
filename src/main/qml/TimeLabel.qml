import QtQuick 2.0
import QtQuick.Controls 2.0

Label {
  property int timestamp
  property string prefix
  property string suffix

  property string normalized:
        Qt.formatDateTime(new Date(1970, 1, 1, 0, 0, timestamp, 0), "HH:mm:ss")

  text: {
    var formatString = prefix ? "%1%2" : "%1"
    formatString += suffix ? (prefix ? "%3" : "%2") : ""

    var output = qsTr(formatString)
    if (prefix) output = output.arg(prefix)
    output = output.arg(normalized)
    if (suffix) output = output.arg(suffix)

    return output
  }
}
