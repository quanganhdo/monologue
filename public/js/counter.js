$(function() {
	updateCounter();
	$('#content').focus();
	$('#content').bind('keypress keyup', updateCounter);
});

function updateCounter() {
	var remain = 140 - $('#content').val().length;
	$('#count').html(remain);
	if (remain < 0) {
		$('#count').removeClass().addClass('err');
		$('#submit').attr('disabled', true);
	} else if (remain < 20) {
		$('#count').removeClass().addClass('warning');
		$('#submit').removeAttr('disabled');
	} else {
		$('#count').removeClass().addClass('normal');
		$('#submit').removeAttr('disabled');
	}
}