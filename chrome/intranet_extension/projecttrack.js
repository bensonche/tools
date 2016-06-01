(function () {
	var ran = false;
	
	var selfID = null;
    var oauth = null;
    
    function buildPullRequestLink() {
        function getPRId(url) {
            return parseInt(url.match(/\d+$/));
        }
        
        if($("#github-PR").length > 0)
            return;
        
        var allMatches = [];
        $.each($(".RDIHistorySection p"), function(i, v) {
            var body = $(v).text();
            
            var matches = body.match(/https:\/\/github\.com\/ResourceDataInc\/Intranet\/pull\/\d+/i);
            
            if(matches) {
                allMatches = allMatches.concat(matches);
            }
        });
        
        allMatches = _.sortBy(allMatches, function(x) {
            return -getPRId(x);
        });
        
        allMatches = _.uniq(allMatches, true);
        
        var $link;
        var validLink = false;
        var prId;
        
        if(allMatches.length === 0)
            $link = $("<div id='github-PR' class='RDIText'>PR missing</div>");
        else {
            prId = getPRId(allMatches[0]);
            var prCount = "";
            if(allMatches.length > 1)
                prCount = "(" + allMatches.length + ")";
            $link = $("<div id='github-PR'><a target='_blank' class='RDIHyperLink' href='" + allMatches[0] + "'>PR " + prId + " " + prCount + "</a><div class='circle circle-orange'></div></div>");
            validLink = true;
        }
        
        $("[id$=txtBranch]").parents("td").first().append($link);
        
        if(validLink) {
            if(oauth !== null && oauth.length > 0) {
                $.ajax({
                    url: "https://api.github.com/repos/ResourceDataInc/Intranet/pulls/" + prId + "?access_token=" + oauth
                }).done(function(d) {
                    if(d && d.head && d.head.ref) {
                        var branchname = d.head.ref;
                        if($("[id$=txtBranch]").val() === branchname)
                            $("#github-PR .circle").removeClass("circle-orange").addClass("circle-green");
                        else
                            $("#github-PR .circle").removeClass("circle-orange").addClass("circle-red");
                    }
                }).fail(function(d) {
                    $("#github-PR .circle").removeClass("circle").removeClass("circle-orange").addClass("error-link").html("<a class='RDIHyperLink' target='_blank' href='" + chrome.extension.getURL("options.html") + "'>Bad OAth token</a>");
                });
            }
            else {
                $("#github-PR .circle").removeClass("circle").removeClass("circle-orange").addClass("error-link").html("<a class='RDIHyperLink' target='_blank' href='" + chrome.extension.getURL("options.html") + "'>Missing OAth token</a>");
            }
        }
    }
    
	function getLatestQA() {
		var historyItems = $(".RDIHistory .RDIHistoryItem .RDIHistorySidebar");

		var QADate = null;
		$.each(historyItems, function(index, value) {
			var found = false;
			$.each($(value).find(".RDIRowChanged td"), function(index, value) {
				var text = $(value).text().replace(/\240/g, " ").trim();
				
				if(text == "Release to Production to Quality Assurance") {
					found = true;
					return false;
				}
			});
			
			if(found) {
				var dateString = $(value).find("tr").eq(0).text().substring(0, 10);
				if(!isNaN(Date.parse(dateString))) {
					QADate = new Date(dateString);
					return false;
				}
			}
		});
		
		return QADate;
	}

	function subscribeSelfCheckbox() {
		if($("input#subscribeSelf").length > 0) {
			return;
		}

		var container = $("div#_NotificationsContainer tr").eq(1).find("td").eq(1).first();

		if(container.length == 0) {
			return;
		}

		if($("input#subscribeSelf").length > 0) {
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

			if($(this).prop("checked")) {
				left.val(selfID);
				$("input[id$=Notifications_btnAddUser]").click();
			} else {
				right.val(selfID);
				$("input[id$=btnDeleteNotify]").click();
			}
		});
	}

	function toggleCheckbox() {
		if($("input#subscribeSelf").length == 0) {
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
		if(isRTP()) {
			if($("input#QAButton").length > 0) {
				return;
			}

			var assignTo = $("span#assignedToDdSpan");

			if(assignTo.length == 0) {
				return;
			}

			assignTo.after("<input type='button' id='QAButton' value='QA' class='RDIButton' />");

			$("input#QAButton").click(function () {
				if($("[id$=ddlAssignedTo]").val() != 10000) {
					$("select[id$=ddlStatus] option[value=8]").prop("selected", true);
					$("textarea[id$=txtComments]").val("In prod, please review.");

					$("input[id$=Submit]").click();
				}
			});


		} else {
			$("input#QAButton").remove();
		}
	}
	
	var buildingSQL = false;
	function buildSQLCount() {
		if(buildingSQL)
			return;
		
		buildingSQL = true;
		
		if($("span#SQLCount").length > 0) {
			return;
		}
		
		var table = $("[id$=tpFiles_FileList]");
		var extHeader = table.find(".RDIGridHeader td:contains(Extension)");
		var updHeader = table.find(".RDIGridHeader td:contains(Updated)");
		
		var colExtIndex = extHeader.parent().children().index(extHeader);
		var colUpdIndex = updHeader.parent().children().index(updHeader);
		
		var sqlCount = 0;
		$.each(table.find("tr"), function(index, value) {
			if(index == 0)
				return true;
			
			if($(value).find("td").eq(colExtIndex).text().trim() == ".sql") {
				var dateString = $(value).find("td").eq(colUpdIndex).text().trim();
				if(!isNaN(Date.parse(dateString))) {
					var updatedDate = new Date(dateString);
					
					if(updatedDate > getLatestQA())
						sqlCount++;
				}
			}
		});
		
		var txtBranch = $("[id$=txtBranch]");

		if(txtBranch.length == 0) {
			return;
		}
		
		if(sqlCount == 0)
			txtBranch.parent().append("<span id='SQLCount' class='RDIText'>No SQL</span>");
		else if(sqlCount == 1)
			txtBranch.parent().append("<span id='SQLCount' class='RDIText'><b>" + sqlCount + "</b> SQL file</span>");
		else
			txtBranch.parent().append("<span id='SQLCount' class='RDIText'><b>" + sqlCount + "</b> SQL files</span>");
		
		buildingSQL = false;
	}

	function isRTP() {
		if($("[id$=ddlStatus]").length > 0) {
			return $("[id$=ddlStatus]").val() == '48';
		}
		return false;
	}

	function buildCompareButton () {
		if($("a.githubCompare").length > 0) {
			return;
		}
		var txtBranch = $("[id$=txtBranch]");

		if(txtBranch.length == 0) {
			return;
		}

		var compare = $("<a class='githubCompare RDIHyperLink' data-repo='Intranet' href='#' target='_blank'>Compare</a>");
		var comparePublic = $("<a class='githubCompare RDIHyperLink' data-repo='RDIPublicSite' href='#' target='_blank'> [p]</a>");
		
		txtBranch.after(compare);
		compare.after(comparePublic);

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
		if(!isNaN(empid)) {
			return empid;
		}
		return null;
	}

	function reassignPTs() {
		if(ran) {
			return;
		}
		ran = true;

		// Check that the empid supplied is valid
		var empid = readURL();
		if(!empid) {
			return;
		}

		// Check that the QA button exists
		if($("input#QAButton").length == 0) {
			return;
		}

		$("select[id$=ddlAssignedTo]").val(empid);

		setTimeout(function() {
			$("input#QAButton").first().click();
		}, 5000);
	}

	function init() {
		var dfd = $.Deferred();
		
		if(isNaN(parseInt(selfID))) {
			chrome.storage.sync.get({
				empid: '',
                oauth: ''
			}, function (item) {
				selfID = item.empid;
				oauth = item.oauth;
				dfd.resolve();
			});
		} else {
			dfd.resolve();
		}
		
		dfd.done(function () {
			buildSQLCount();
			buildCompareButton();
			buildQAButton();
            buildPullRequestLink();
			subscribeSelfCheckbox();
			reassignPTs();
		});
	}


	document.addEventListener("DOMSubtreeModified", function(){
		init();
	});
})()
