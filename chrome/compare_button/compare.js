(function () {
	var selfID = 320;
	var ran = false;

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

		txtBranch.after("<a id='githubCompare' class='RDIHyperLink' href='#'>Compare</a>");

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
		buildCompareButton();
		buildQAButton();
		subscribeSelfCheckbox();
		reassignPTs();
	}


	document.addEventListener("DOMSubtreeModified", function(){
		init();
	});
})()
