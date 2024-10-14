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
- scrapy , to get web ebook and publish to ebook 


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

2024 6月26號
補番26號日記先！ 今日其實係27號

一口氣做好左個互換data 既功能，開心到，即刻commit
諗起可以順手trigger 埋xcode cloud，點知冇反應

原來係未Review account 既agreement 
 
2024 9月19號
哇。。。原來已經3個月冇update 
呢期太忙了 

依家諗緊去邊個方向行好，應該係整ebook 先，定整send data 好，不如整左push noti 先

2024 10月9號
我既一小步！
整好左push notification
好正，我依家係firebase 既functions 去做

首先我要係電腦setup 好firebase function 既venv 先
然後再用js 寫左個function 負責send push

deploy 完之後就變成我既backend

幾正，成功send到第一個push既感覺好爽 

2024 10月9號
都仲係同一日，但我要分開寫
因為呢個係我做完push之後，突然發現仲未可以commit 住既野黎
係咩黎，就係。。。。
安全

我覺得依家就咁放條link 上網好唔安全，所以我想睇下有冇d咩方法可以保護到隻app

依家試下先！ 
ios 16 出左d新野，應該用得著。

2024 10月11號
極度興奮！！！！
終於
終於成功整到app attest
冇想像中咁難整
但網絡上既資源其實好少

2024 10月13號
係屋企專心沖左成日
好正

整左好多野
主要都係針對firestore 上既野黎，同埋d 制既回彈反應，動畫，好過癮
依家可以隨意加野！ 
黎緊整埋排位，remove ，就差唔多完成呢part！

做埋code refactor，將logic 抽哂出黎放係viewmodel 到，似番樣了 
正


2024 10月14 
成功搞掂app check，所有firestore 上面既資源，都要經app check先做到
同埋可以收埋條link，令到call api 既link 唔洗係public git 出現
v1 既firebase function 淨係得條link ，v2 好好多
