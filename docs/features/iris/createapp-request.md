curl 'https://appstoreconnect.apple.com/iris/v1/apps' \
-H 'accept: application/vnd.api+json' \
-H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7' \
-H 'content-type: application/vnd.api+json' \
-b 'dssf=1; dssid2=fabb3149-d347-4666-abaf-bbc8fa3992df; as_sfa=Mnx1c3x1c3x8ZW5fVVN8Y29uc3VtZXJ8aW50ZXJuZXR8MHwwfDE; acn01=0BejDwHEUjEqAFC0JzX8J2ER/BwzZBmJOChyqPBZ4QABxxMIqk9r; XID=b5e33346b5a78791a258685b696a8f81; s_vi=[CS]v1|34DC815EE52A41DF-600012E9A34A181C[CE]; s_fid=5D3A4CA64B0369AC-0D3FF4676AE6D5CD; geo=CN; s_cc=true; s_sq=%5B%5BB%5D%5D; dslang=US-EN; site=USA; myacinfo=DAWTKNV323952cf8084a204fb20ab2508441a07d02d37004795fa4871d2e57c0c33409828a43a844d8bec29076f7ed4b4c8ae76d209028540ff4764b20024ff54158fbee34e64499ce656871644995243f356b5a1c1155d8bafb453835489c3c94e0a18a6ff1f3ad7c2714d7b8821a92adae3a2a870a7624f893c1617a83786aaed00a2176f84e1b472d5d1dfc6419daa7b6945a363ab84607bdeb63fa97c6d2c9b0b73c9d374f3c81cd1b216f1fe8b69845b76f3ddd0f2bcaa70dbbac4be3cc6cf93f7984f72ba2d0c3503134f62d9432266a95b6057cedfe4244c2afd2b74698892b9a2bc67f243fb9fc092cc39a3320be37665a1f1a66adf54843d690899343b367680f01109a99e153300942ff3d431df5dd795902a459af184a2e76db66e14bc70db81a082c0c5099054d7a24d16d3ffa9ae8b6ad139009c722f7411d1a5ec9c4dbae661662a6573b934b75597f3e1b59ce7a80d3e5af5834b0927b2f5b6069456e1641975a496c8219174ecc291035617655381fa8af808bc81a4fd4ebf4ba5bcf3d12299b45711c40b91eb49ef30dc82ea9968f9071ff2269bca77008007478764590f8179df648ebf4e26278fa8b75ebbb41dd35c7187fba4c661e466006035bb4892086f6369638cceff135fc56c89efa147aad2bd44697711cffaecff24278ab963eb8119d937365c417f40cbf3035d0875a2fc966a67714d80cad41681b0f160ccd26b98d85e1182353d921e3a6be1bd8585a47V3; dc=pv; itctx=eyJjcCI6ImQ0ZjJmYTEyLTVmN2YtNGYxNS1hMTQyLWIzOGFhMWZhNjA2MiIsImRzIjo0NjU1MjU0MjcsImV4IjoiMjAyNi0zLTIxIDExOjIzOjMifQ|olgnsf4flh0l2elmdb315ui39u|HtZBs39Mq9YvrM-7B69TpkTC_YQ; itcdq=0; dqsid=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NzQwNjMzODMsImp0aSI6IkRsMHpYeWRoOWFXQTVVcFA2a2ZsMmcifQ.VfuH41pFjrRGjCzMEBaNnp-EiA9cd4_InEBdC9I6Lk4; wosid=ttZtqoLjsu6YP2F3VjKobg; woinst=220533' \
-H 'origin: https://appstoreconnect.apple.com' \
-H 'priority: u=1, i' \
-H 'referer: https://appstoreconnect.apple.com/apps' \
-H 'sec-ch-ua: "Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"' \
-H 'sec-ch-ua-mobile: ?0' \
-H 'sec-ch-ua-platform: "macOS"' \
-H 'sec-fetch-dest: empty' \
-H 'sec-fetch-mode: cors' \
-H 'sec-fetch-site: same-origin' \
-H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
-H 'x-csrf-itc: [asc-ui]' \
--data-raw '{"data":{"type":"apps","attributes":{"sku":"com.onegai.asccli.demo1","primaryLocale":"en-US","bundleId":"onegai.BriRus.WaterPict"},"relationships":{"appStoreVersions":{"data":[{"type":"appStoreVersions","id":"${store-version-ios}"}]},"appInfos":{"data":[{"type":"appInfos","id":"${new-appInfo-id}"}]}}},"included":[{"type":"appStoreVersions","id":"${store-version-ios}","attributes":{"platform":"IOS","versionString":"1.0"},"relationships":{"appStoreVersionLocalizations":{"data":[{"type":"appStoreVersionLocalizations","id":"${new-iosVersionLocalization-id}"}]}}},{"type":"appStoreVersionLocalizations","id":"${new-iosVersionLocalization-id}","attributes":{"locale":"en-US"}},{"type":"appInfos","id":"${new-appInfo-id}","relationships":{"appInfoLocalizations":{"data":[{"type":"appInfoLocalizations","id":"${new-appInfoLocalization-id}"}]}}},{"type":"appInfoLocalizations","id":"${new-appInfoLocalization-id}","attributes":{"locale":"en-US","name":"ASC CLI"}}]}'


curl 'https://appstoreconnect.apple.com/iris/v1/ascBundleIds?limit=2000' \
-H 'accept: application/vnd.api+json' \
-H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7' \
-H 'content-type: application/vnd.api+json' \
-b 'dssf=1; dssid2=fabb3149-d347-4666-abaf-bbc8fa3992df; as_sfa=Mnx1c3x1c3x8ZW5fVVN8Y29uc3VtZXJ8aW50ZXJuZXR8MHwwfDE; acn01=0BejDwHEUjEqAFC0JzX8J2ER/BwzZBmJOChyqPBZ4QABxxMIqk9r; XID=b5e33346b5a78791a258685b696a8f81; s_vi=[CS]v1|34DC815EE52A41DF-600012E9A34A181C[CE]; s_fid=5D3A4CA64B0369AC-0D3FF4676AE6D5CD; geo=CN; s_cc=true; s_sq=%5B%5BB%5D%5D; dslang=US-EN; site=USA; myacinfo=DAWTKNV323952cf8084a204fb20ab2508441a07d02d37004795fa4871d2e57c0c33409828a43a844d8bec29076f7ed4b4c8ae76d209028540ff4764b20024ff54158fbee34e64499ce656871644995243f356b5a1c1155d8bafb453835489c3c94e0a18a6ff1f3ad7c2714d7b8821a92adae3a2a870a7624f893c1617a83786aaed00a2176f84e1b472d5d1dfc6419daa7b6945a363ab84607bdeb63fa97c6d2c9b0b73c9d374f3c81cd1b216f1fe8b69845b76f3ddd0f2bcaa70dbbac4be3cc6cf93f7984f72ba2d0c3503134f62d9432266a95b6057cedfe4244c2afd2b74698892b9a2bc67f243fb9fc092cc39a3320be37665a1f1a66adf54843d690899343b367680f01109a99e153300942ff3d431df5dd795902a459af184a2e76db66e14bc70db81a082c0c5099054d7a24d16d3ffa9ae8b6ad139009c722f7411d1a5ec9c4dbae661662a6573b934b75597f3e1b59ce7a80d3e5af5834b0927b2f5b6069456e1641975a496c8219174ecc291035617655381fa8af808bc81a4fd4ebf4ba5bcf3d12299b45711c40b91eb49ef30dc82ea9968f9071ff2269bca77008007478764590f8179df648ebf4e26278fa8b75ebbb41dd35c7187fba4c661e466006035bb4892086f6369638cceff135fc56c89efa147aad2bd44697711cffaecff24278ab963eb8119d937365c417f40cbf3035d0875a2fc966a67714d80cad41681b0f160ccd26b98d85e1182353d921e3a6be1bd8585a47V3; dc=pv; itctx=eyJjcCI6ImQ0ZjJmYTEyLTVmN2YtNGYxNS1hMTQyLWIzOGFhMWZhNjA2MiIsImRzIjo0NjU1MjU0MjcsImV4IjoiMjAyNi0zLTIxIDExOjIzOjMifQ|olgnsf4flh0l2elmdb315ui39u|HtZBs39Mq9YvrM-7B69TpkTC_YQ; itcdq=0; dqsid=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NzQwNjMzODMsImp0aSI6IkRsMHpYeWRoOWFXQTVVcFA2a2ZsMmcifQ.VfuH41pFjrRGjCzMEBaNnp-EiA9cd4_InEBdC9I6Lk4; wosid=4ifM6YB6wmM9BSvROsX6bM; woinst=220978' \
-H 'priority: u=1, i' \
-H 'referer: https://appstoreconnect.apple.com/apps' \
-H 'sec-ch-ua: "Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"' \
-H 'sec-ch-ua-mobile: ?0' \
-H 'sec-ch-ua-platform: "macOS"' \
-H 'sec-fetch-dest: empty' \
-H 'sec-fetch-mode: cors' \
-H 'sec-fetch-site: same-origin' \
-H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
-H 'x-csrf-itc: [asc-ui]'