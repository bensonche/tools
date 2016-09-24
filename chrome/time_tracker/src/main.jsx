import React from "react"
import {render} from "react-dom"
import $ from "jquery"
import _ from "underscore"

var Task = React.createClass({
    getInitialState: function () {
        return {
            timeList: [],
            isStarted: false
        };
    },

    start: function () {
        var time = {
            start: Date.now()
        };

        var self = this;
        this.timer = setInterval(function () {
            self.forceUpdate();
        }, 1000);

        this.setState({
            timeList: this.state.timeList.concat(time),
            isStarted: true
        });
    },

    stop: function () {
        var time = this.state.timeList[this.state.timeList.length - 1];

        time.stop = Date.now();

        clearInterval(this.timer);

        this.setState({
            timeList: this.state.timeList,
            isStarted: false
        });
    },

    getElapsedTime: function () {
        if (this.state.timeList.length === 0)
            return "0:00";
        else {
            var elapsed = 0;
            _.each(this.state.timeList, function (i) {
                if (i.stop !== undefined)
                    elapsed += i.stop - i.start;
                else
                    elapsed += Date.now() - i.start;
            });

            if (elapsed === 0)
                return "0:00";

            var seconds = elapsed / 1000;
            seconds %= 60;

            var minutes = seconds / 60;
            minutes %= 60;

            seconds = parseInt(seconds);
            if (seconds < 10)
                seconds = "0" + seconds;

            return parseInt(minutes) + ":" + seconds;
        }
    },

    render() {
        var StartStop;
        if (this.state.isStarted)
            StartStop = <button onClick={this.stop}>Stop</button>
        else
            StartStop = <button onClick={this.start}>Start</button>

        return (
            <div className="task">
                <div>{this.props.name}</div>
                <div>Time elapsed: {this.getElapsedTime() }</div>
                {StartStop}
            </div>
        );
    }
});

render(<Task name='test' />, document.getElementById('main'));
