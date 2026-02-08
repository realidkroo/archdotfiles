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

    configEntryName: "macDate"
    visibleWhenLocked: Config.options.background.widgets.macDate.showOnLockScreen

    implicitHeight: dateText.implicitHeight
    implicitWidth: dateText.implicitWidth

    StyledDropShadow {
        target: dateText
    }

    StyledText {
        id: dateText
        text: DateTime.longDate
        color: root.colText
        font {
                pixelSize: 40
                family: Appearance.font.family.expressive
                weight: Font.Bold
        }
        style: Text.Raised
        styleColor: ColorUtils.transparentize(Appearance.colors.colShadow, 0.5)
    }
}
