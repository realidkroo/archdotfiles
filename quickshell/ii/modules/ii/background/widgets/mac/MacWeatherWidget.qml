import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "macWeather"
    visibleWhenLocked: Config.options.background.widgets.macWeather.showOnLockScreen

    implicitHeight: weatherRow.implicitHeight
    implicitWidth: weatherRow.implicitWidth

    // --- 1. LOGIC: Define your quotes here ---
    function getQuote(code) {
        // If code is missing, return a default
        if (code === undefined || code === null) return "Have a nice day!";

        // These codes are based on standard WMO weather codes. 
        // You might need to adjust the numbers depending on your weather provider.
        
        // Thunderstorm (Codes 95, 96, 99)
        if (code >= 95) return "Stay safe inside!";
        
        // Snow (Codes 71-77, 85-86)
        if (code >= 71 && code <= 86) return "Do you want to build a snowman?";
        
        // Rain (Codes 51-67, 80-82)
        if (code >= 51 && code <= 67 || code >= 80 && code <= 82) return "It's raining! Have some hot coffee.";
        
        // Fog (Codes 45, 48)
        if (code === 45 || code === 48) return "Spooky weather...";
        
        // Clear Sky / Sunny (Code 0, 1)
        if (code <= 1) return "Soak up the sun!";
        
        // Cloudy (Code 2, 3)
        if (code <= 3) return "A bit grey, but cozy.";

        // Default fallback
        return "Enjoy the weather!";
    }

    StyledDropShadow {
        target: weatherRow
    }

    RowLayout {
        id: weatherRow
        spacing: 12

        // Weather Icon (Left side)
        MaterialSymbol {
            iconSize: 48
            color: root.colText
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            style: Text.Raised
            styleColor: ColorUtils.transparentize(Appearance.colors.colShadow, 0.5)
            
            // Align icon to the center of the row vertically
            Layout.alignment: Qt.AlignVCenter
        }

        // --- 2. LAYOUT: Stack Temp and Quote vertically ---
        ColumnLayout {
            spacing: 0 // Space between temp and quote
            Layout.alignment: Qt.AlignVCenter

            // Temperature Text
            StyledText {
                id: tempText
                text: Weather.data?.temp ?? "--°"
                color: root.colText
                font {
                    pixelSize: 30
                    family: Appearance.font.family.expressive
                    weight: Font.Bold
                }
                style: Text.Raised
                styleColor: ColorUtils.transparentize(Appearance.colors.colShadow, 0.5)
            }

            // The New Quote Text
            StyledText {
                id: quoteText
                text: getQuote(Weather.data.wCode)
                color: ColorUtils.transparentize(root.colText, 0.2) // Slightly distinct color
                font {
                    pixelSize: 14 // Smaller font for the quote
                    family: Appearance.font.family.main // Standard font for readability
                    weight: Font.DemiBold
                }
                style: Text.Raised
                styleColor: ColorUtils.transparentize(Appearance.colors.colShadow, 0.5)
            }
        }
    }
}