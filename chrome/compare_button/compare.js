(function () {
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

	function init() {
		buildCompareButton();
		buildQAButton();
	}

	document.addEventListener("DOMSubtreeModified", function(){
		init();
	});
})()
