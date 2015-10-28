(function () {
	function init() {
		var $items = $(".ItemID");
		
		$.each($items, function(i, v) {
			var $v = $(v);
			var id = $v.text();
			
			$v.empty();
			$v.append("<a href='/privatedn/ProjectTrack/IssueGrid.aspx?IssueID=" + id + "'>" + id + "</a>");
		});
	}

	$(function() {
		init();
	});
})()
