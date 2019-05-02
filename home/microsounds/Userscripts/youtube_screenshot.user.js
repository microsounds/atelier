// ==UserScript==
// @name YouTube Screenshot
// @author microsounds
// @version 0.1
// @description Lets you capture stills from YouTube videos. Images are captured at native resolution.
// @downloadURL https://github.com/microsounds/dotfiles/blob/master/userscripts/youtube_screenshot.user.js
// @run-at document-idle
// @match *://www.youtube.com/*
// @grant none
// ==/UserScript== */

window.youtube_screenshot = function() {
	/* create image */
	var vid = document.getElementsByClassName('video-stream')[0];
	var cv = document.createElement('canvas');
	cv.width = vid.videoWidth;
	cv.height = vid.videoHeight;
	cv.getContext('2d').drawImage(vid, 0, 0, cv.width, cv.height);

	/* download as file */
	var dl = document.createElement("a");
	dl.download = 'Screenshot-' + Math.round((new Date()).getTime() / 1000);
	dl.target = '_blank';
	dl.href = cv.toDataURL('image/jpeg', 1.0);
	document.body.appendChild(dl);
	dl.click();
	document.body.removeChild(dl);
};

