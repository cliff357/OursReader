Feature in OursReader
- User management  <--- now i am here
- push notification
- testflight
- xcode cloud 
- peer to peer exchange data
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
