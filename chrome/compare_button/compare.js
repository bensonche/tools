(function () {
	function buildButton () {
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

	buildButton();

	document.addEventListener("DOMSubtreeModified", function(){
		buildButton();
	});
})()
