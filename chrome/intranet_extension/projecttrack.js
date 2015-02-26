(function () {
	var ran = false;
	
	var selfID = null;
	
	function GetLatestQA() {
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
	
	function buildSQLCount() {
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
					
					console.log(GetLatestQA());
					if(updatedDate > GetLatestQA())
						sqlCount++;
				}
			}
		});
		
		var txtBranch = $("[id$=txtBranch]");

		if(txtBranch.length == 0) {
			return;
		}
		
		if(sqlCount == 1)
			txtBranch.parent().append("<span id='SQLCount' class='RDIText'>" + sqlCount + " SQL file uploaded since last release</span>");
		else
			txtBranch.parent().append("<span id='SQLCount' class='RDIText'>" + sqlCount + " SQL files uploaded since last release</span>");
	}

	function isRTP() {
		if($("[id$=ddlStatus]").length > 0) {
			return $("[id$=ddlStatus]").val() == '48';
		}
		return false;
	}

	function buildCompareButton () {
		if($("a#githubCompare").length > 0) {
			return;
		}
		var txtBranch = $("[id$=txtBranch]");

		if(txtBranch.length == 0) {
			return;
		}

		txtBranch.after("<a id='githubCompare' class='RDIHyperLink' href='#' target='_blank'>Compare</a>");

		updateLink();

		txtBranch.keyup(function () {
			updateLink();
		});


		function getURL(branch) {
			var github = "https://github.com/ResourceDataInc/Intranet/compare/";
			return github + branch;
		}

		function updateLink() {
			$("a#githubCompare").prop("href", getURL(txtBranch.val()));
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
				empid: ''
			}, function (item) {
				selfID = item.empid;
				dfd.resolve();
			});
		} else {
			dfd.resolve();
		}
		
		dfd.done(function () {
			buildSQLCount();
			buildCompareButton();
			buildQAButton();
			subscribeSelfCheckbox();
			reassignPTs();
		});
	}


	document.addEventListener("DOMSubtreeModified", function(){
		init();
	});
})()
