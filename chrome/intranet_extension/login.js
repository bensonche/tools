(function () {
    $(function() {
        $("input#tbUserName").on("blur", function () {
            if($(this).val() == "rda"
                || $(this).val() == "rdb"
                || $(this).val() == "rdp"
                || $(this).val() == "rde")
                $("input#tbPassword").val("rdiintranettestaccount");
            else
                $("input#tbPassword").val("");
        });
    });
})()
