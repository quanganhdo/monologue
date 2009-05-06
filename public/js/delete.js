$(function() {
	$('.delete_post').click(function() {
		if (confirm('Delete this entry permanently?')) {
			var id = $(this).attr('id').match(/delete_post_([0-9]*)/)[1];
			
			$.post('/delete', {id: id, _method: 'delete'}, function(data) {
				if (data.result == 'success') {
					humanMsg.displayMsg('Entry deleted successfully.');
					if ($('.post').length > 0) { // home
						$('#post_' + id).hide('slow');
					} else { // view 
						setTimeout("document.location.replace('/')", 2000);
					}
				} else {
					humanMsg.displayMsg('Oops... the system was unable to perform your operation. Please try again.');
				}
			}, 'json');
		}
	});
});