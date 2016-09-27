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

    saveChanges: function () {
        chrome.storage.local.set({
            taskList: this.state.taskList
        });
    },

    getTotalTime: function () {
        return Util.getTotalTimeString(this.state.taskList);
    },

    start: function (name) {
        if (name !== null) {
            var now = Date.now();

            _.each(this.state.taskList, function (v) {
                if (v.timer.length > 0 && v.timer[v.timer.length - 1].stop === undefined)
                    v.timer[v.timer.length - 1].stop = now;

                if (v.name === name) {
                    v.timer.push({ start: now });
                }
            });

            this.setState({
                taskList: this.state.taskList
            });

            var self = this;
            this.timer = setInterval(function () {
                self.forceUpdate();
            }, 1000);

            this.saveChanges();
        }
    },

    stop: function (name) {
        if (name !== null) {
            var task = _.findWhere(this.state.taskList, { name: name });
            task.timer[task.timer.length - 1].stop = Date.now();

            this.setState({
                taskList: this.state.taskList
            });

            clearInterval(this.timer);

            this.saveChanges();
        }
    },

    componentDidMount: function () {
        var self = this;
        if (Util.isStarted(this.state.taskList)) {
            this.timer = setInterval(function () {
                self.forceUpdate();
            }, 1000);
        }
    },

    nameChanged: function (name, event) {
        var newName = event.target.value;

        var taskList = this.state.taskList;

        if (name === null)
            taskList.push({
                name: newName,
                timer: [],
                focus: true
            });
        else {
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

        var taskList = this.state.taskList.map(function (v, i) {
            return <Task
                key={i}
                name={v.name}
                timer={v.timer}
                nameChanged={self.nameChanged.bind(null, v.name) }
                focus={v.focus}
                start={self.start.bind(null, v.name) }
                stop={self.stop.bind(null, v.name) }
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