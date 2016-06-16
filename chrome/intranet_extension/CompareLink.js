"use strict";

var CompareLink = React.createClass({
    displayName: "CompareLink",

    getInitialState: function getInitialState() {
        return {
            branchName: $("[id$=txtBranch]").val()
        };
    },

    componentDidMount: function componentDidMount() {
        var context = this;
        $("[id$=txtBranch]").on("input", function () {
            context.setState({
                branchName: $(this).val()
            });
        });
        context.setState({
            branchName: $("[id$=txtBranch]").val()
        });
    },

    render: function render() {
        var context = this;
        function getUrl(repo) {
            return "https://github.com/ResourceDataInc/" + repo + "/compare/" + context.state.branchName;
        }

        if (this.state.branchName.trim() === "") return React.createElement("div", null, React.createElement("span", null, "No git branch"));

        return React.createElement("div", null, React.createElement("a", { className: "RDIHyperLink", href: getUrl("Intranet"), target: "_blank" }, "Compare"), React.createElement("a", { className: "RDIHyperLink", href: getUrl("RDIPublicSite"), target: "_blank" }, "[p]"));
    }
});