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

export function timeToString(elapsed) {
    if (elapsed === 0)
        return "0:00";

    var seconds = parseInt(elapsed / 1000);
    var minutes = parseInt(seconds / 60);
    var hours = parseInt(minutes / 60);

    seconds %= 60;
    minutes %= 60;

    if (seconds < 10)
        seconds = "0" + seconds;

    var displayString = "";

    if (hours > 0)
        displayString = hours + ":";

    displayString += parseInt(minutes) + ":" + seconds;

    return displayString;
}