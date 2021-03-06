$(function() {
	page = 0;

	$('#reader').spy({
		ajax: '/random',
		limit: 7,
		fadeLast: 3,
		fadeInSpeed: 600,
		timeout: 3000,
		method: 'json',
		push: another,
		pushTimeout: 3000,
		isDupe: function(latest, last) { return latest.id == last.id; }
	});
	
	$('#pause').click(function() {
		humanMsg.displayMsg('Reader paused.');
		$('#pause').hide();
		$('#resume').show();
		return pauseSpy();
	});
	
	$('#resume').click(function() {
		humanMsg.displayMsg('Reader resumed.');
		$('#resume').hide();
		$('#pause').show();
		return playSpy();
	});
});

function another(post) {
	var html = '<li>';
	html += '<a href="/' + post.emo + '/days" title="View your most recent 7 ' + post.emo + ' days">';
		html += '<img class="emo2" width="48" height="48" alt="' + post.emo + '" src="/img/emo/' + post.emo + '.png"';
	html += '</a>';
	html += '<h4>';
		html += '<span class="meta">';
			html += 'Posted on ' + post.created_at.match(/([0-9]{4}\/[0-9]{2}\/[0-9]{2}).*/)[1] + ' &middot; ';
			html += '<a href="/' + post.id + '" title="Permalink to this entry">#</a>';
		html += '</span>';
	html += '</h4>';
	html += '<div class="postcontent"><p>' + post.content + '</p></div>';
	html += '<div class="bottom_of_entry"></div>';
	$('#' + this.id).prepend(html);
}