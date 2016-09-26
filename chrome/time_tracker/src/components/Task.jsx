import React from "react"
import $ from "jquery"
import _ from "underscore"

var Task = React.createClass({
    isStarted: function () {
        if (!this.props.timer || this.props.timer.length === 0)
            return false;
        
        return this.props.timer[this.props.timer.length - 1].stop === undefined;
    },

    getElapsedTime: function () {
        if (!this.props.timer || this.props.timer.length === 0)
            return 0;
        else {
            var elapsed = 0;
            _.each(this.props.timer, function (i) {
                if (i.stop !== undefined)
                    elapsed += i.stop - i.start;
                else
                    elapsed += Date.now() - i.start;
            });
            return elapsed;
        }
    },

    getElapsedTimeString: function () {
        var elapsed = this.getElapsedTime();

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
    },

    render() {
        var StartStop;
        if (this.props.name !== undefined && this.props.name.length > 0) {
            if (this.isStarted())
                StartStop = <button className="btn btn-danger btn-xs" onClick={this.props.stop}>Stop</button>
            else
                StartStop = <button className="btn btn-success btn-xs" onClick={this.props.start}>Start</button>
        }

        var input = <input type="text" value={this.props.name} onChange={this.props.nameChanged} />;
        if (this.props.focus) {
            input = <input autoFocus type="text" value={this.props.name} onChange={this.props.nameChanged} />;
        }

        return (
            <div className="task">
                {input}
                <div>Time elapsed: {this.getElapsedTimeString() }</div>
                {StartStop}
            </div>
        );
    }
});

export default Task;