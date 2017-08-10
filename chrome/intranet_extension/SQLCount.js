"use strict";

var SQLCount = React.createClass({
    displayName: "SQLCount",

    getInitialState: function getInitialState() {
        return {
            count: this._getSQLCount()
        };
    },

    _getSQLCount: function _getSQLCount() {
        var table = $("[id$=gvDocList]");
        var extHeader = table.find(".RDIGridHeader th:contains(Ext)");
        var updHeader = table.find(".RDIGridHeader th:contains(Updated)");

        var colExtIndex = extHeader.parent().children().index(extHeader);
        var colUpdIndex = updHeader.parent().children().index(updHeader);

        var sqlCount = 0;
        $.each(table.find("tr"), function (index, value) {
            if (index == 0) return true;

            var extension = $(value).find("td").eq(colExtIndex).text().trim();
            if (extension == ".sql" || extension == "sql") {
                var dateString = $(value).find("td").eq(colUpdIndex).text().trim();
                if (!isNaN(Date.parse(dateString))) {
                    var updatedDate = new Date(dateString);

                    if (updatedDate > getLatestQA()) sqlCount++;
                }
            }
        });

        return sqlCount;
    },

    render: function render() {
        var count = this.state.count;

        if (count == 0) return React.createElement(
            "span",
            { "class": "RDIText" },
            "No SQL"
        );
        if (count == 1) return React.createElement(
            "span",
            { "class": "RDIText" },
            React.createElement(
                "b",
                null,
                count
            ),
            " SQL file"
        );

        return React.createElement(
            "span",
            { "class": "RDIText" },
            React.createElement(
                "b",
                null,
                count
            ),
            " SQL files"
        );
    }
});