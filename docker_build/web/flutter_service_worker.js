'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "db10c891a78a8754e459d58deb0d9e10",
"assets/AssetManifest.bin.json": "05e2ee67d74b1484a0aba543042f6d31",
"assets/assets/images/crops/apple.png": "d03e80dc3b233bc6129cc5a9b7105e91",
"assets/assets/images/crops/corn.png": "07f3b5a02f5d34346db453107f30c71c",
"assets/assets/images/crops/pepper.png": "04376d805e9092fd572ff90772b0c76c",
"assets/assets/images/crops/potato.png": "17dbc905d523838392e5b9a37fdcdf74",
"assets/assets/images/crops/strawberry.png": "b938c1d2e8ae0af3b0e410501853c7a6",
"assets/assets/images/crops/tomato.png": "533a6fd57e00a3ee4afea9dd8802ad78",
"assets/assets/images/reference_diseases/Apple___Apple_scab.jpeg": "841d0bf56e5ab96bb96b0953c49eb31a",
"assets/assets/images/reference_diseases/Apple___Black_rot.jpeg": "bc53869c8cc94fa805c9f9b2a7a077fe",
"assets/assets/images/reference_diseases/Apple___Cedar_apple_rust.jpeg": "c0208107570b8d61ef94e3e0ef505504",
"assets/assets/images/reference_diseases/Apple___healthy.jpeg": "fe7a3397d602dffb1cd67921d093e0cb",
"assets/assets/images/reference_diseases/Corn_(maize)___Cercospora_leaf_spot%2520Gray_leaf_spot.jpeg": "31c820beaa5779d4060b45ebed70e6af",
"assets/assets/images/reference_diseases/Corn_(maize)___Common_rust_.jpeg": "491536a28f6b2897c2860e410b9a7c68",
"assets/assets/images/reference_diseases/Corn_(maize)___healthy.jpeg": "416ee4dd2ab83b4342f089aff7c959a7",
"assets/assets/images/reference_diseases/Corn_(maize)___Northern_Leaf_Blight.jpeg": "b8d13f6c580961b66c46a798019facd4",
"assets/assets/images/reference_diseases/Pepper,_bell___Bacterial_spot.jpeg": "e51a120ffd5a6fb1fdeccf775a146beb",
"assets/assets/images/reference_diseases/Pepper,_bell___healthy.jpeg": "ba43f0c2e6ae4c66e48fd700edf63cc4",
"assets/assets/images/reference_diseases/Potato___Early_blight.jpeg": "faba91aa5b50fe90d4c550e244ad280d",
"assets/assets/images/reference_diseases/Potato___healthy.jpeg": "99bfddf62ac7e69bb24dd53a8d83f635",
"assets/assets/images/reference_diseases/Potato___Late_blight.jpeg": "068bf4c3d302433c7691b469018c9e03",
"assets/assets/images/reference_diseases/Strawberry___healthy.jpeg": "ebd680674e7b7d497f85799f0faf9b5d",
"assets/assets/images/reference_diseases/Strawberry___Leaf_scorch.jpeg": "fbfb28d21a27ff53611b740da7572df0",
"assets/assets/images/reference_diseases/Tomato___Early_blight.jpeg": "e7cfc1e937b5136f305a019742b4307b",
"assets/assets/images/reference_diseases/Tomato___healthy.jpeg": "d5fd27135f798ba8738d02bae5e1c52b",
"assets/assets/images/reference_diseases/Tomato___Late_blight.jpeg": "c8a9739b962b13ebb4a3a3f7c44db910",
"assets/assets/images/reference_diseases/Tomato___Tomato_Yellow_Leaf_Curl_Virus.jpeg": "70e170eec29fad5d7e48565b9ed73514",
"assets/assets/logo.png": "d1cb8d2b84803a8d4ded02820be9135d",
"assets/assets/remediation/remediation.json": "8c6ba1439ebd454d27e7b3cc28c0498b",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "34a831abcbbc019e90bd7d6a13612b89",
"assets/NOTICES": "dd18236e2f1cf2ac70fd88babdf692ec",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "6ad707a6f708992076962b8244089bb5",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "81036c095c7303500ae3f8d5f2076340",
"/": "81036c095c7303500ae3f8d5f2076340",
"main.dart.js": "b9a8086e254bd75552fdcd91205396de",
"manifest.json": "0030ff64be1c3181710c3014b11018a8",
"version.json": "2b521e10dfa0f067561de489a19d6620"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
