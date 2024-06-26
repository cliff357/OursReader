Feature in OursReader
- User management  
- testflight
- xcode cloud 
- peer to peer exchange data <--- now i am here
- push notification
- interactive widget 
- live activities
- account deletion
- setup fastlane and github action 


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

2024 5月25號
我發現我需要一個可以隨時彈出既error dialog
以下係幾點想隨時做到既要求
1. 隨時都call 得既彈出式error alert
2. 有個handler call佢，只要比message佢就可以隨時彈出黎
3. 盡可能減少callback hell

2024 5月27號
成功啦！！！！！！係chatgpt 4o 既幫助下
終於實現到2部電話用MultipeerConnectivity 黎exchange data
雖然寫得唔靚，但起碼做到個效果了，commit！ 然後就睇下可以點樣寫番靚仔d

依家kick住既問題係雙方一connected 就會delay 1 秒先會send msg
以下係2個解決方法
1. display loading，交換完就dismiss loading 
2. 真係detect到connected，先會交換data 
 

2024 6月2號
wow 用xcode cloud build app 又幾正，幾經辛苦 
終於搞掂哂d 問題，成功係xcode cloud 出build 上testflight，正

順手加埋相片display 係welcome page
