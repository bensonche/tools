import * as Util from "./util/util.js"

chrome.storage.local.get("taskList", function (result) {
    if (result && result.taskList !== undefined && result.taskList !== null) {
        chrome.browserAction.setBadgeText({ text: Util.getTotalTimeString(result.taskList, true) });

        if (Util.isStarted(result.taskList))
            chrome.browserAction.setBadgeBackgroundColor({ color: "green" });
        else
            chrome.browserAction.setBadgeBackgroundColor({ color: "maroon" });
    }
});

setInterval(function () {
    chrome.storage.local.get("taskList", function (result) {
        if (result && result.taskList !== undefined && result.taskList !== null) {
            chrome.browserAction.setBadgeText({ text: Util.getTotalTimeString(result.taskList, true) });

            if (Util.isStarted(result.taskList))
                chrome.browserAction.setBadgeBackgroundColor({ color: "green" });
            else
                chrome.browserAction.setBadgeBackgroundColor({ color: "maroon" });
        }
    });
}, 1000);