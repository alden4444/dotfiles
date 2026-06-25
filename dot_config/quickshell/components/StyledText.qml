import QtQuick
import "../theme"

// Theme-aware text on the Obsidian type scale. Set `variant` to pick the role (display
// uses the mono display face, the rest use the body face). Callers can still override
// font.pixelSize / color directly: explicit assignment wins, so existing call sites
// keep working.
Text {
    id: root

    // display | header | title | body | label | caption
    property string variant: "body"

    color: Theme.inkPrimary
    font.family: variant === "display" ? Theme.fontDisplay : Theme.fontBody
    font.pixelSize: variant === "display" ? Theme.fsDisplay
        : variant === "title" ? Theme.fsTitle
        : variant === "header" ? Theme.fsHeader
        : variant === "label" ? Theme.fsLabel
        : variant === "caption" ? Theme.fsCaption
        : Theme.fsBody
    font.weight: (variant === "display" || variant === "title" || variant === "header") ? Theme.wMedium : Theme.wRegular
    // headers get tightened tracking; everything else stays at natural spacing
    font.letterSpacing: variant === "header" ? Theme.headerTracking : 0
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
}
