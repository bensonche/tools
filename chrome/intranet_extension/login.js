(function () {
	$(function() {
		$("input#tbUserName").on("keyup", function () {
			window.Extension = window.Extension || {};
			
			if($(this).val() == "rda"
				|| $(this).val() == "rdb"
				|| $(this).val() == "rdp"
				|| $(this).val() == "rde") {
				$("input#tbPassword").val("rdiintranettestaccount");
				window.Extension.AutoPW = true;
			}
			else if (window.Extension.AutoPW) {
				$("input#tbPassword").val("");
				window.Extension.AutoPW = false;
			}
		});
	});
})()
