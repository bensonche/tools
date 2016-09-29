import $ from "jquery"
import _ from "underscore"

export function getElapsedTime(timer) {
    if (!timer || timer.length === 0)
        return 0;
    else {
        var elapsed = 0;
        _.each(timer, function (i) {
            if (i.stop !== undefined)
                elapsed += i.stop - i.start;
            else
                elapsed += Date.now() - i.start;
        });
        return elapsed;
    }
}

export function getElapsedTimeString(timer) {
    return timeToString(this.getElapsedTime(timer));
}

export function timeToString(elapsed, showHours) {
    if (elapsed === 0)
        return "0:00";

    var seconds = parseInt(elapsed / 1000);
    var minutes = parseInt(seconds / 60);
    var hours = parseInt(minutes / 60);

    seconds %= 60;
    minutes %= 60;

    var displayString = "";

    if (showHours) {
        if (hours > 0)
            displayString = hours + "h";

        displayString += parseInt(minutes) + "m";
        return displayString;
    }

    if (seconds < 10)
        seconds = "0" + seconds;

    if (hours > 0) {
        displayString = hours + ":";
        if (minutes < 10)
            displayString += "0";
        displayString += parseInt(minutes) + ":" + seconds;
    }
    else {
        displayString += parseInt(minutes) + ":" + seconds;
    }

    return displayString;
}

export function getTotalTimeString(timerList, showHours) {
    var elapsed = 0;
    _.each(timerList, function (v) {
        elapsed += getElapsedTime(v.timer);
    });

    return timeToString(elapsed, showHours);
}

export function isStarted(timerList) {
    var started = _.find(timerList, function (v) {
        if (v.timer.length === 0)
            return false;

        if (v.timer[v.timer.length - 1].stop === undefined)
            return true;
    });

    return started !== undefined;
}