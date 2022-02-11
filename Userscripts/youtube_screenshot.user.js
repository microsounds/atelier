// ==UserScript==
// @name YouTube Screenshot
// @author microsounds
// @version 0.2
// @description Press Ctrl+F11 to save native resolution screenshots from YouTube videos.
// @homepageURL https://microsounds.github.io/notes/dotfiles.htm
// @downloadURL https://raw.githubusercontent.com/microsounds/atelier/master/Userscripts/youtube_screenshot.user.js
// @icon https://img2.apksum.com/f9/com.google.android.youtube/16.01.34/icon.png
// @run-at document-idle
// @match *://www.youtube.com/watch*
// @grant none
// ==/UserScript== */

window.youtube_screenshot = function() {

	/* zero padding timestamps */
	function zeropad(n) {
		return (n > 9) ? n : '0' + n;
	};

	/* get current frame */
	var vid = document.getElementsByClassName('video-stream')[0];
	var cv = document.createElement('canvas');
	cv.width = vid.videoWidth;
	cv.height = vid.videoHeight;
	cv.getContext('2d').drawImage(vid, 0, 0, cv.width, cv.height);

	/*
	 * compose filename from various sources
	 * and download as file
	 */
	var api = 'https://www.youtube.com/oembed?url=' +
		window.location + '&format=json';
	var req = new XMLHttpRequest();
	req.open('GET', api, true);
	req.onload = function() {
		if (this.status == 200) {

			/* title */
			var fname = JSON.parse(this.response).title + ' ';

			/* resolution */
			fname += '(' +
				vid.videoWidth + 'x' +
				vid.videoHeight + ')' + ' ';

			/* current timestamp */
			fname += '[' +
				zeropad((vid.currentTime / 3600) | 0) + ':' +
				zeropad((vid.currentTime / 60)| 0) + ':' +
				zeropad((vid.currentTime % 60) | 0) +
			']';

			/* download screenshot */
			var dl = document.createElement("a");
			dl.download = fname;
			dl.target = '_blank';
			dl.href = cv.toDataURL('image/jpeg', 1.0);
			dl.click();
		}
	};
	req.send();
};

document.addEventListener('keydown', function(e) {
	if (e.ctrlKey && e.key === 'F11') {
		window.youtube_screenshot();
	}
});
