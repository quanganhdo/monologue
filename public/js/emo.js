$(function() {
	$('.emo').click(function() {
		$('.emo').removeClass('selected');
		$(this).addClass('selected');
		$('#emo').val($(this).attr('id'));
	});
});