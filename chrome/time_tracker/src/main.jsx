import React from "react"
import {render} from "react-dom"

class Task extends React.Component {
    render() {
        return (
            <div className="task">
                <div>{this.props.name}</div>
                <div>Time elapsed: { this.props.name }</div>
            </div>
        );
    }
}

render(<Task name='test' />, document.getElementById('main'));
