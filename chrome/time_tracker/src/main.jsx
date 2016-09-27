import React from "react"
import {render} from "react-dom"

import TaskList from "./components/TaskList.jsx"

chrome.storage.local.get("taskList", function (result) {
    if (result && result.taskList !== undefined && result.taskList !== null)
        render(<TaskList taskList={result.taskList} />, document.getElementById('main'));
    else
        render(<TaskList />, document.getElementById('main'));
});
