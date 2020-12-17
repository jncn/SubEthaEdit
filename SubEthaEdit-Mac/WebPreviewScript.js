window.onmouseover = function(event) {
    var closestAnchor = event.target.closest('a')
    if (closestAnchor) {
        window.webkit.messageHandlers.scriptHoverHandler.postMessage(closestAnchor.href);
    }
}
window.onmouseout = function(event) {
    var closestAnchor = event.target.closest('a')
    if (closestAnchor) {
        window.webkit.messageHandlers.scriptHoverHandler.postMessage("");
    }
}
