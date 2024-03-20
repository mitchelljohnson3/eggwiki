// service-worker.js
self.addEventListener('install', (event) => {
	// Cache some resources during the install event
	event.waitUntil(
		caches.open('my-cache-name').then((cache) => {
			return cache.addAll([
				'eggwiki.js',
				'../img/otter_512x512.png',
				'../img/otter_192x192.png',
				'../img/otter-favicon.ico',
				// other assets you want to cache
			])
		})
	)
})

self.addEventListener('fetch', (event) => {
	// Respond with cached resources or fetch from the network
	event.respondWith(
		caches.match(event.request).then((response) => {
			return response || fetch(event.request)
		})
	)
})
