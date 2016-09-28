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
            taskList: [
                // {
                //     name: "test1",
                //     timer: [{ start: 0, stop: 54353 }]
                // },
                // {
                //     name: "test2",
                //     timer: [{ start: 0, stop: 454654 }]
                // },
                // {
                //     name: "test3",
                //     timer: [{ start: 0, stop: 12252 }]
                // },
                // {
                //     name: "test4",
                //     timer: [{ start: 0, stop: 10000 }]
                // },
                // {
                //     name: "test5",
                //     timer: []
                // },
                // {
                //     name: "test6",
                //     timer: [{ start: Date.now() - 5000 }]
                // }
            ]
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
        chrome.storage.local.set({
            taskList: this.state.taskList
        });
    },

    getTotalTime: function () {
        return Util.getTotalTimeString(this.state.taskList);
    },

    start: function (id) {
        var task = _.findWhere(this.state.taskList, { id: id });

        var now = Date.now();

        _.each(this.state.taskList, function (v) {
            if (v.timer.length > 0 && v.timer[v.timer.length - 1].stop === undefined)
                v.timer[v.timer.length - 1].stop = now;
        });

        task.timer.push({ start: now });

        this.setState({
            taskList: this.state.taskList
        });

        var self = this;

        if (this.timer === undefined || this.timer === null) {
            this.timer = setInterval(function () {
                self.forceUpdate();
            }, 1000);
        }

        this.saveChanges();
    },

    stop: function (id) {
        var task = _.findWhere(this.state.taskList, { id: id });
        task.timer[task.timer.length - 1].stop = Date.now();

        this.setState({
            taskList: this.state.taskList
        });

        clearInterval(this.timer);
        this.timer = null;

        this.saveChanges();
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
        });

        this.saveChanges();
    },

    nameChanged: function (name, event) {
        var newName = event.target.value;

        var taskList = this.state.taskList;

        if (name === null) {
            var now = Date.now();
            taskList.push({
                name: newName,
                timer: [],
                focus: true,
                id: now
            });
            this.focus = now;
        }else {
            var task = _.findWhere(taskList, { name: name });

            task.name = newName;
        }

        this.setState({
            taskList: taskList
        });

        this.saveChanges();
    },

    reset: function () {
        this.setState({
            taskList: []
        });
    },

    render: function () {
        var self = this;

        var sortedTaskList = _.sortBy(this.state.taskList, function (v) {
            if (v.timer.length === 0)
                return 0
            return -v.timer[v.timer.length - 1].start;
        });

        var focusId = this.focus;
        this.focus = null;

        var taskList = sortedTaskList.map(function (v, i) {
            return <Task
                key={v.id}
                name={v.name}
                timer={v.timer}
                nameChanged={self.nameChanged.bind(null, v.name) }
                focus={focusId === v.id}
                start={self.start.bind(null, v.id) }
                stop={self.stop.bind(null, v.id) }
                delete={self.delete.bind(null, v.id) }
                />;
        });

        return (
            <div className="taskList">
                <button className="btn btn-danger" onClick={this.reset}>Reset</button>
                <span>{this.getTotalTime() }</span>
                {taskList}
                <Task name="" nameChanged={this.nameChanged.bind(null, null) }/>
            </div>
        );
    }
});

export default TaskList;