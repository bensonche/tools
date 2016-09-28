import React from "react"
import $ from "jquery"
import _ from "underscore"
import * as Util from "../util/util.js"

var Task = React.createClass({
    isStarted: function () {
        if (!this.props.timer || this.props.timer.length === 0)
            return false;

        return this.props.timer[this.props.timer.length - 1].stop === undefined;
    },

    render() {
        var StartStop;
        if (this.props.name !== undefined && this.props.name.length > 0) {
            if (this.isStarted())
                StartStop =
                    <div>
                        <button className="btn btn-danger btn-xs" onClick={this.props.stop}>Stop</button>
                        <button type="button" className="btn btn-sm delete-button" onClick={this.props.delete}>
                            <span className="glyphicon glyphicon-trash"></span>
                        </button>
                    </div>
            else
                StartStop =
                    <div>
                        <button className="btn btn-success btn-xs" onClick={this.props.start}>Start</button>
                        <button type="button" className="btn btn-sm delete-button" onClick={this.props.delete}>
                            <span className="glyphicon glyphicon-trash"></span>
                        </button>
                    </div>
        }

        var input = <input type="text" value={this.props.name} onChange={this.props.nameChanged} />;
        if (this.props.focus) {
            input = <input autoFocus type="text" value={this.props.name} onChange={this.props.nameChanged} />;
        }

        return (
            <div className="task">
                {input}
                <div>Time elapsed: {Util.getElapsedTimeString(this.props.timer) }</div>
                {StartStop}
            </div>
        );
    }
});

export default Task;