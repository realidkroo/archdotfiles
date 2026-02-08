import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "macClock"
    visibleWhenLocked: Config.options.background.widgets.macClock.showOnLockScreen

    implicitHeight: clockText.implicitHeight
    implicitWidth: clockText.implicitWidth

    StyledDropShadow {
        target: clockText
    }

    StyledText {
        id: clockText
        text: DateTime.time
        color: root.colText
        font {
                pixelSize: 100
                family: Appearance.font.family.expressive
                weight: Font.Bold
        }
        style: Text.Raised
        styleColor: ColorUtils.transparentize(Appearance.colors.colShadow, 0.5)
    }
}
