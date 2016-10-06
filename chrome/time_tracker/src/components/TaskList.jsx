import React from "react"
import $ from "jquery"
import _ from "underscore"

import Task from "./Task.jsx"
import * as Util from "../util/util.js"

var TaskList = React.createClass({
    getInitialState: function () {
        if (this.props.taskList)
            return { taskList: this.props.taskList };

        return {
            taskList: []
        };
    },

    componentDidMount: function () {
        var self = this;
        if (Util.isStarted(this.state.taskList)) {
            this.timer = setInterval(function () {
                self.forceUpdate();
            }, 1000);
        }
    },

    saveChanges: function () {
        chrome.storage.sync.set({
            taskList: this.state.taskList
        });
    },

    getTotalTime: function () {
        return Util.getTotalTimeString(this.state.taskList);
    },

    start: function (id) {
        var task = _.findWhere(this.state.taskList, { id: id });

        this.focus = task.id;

        var now = Date.now();

        _.each(this.state.taskList, function (v) {
            if (v.timer.length > 0 && v.timer[v.timer.length - 1].stop === undefined)
                v.timer[v.timer.length - 1].stop = now;
        });

        task.timer.push({ start: now });

        this.setState({
            taskList: this.state.taskList
        }, this.saveChanges);

        var self = this;

        if (this.timer === undefined || this.timer === null) {
            this.timer = setInterval(function () {
                self.forceUpdate();
            }, 1000);
        }
    },

    stop: function (id) {
        var task = _.findWhere(this.state.taskList, { id: id });
        task.timer[task.timer.length - 1].stop = Date.now();

        this.focus = task.id;

        this.setState({
            taskList: this.state.taskList
        }, this.saveChanges);

        clearInterval(this.timer);
        this.timer = null;
    },

    delete: function (id) {
        var index = _.findIndex(this.state.taskList, function (v) {
            return v.id === id;
        });

        if (index === -1)
            return;

        var removed = this.state.taskList.splice(index, 1);

        this.setState({
            taskList: this.state.taskList
        }, this.saveChanges);
    },

    nameChanged: function (name, event) {
        var newName = event.target.value;

        var taskList = this.state.taskList;

        if (name === null) {
            var now = Date.now();
            taskList.push({
                name: newName,
                timer: [],
                id: now
            });
            this.focus = now;
        } else {
            var task = _.findWhere(taskList, { name: name });

            task.name = newName;
        }

        this.setState({
            taskList: taskList
        }, this.saveChanges);
    },

    addTime: function (id, time) {
        var task = _.findWhere(this.state.taskList, { id: id });
        task.timer.splice(0, 0, { start: 0, stop: time * 1000 * 60 });

        this.setState({
            taskList: this.state.taskList
        }, this.saveChanges);
    },

    reset: function () {
        this.setState({
            taskList: []
        }, this.saveChanges);
    },

    render: function () {
        var self = this;

        var sortedTaskList = _.sortBy(this.state.taskList, function (v) {
            if (v.timer.length === 0)
                return 0
            return -v.timer[v.timer.length - 1].start;
        });

        var taskList = sortedTaskList.map(function (v, i) {
            return <Task
                key={v.id}
                name={v.name}
                timer={v.timer}
                nameChanged={self.nameChanged.bind(null, v.name) }
                focus={self.focus === v.id}
                start={self.start.bind(null, v.id) }
                stop={self.stop.bind(null, v.id) }
                delete={self.delete.bind(null, v.id) }
                addTime={self.addTime.bind(null, v.id) }
                />;
        });

        this.focus = null;

        return (
            <div className="taskList">
                <div id="infoPanel">
                    <button className="btn btn-danger" onClick={this.reset}>Reset</button>
                    <span className="pull-right">{this.getTotalTime() }</span>
                </div>

                {taskList}
                <Task name="" nameChanged={this.nameChanged.bind(null, null) }/>
            </div>
        );
    }
});

export default TaskList;