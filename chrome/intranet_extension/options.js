function save_options() {
	var empid = $("#txtID").val();
	var oauth = $("#oAuth").val();
	
	chrome.storage.sync.set({
		empid: empid,
        oauth: oauth
	}, function () {
		$("#Message").text("saved");
		setTimeout(function() {
			$("#Message").text("");
		}, 500);
	});
}

function restore_options() {
	chrome.storage.sync.get({
		empid: '',
        oauth: ''
	}, function(items) {
		$("#txtID").val(items.empid);
		$("#oAuth").val(items.oauth);
	});
}

$(restore_options);
$("#btnSave").click(save_options);