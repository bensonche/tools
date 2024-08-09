function save_options() {
    var empid = $("#txtID").val();
    
    chrome.storage.sync.set({
        empid: empid
    }, function () {
        $("#Message").text("saved");
        setTimeout(function() {
            $("#Message").text("");
        }, 500);
    });
}

function restore_options() {
    chrome.storage.sync.get({
        empid: ''
    }, function(items) {
        $("#txtID").val(items.empid);
    });
}

$(restore_options);
$("#btnSave").click(save_options);