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

    getInitialState: function () {
        return { addTime: "" };
    },

    componentDidUpdate: function () {
        if (this.props.focus !== undefined && this.props.focus) {
            $(this.refs.input).focus();
        }
    },

    componentDidMount: function () {
        if (this.props.focus !== undefined && this.props.focus) {
            $(this.refs.input).focus();
        }
    },

    addTime: function (time) {
        if (!isNaN(parseInt(this.state.addTime)))
            this.props.addTime(parseInt(this.state.addTime));

        this.setState({
            addTime: ""
        });
    },

    addTimeChanged: function (e) {
        this.setState({
            addTime: e.target.value
        });
    },

    render() {
        var controlButtons;
        if (this.props.name !== undefined && this.props.name.length > 0) {
            var deleteBtn =
                <button type="button" className="btn btn-default pull-right" onClick={this.props.delete}>
                    <span className="glyphicon glyphicon-trash"></span>
                </button>;

            var addTime =
                <div className="addTime">
                    <div className="input-group input-group-sm">
                        <input type="text" className="form-control" onChange={this.addTimeChanged} value={this.state.addTime} />

                        <span className="input-group-btn">
                            <button type="button" className="btn btn-default" onClick={this.addTime}>
                                +
                            </button>
                        </span>
                    </div>
                </div>;

            var startStop;
            if (this.isStarted())
                startStop = <button className="btn btn-danger btn-sm startStop" onClick={this.props.stop}>Stop</button>;
            else
                startStop = <button className="btn btn-success btn-sm startStop" onClick={this.props.start}>Start</button>;

            controlButtons =
                <div>
                    {startStop}
                    {deleteBtn}
                    {addTime}
                </div>;
        }

        var nameInput = <input ref="input" type="text" value={this.props.name} onChange={this.props.nameChanged} />;

        return (
            <div className="task">
                {nameInput}
                <div>Time elapsed: {Util.getElapsedTimeString(this.props.timer) }</div>
                {controlButtons}
            </div>
        );
    }
});

export default Task;