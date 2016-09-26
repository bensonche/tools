import React from "react"
import $ from "jquery"
import _ from "underscore"
import * as Util from "../util/util.js"

import Task from "./Task.jsx"

var TaskList = React.createClass({
    getInitialState: function () {
        return {
            taskList: [
                {
                    name: "test1",
                    timer: [{ start: 0, stop: 54353 }]
                },
                {
                    name: "test2",
                    timer: [{ start: 0, stop: 454654 }]
                },
                {
                    name: "test3",
                    timer: [{ start: 0, stop: 12252 }]
                },
                {
                    name: "test4",
                    timer: [{ start: 0, stop: 10000 }]
                },
                {
                    name: "test5",
                    timer: []
                },
                {
                    name: "test6",
                    timer: [{ start: Date.now() - 5000 }]
                }
            ]
        };
    },

    getTotalTime: function () {
        var elapsed = 0; 
        _.each(this.state.taskList, function (v) {
            elapsed += Util.getElapsedTime(v.timer);
        });
        
        return Util.timeToString(elapsed);
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
        }
    },

    nameChanged: function (name, event) {
        var newName = event.target.value;

        var taskList = this.state.taskList;

        if (name === null)
            taskList.push({
                name: newName,
                isStarted: false,
                elapsed: 0,
                focus: true
            });
        else {
            var task = _.findWhere(taskList, { name: name });

            task.name = newName;
        }

        this.setState({
            taskList: taskList
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
                <span>{this.getTotalTime()}</span>
                {taskList}
                <Task name="" nameChanged={self.nameChanged.bind(null, null) }/>
            </div>
        );
    }
});

export default TaskList;