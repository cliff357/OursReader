Feature in OursReader
- User management  
- peer to peer exchange data <--- now i am here
- account deletion
- push notification
- testflight
- xcode cloud 
- interactive widget 
- live activities


Function
- Firebase
  - login / reg / google sign-in / apple sign-in
  - push notification
  - firestore database
- Create / update widget
- Custom content in push notifications
- User can send push by one click in widget
- User can exchange their name card by near device (just like Bump)

＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

2024 4月29號 
其實可以當呢到係開發日記？

由於呢個project 需要firestore database , 所以好神奇地去左學點樣setup firestore，然後比我發現到原來google 有得setup security rules
然後再發現有d 好細既pj 入面，d人會咁寫
allow read, write: 
    if  request.time < timestamp.date(2050, 1, 1); 

咁其實等於冇set 到任何rules 


2024 5月7號
今日終於又抽到lunch time 番黎做野
我發現用copilot 去寫真係快勁多
例如想加一個check firestore user exist
copilot真係gen到一個好fit既function出黎

今日完成好左app層面對firestore 既setup！
包括create完user，會加data落firestore 
可以開始向dashboard推進

下一個思考既位係，我應唔應該花時間去整靚ui ，定做好左功能先呢？ 


2024 5月8號
好！ 我決定唔搞UI住，太想研究下點樣處理近距離交換data既問題
決定用 MultipeerConnectivity

功能上其實只係需要2部機好近，然後互加對方
如果可以做到唔洗approve都加到好友，就perfect

試一試先 
決定將 peer to peer exchange data 作為下一個feature



2024 5月24號
去左專心考車一段時間
番黎！好想盡快可以交換到data，咁就可以send push！

