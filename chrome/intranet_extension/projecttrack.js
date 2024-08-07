(function () {
    var ran = false;

    var selfID = null;

    function buildPullRequestLink() {
        function getPRId(url) {
            return parseInt(url.match(/\d+$/));
        }

        if ($("#github-PR").length > 0)
            return;

        var allMatches = [];
        $.each($(".RDIHistorySection p"), function (i, v) {
            var body = $(v).text();

            var matches = body.match(/https:\/\/github\.com\/ResourceDataInc\/Intranet\/pull\/\d+/i);
            if(matches)
            {
            for (let i = 0; i < matches.length; i++) {
                if (matches[i] !== null) {
                    allMatches = allMatches.concat(matches[i]);

                }
            }
        }

            matches = body.match(/https:\/\/github\.com\/ResourceDataInc\/ModernIntranet\/pull\/\d+/i);
            if(matches)
                {
                for (let i = 0; i < matches.length; i++) {
                    if (matches[i] !== null) {
                        allMatches = allMatches.concat(matches[i]);
    
                    }
                }
            }
        });

        allMatches = _.sortBy(allMatches, function (x) {
            return -getPRId(x);
        });

        allMatches = _.uniq(allMatches, true);

        var $link;

        if (allMatches.length === 0)
            $link = $("<div id='github-PR' class='RDIText'>PR missing</div>");
        else {
            var prId;
            var source;

            let link = "<div id='github-PR'>";

            const maxToDisplay =5;

            for (var i = 0; i < allMatches.length; i++) {

                if(i > maxToDisplay){
                    const remaining = allMatches.length;

                    link += `<div>${remaining} other PRs not shown</div>`;

                    break;
                }
                const currentMatch = allMatches[i];

                prId = getPRId(currentMatch);

                const isMI = currentMatch.search(/ModernIntranet/i) > -1;

                const environment = isMI ? "MI" : "Legacy";

                link += `<div><a target='_blank' class='RDIHyperLink' href='${currentMatch}'>${environment} PR ${prId}</a></div>`;
            }

            link += "</div>";

            $link = $(link);
        }

        $(".githubLinks").append($link);
    }

    function getLatestQA() {
        var historyItems = $(".RDIHistory .RDIHistoryItem .RDIHistorySidebar");

        var QADate = null;
        $.each(historyItems, function (index, value) {
            var found = false;
            $.each($(value).find(".RDIRowChanged td"), function (index, value) {
                var text = $(value).text().replace(/\240/g, " ").trim();

                if (text == "Release to Production to Quality Assurance") {
                    found = true;
                    return false;
                }
            });

            if (found) {
                var dateString = $(value).find("tr").eq(0).text().substring(0, 10);
                if (!isNaN(Date.parse(dateString))) {
                    QADate = new Date(dateString);
                    return false;
                }
            }
        });

        return QADate;
    }

    function subscribeSelfCheckbox() {
        if ($("input#subscribeSelf").length > 0) {
            return;
        }

        var container = $("div#_NotificationsContainer tr").eq(1).find("td").eq(1).first();

        if (container.length == 0) {
            return;
        }

        if ($("input#subscribeSelf").length > 0) {
            return;
        }

        container.prepend("<input type='checkbox' id='subscribeSelf' class='bc_vertMiddle' /><span class='bc_vertMiddle' >Subscribe myself</span>");
        container.css("text-align", "left");

        if (isNaN(parseInt(selfID))) {
            var span = $("<span style='color: red;'>Please set your employee ID <a target='_blank'>here</a> and refresh the page</span>");

            var url = span.find("a");
            url.prop("href", chrome.extension.getURL("options.html"));

            container.append(span);

            $("#subscribeSelf").prop("disabled", "disabled");

            return;
        }

        toggleCheckbox();

        $("input#subscribeSelf").change(function () {
            var left = $("select[id$=Notifications__RDIUsers]");
            var right = $("select[id$=Notifications__NotifyList]");

            if ($(this).prop("checked")) {
                left.val(selfID);
                $("input[id$=Notifications_btnAddUser]").click();
            } else {
                right.val(selfID);
                $("input[id$=btnDeleteNotify]").click();
            }
        });
    }

    function toggleCheckbox() {
        if ($("input#subscribeSelf").length == 0) {
            return;
        }

        var left = $("select[id$=Notifications__RDIUsers]");
        var right = $("select[id$=Notifications__NotifyList]");

        var me = right.findSelf();
        $("input#subscribeSelf").prop("checked", me.length > 0);
    }

    $.fn.findSelf = function () {
        return $(this[0]).find("option[value=" + selfID + "]");
    }

    function buildQAButton() {
        if (isRTP()) {
            if ($("input#QAButton").length > 0) {
                return;
            }

            var assignTo = $("span#assignedToDdSpan");

            if (assignTo.length == 0) {
                return;
            }

            assignTo.after("<input type='button' id='QAButton' value='QA' class='RDIButton' />");

            $("input#QAButton").click(function () {
                if ($("[id$=ddlAssignedTo]").val() != 10000) {
                    $("select[id$=ddlStatus] option[value=8]").prop("selected", true);

                    var prodString = "In prod, please review.";
                    prodString += "\n";
                    prodString += "Please create a new branch for any additional work.";

                    $("textarea[id$=txtComments]").val(prodString);

                    $("input[id$=Submit]").click();
                }
            });


        } else {
            $("input#QAButton").remove();
        }
    }

    function buildRTPButton() {
        if (isReview()) {
            if ($("input#RTPButton").length > 0) {
                return;
            }

            // Check assigned to Intranet Group
            if ($("span#assignedToDdSpan select option:selected").val() != 10000)
                return;

            // Check git feature branch
            if ($("input[id$=txtBranch]").val().trim() === "")
                return;

            // Check change summary
            if ($("textarea[id$=txtChangedDescription]").val().trim() === "")
                return;

            var assignTo = $("span#assignedToDdSpan");

            if (assignTo.length == 0) {
                return;
            }

            assignTo.after("<input type='button' id='RTPButton' value='Release to Prod' class='RDIButton' />");

            $("input#RTPButton").click(function () {
                $("select[id$=ddlStatus] option[value=48]").prop("selected", true);
                $("input[id$=Submit]").click();
            });
        } else {
            $("input#RTPButton").remove();
        }
    }

    function isRTP() {
        if ($("[id$=ddlStatus]").length > 0) {
            return $("[id$=ddlStatus]").val() == '48';
        }
        return false;
    }

    function isReview() {
        if ($("[id$=ddlStatus]").length > 0) {
            return $("[id$=ddlStatus]").val() == '7';
        }
        return false;
    }

    function buildCompareButton() {
        if ($("a.githubCompare").length > 0) {
            return;
        }
        var txtBranch = $("[id$=txtBranch]");

        if (txtBranch.length == 0) {
            return;
        }

        var compare = $("<div class='githubLinks'><a class='githubCompare RDIHyperLink' data-repo='Intranet' href='#' target='_blank'>Compare</a></div>");

        txtBranch.after(compare);

        updateLink();

        txtBranch.keyup(function () {
            updateLink();
        });

        function getURL(branch, repo) {
            var github = "https://github.com/ResourceDataInc/" + repo + "/compare/";
            return github + branch;
        }

        function updateLink() {
            $("a.githubCompare").each(function (i, v) {
                var repo = $(v).data("repo");
                $(v).prop("href", getURL(txtBranch.val(), repo));
            });
        }
    }

    function readURL() {
        var empid = $.url().param("bcempid");
        if (!isNaN(empid)) {
            return empid;
        }
        return null;
    }

    function reassignPTs() {
        if (ran) {
            return;
        }
        ran = true;

        // Check that the empid supplied is valid
        var empid = readURL();
        if (!empid) {
            return;
        }

        // Check that the QA button exists
        if ($("input#QAButton").length == 0) {
            return;
        }

        $("select[id$=ddlAssignedTo]").val(empid);

        setTimeout(function () {
            $("input#QAButton").first().click();
        }, 5000);
    }

    function init() {
        var dfd = $.Deferred();

        if (isNaN(parseInt(selfID))) {
            chrome.storage.sync.get({
                empid: '',
            }, function (item) {
                selfID = item.empid;
                dfd.resolve();
            });
        } else {
            dfd.resolve();
        }

        dfd.done(function () {
            buildCompareButton();
            buildQAButton();
            buildRTPButton();
            buildPullRequestLink();
            subscribeSelfCheckbox();
            reassignPTs();
        });
    }


    $(document).ready(function () {
        init();
    });
})()
