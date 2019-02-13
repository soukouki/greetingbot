
module GreetingCases
	# {"テストする文字列", マッチするかどうか(boolean)}
	TEST_PATTERN = {
		# その他
		"あいう"=>false,
		"こん"=>true,
		"コン"=>true,
		"ｺﾝ"=>true,
		"ほーい"=>false,
		"ただいまから復活薬を破格の..."=>false,
		"なっ"=>false,
		"ただいま△△です"=>false, # ○だとゼロとかぶる
		"はっじめましてー"=>true,
		"お前を消す方法"=>true,
		
		# こんなど
		"おーはーよー"=>true,
		"おはざまー"=>true,
		"かばんさんこんですー"=>true,
		"アイコン"=>false,
		"コンストラクタ"=>false,
		"どうもー"=>true,
		"ちわー"=>true,
		"ども"=>true,
		"コードも"=>false,
		"どーもー"=>true,
		"どうもですー"=>true,
		"あ、どうもですー"=>true,
		"あ、どもども"=>true,
		"こ！ん！ば！ん！は！"=>true,
		"電子そろばん？"=>false,
		"こんにゃく"=>false,
		"こんどは"=>false,
		"あ、ばんはー"=>true,
		"ばん！"=>true,
		"こんばんは"=>true,
		"こんばんは～"=>true,
		"ban."=>false,
		"どうもクライアント側のバグのようなんです"=>false,
		"ハロウィン"=>false,
		"どうもくん"=>false,
		"どうもり"=>false,
		"どうもです"=>true,
		"こんー"=>true,
		"ばん"=>true,
		"ban"=>false,
		"あ、こんー"=>true,
		"こんな機能を"=>false,
		
		# 寝ます系統
		"ほどほどで寝ますｗ"=>false,
		"寝ます"=>true,
		"ねるね"=>true,
		"ねるねー"=>true,
		"ねるねるねるね"=>false,
		"チャンネル"=>false,
		"ついでに宣伝もかねて(ぉぃ"=>false,
		"眠いので諦める"=>true,
		"眠いし諦め"=>true,
		"ねむいのであきらめ・・"=>true,
		"眠いけど頑張る"=>false,
		"あー、諦めた"=>false,
		"とりあえず寝てない人は背が低いイメージ・・"=>false,
		"💤"=>true,
		"zzz"=>true,
		":zzz:"=>true,
		"そろそろ寝るかなぁ"=>true,
		"永久にnagizzzです"=>false,
		
		# おつかれ系統
		"追いつかれたんじゃ？"=>false,
		"おつかれ"=>true,
		"だったらお疲れって感じ…？"=>false,
		"回復薬の価格が落ちるかな"=>false,
		"もうつかれました"=>true,
		"眠いし落ちる・・"=>true,
		"落ちるに反応したんや…すげえ"=>false,
		"そしておつー"=>true,
		"嘘をつかれた"=>false,
		"うそをつかれました"=>false,
		
		# 行ってきます系統
		"奪い返しに行くからな"=>false,
		"あ、んじゃそっちにいくね"=>true,
		"飯落ち"=>true,
		"行くか行かないか"=>false,
		"あー、行く"=>true,
		"あー、いく"=>true,
		"ではいってきます"=>true,
		"行くかぁ・・"=>true,
		"いくかぁ・・"=>true,
		"行くね"=>true,
		"いくね"=>true,
		"ん、行くー"=>true,
		"ん、いくー"=>true,
		"あ、了解。んじゃ今から行きますね"=>true,
		"お風呂行ってきます"=>true,
		"んじゃ自分がそっちに行きますね"=>true,
		"あー、明日いくか・・"=>false,
		"あ、明後日いくのね。了解"=>false,
		"あ、行くー"=>true,
		"あ、いくー"=>true,
		"昨日行ったところはよかったよね"=>false,
		"昨日行く約束だったよね？"=>false,
		"明日行く約束なんだけどね"=>false,
		"行ってきます"=>true,
		"イッテルビウム"=>false,
		"行く"=>true,
		"いく"=>true,
		"マイク"=>false,
		"マイクラ"=>false,
		"マイクロソフト"=>false,
		"いくら"=>false,
		"敵から搾り取っていくスタイル()"=>false,
		"モザイク"=>false,
		"きんいろモザイク"=>false,
		"そりゃ行くにきまってるよ"=>false,
		"そりゃいくにきまってるよ"=>false,
		"あっ、今から行くね"=>true,
		"あっ、今からいくね"=>true,
		"持っていく"=>false,
		"とっていきますね"=>false,
		"テイクアウト"=>false,
		"そして全員あてメンションが無事行くと・・・"=>false,
		"いくつかの方法で調べてみる"=>false,
		"年間にすると5000円くらい行くか..."=>false,
		"月曜は学校行くけど"=>false,
		"コンビニ行ってくる"=>true,
		"一週間後行くかなぁ"=>false,
		"一週間後に行くかなぁ"=>false,
		"コンビニに行くかなぁ・・それとも行かないかなぁ"=>false,
		"うーん行くか"=>true,
		"やっと行くのか"=>false,
		"やっと○○に行くのか"=>false,
		"コンビニに行くか"=>true,
		"コンビニにいってくる"=>true,
		"これでいくわ"=>false,
		"車で行ってくる"=>false,
		"車で出かけてくる"=>true,
		"○○ちゃんとお出かけー!"=>false,
		"でかけてきますん"=>true,
		"フラップ式行き先表示"=>false,
		"新宮行くやつ"=>false,
		"千葉行き"=>false,
		"素敵な提督で嬉しいのね。伊十九なの。そう、イクって呼んでもいいの！"=>false,
		"イクイクイク"=>false,
		"唐突のお手洗い"=>false,
		
		# 今何日?何時?
		"きょーうーはーなーんーにーちーでーすーかー！"=>true,
		"いーまーなーんーにーちーだったーっけー"=>true,
		"いーまーはーなーんーにーちーでーすーかー！"=>true,
		"きょーはなんにぃち"=>true,
		"今 は何 時 です？"=>true,
		"今何分？"=>true,
		"いまなんどきだい？"=>true,
		"いまは何秒？"=>true,
		"今の時間は1時です"=>false,
		"今の時間は一時"=>false,
		"今は一時、なので"=>false,
		"今の時間は・・・"=>true,
		"今は一時？"=>true,
		"えーっと、今の時間は？"=>true,
		"あー。今は11時?"=>true,
		"今十一時ー"=>false,
		"今は3時です"=>false,
		"いま？3時"=>false,
		"三時だよー"=>false,
		"三時に"=>false,
		
		# クリスマス
		"メリークリスマス"=>true,
		"メリクリ"=>true,
		"メリクリ～！"=>true,
		"メリクリウス"=>false,
		"Merry X'mas"=>true,
		"Merry Christmas"=>true,
		
		# 新年
		"あけましておめでとうございます"=>true,
		"明けましておめでとうございます"=>true,
		"あけおめ"=>true,
		"あけおめー！"=>true,
		"ハッピーニューイヤー"=>true,
		"ハッピーニューイヤー！"=>true,
		"Happy New Year"=>true,
		"新年、明けましておめでとうございます。"=>true,
		
		# n.ruby
		"n.ruby help"=>true,
		"n.ruby Aaa"=>true,
		"n.ruby Aaa::Bbb"=>true,
		"n.ruby Aaa::Bbb::Ccc"=>true,
		"n.ruby Aaa.bb"=>true,
		"n.ruby Aaa::Bbb.cc"=>true,
		"n.ruby Aaa#bb"=>true,
		"n.ruby Aaa::Bbb#cc"=>true,
		"n.ruby Aaa#+"=>true,
		"n.ruby Aaa#+@"=>true,
		"n.ruby Aaa#`"=>true,
		"n.ruby Aaa.#bb"=>true,
		"n.ruby $1"=>true,
		"n.ruby $1234"=>true,
		"n.ruby $LOAD_PATH"=>true,
		"n.ruby $--"=>false,
		"n.ruby $"=>false,
		"n.ruby $-aa"=>false,
	}.merge(
		["$!", "$\"", "$$", "$&", "$'", "$*", "$+", "$,", "$-0", "$/", "$-F", "$;", "$:", "$.", "$<", "$=", "$>", "$?", "$@", "$\\", "$`", "$~"]
			.map{|s|["n.ruby #{s}", true]}
			.to_h
	)
	# テストケース以上
end
