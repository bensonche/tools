import * as Util from "./util/util.js"

function updateBadge(result) {
    if (result && result.taskList !== undefined && result.taskList !== null) {
        chrome.browserAction.setBadgeText({ text: Util.getTotalTimeString(result.taskList, true) });

        if (Util.isStarted(result.taskList))
            chrome.browserAction.setBadgeBackgroundColor({ color: "green" });
        else
            chrome.browserAction.setBadgeBackgroundColor({ color: "maroon" });
    }
}

chrome.storage.sync.get("taskList", updateBadge);

setInterval(function () {
    chrome.storage.sync.get("taskList", updateBadge);
}, 1000);