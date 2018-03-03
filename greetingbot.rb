
client_id = ARGV[0].to_i
token = ARGV[1]

require "discordrb"
require "moji"

def find_case cases, text
	cases.find{|hash|
		(hash[:r] =~ Moji.kata_to_hira(text).tr("A-Z", "a-z"))
	}
end

def greeting cases
	find_case(cases, "こん")[:res].(Time.now).sample
end

bot = Discordrb::Bot.new(token: token, client_id: client_id)

def roughly_time_to_s time
	hour = time.hour % 12
	nexthour = (time.hour+1) % 12
	(case time.hour
	when 4..5
		"早朝"
	when 6..9
		"朝"
	when 10..11
		"昼前"
	when 12..14
		"昼"
	when 15..16
		"昼過ぎ"
	when 17..18
		"夕方"
	when 19..23
		"夜"
	when 0..3
		"深夜"
	end + "の" + case time.min
	when 0..1
		"#{hour}時ちょうど"
	when 2..5
		"#{hour}時"
	when 6..11
		"#{hour}時すぎ"
	when 12..18
		"#{hour}時15分"
	when 19..24
		"#{hour}時半まえ"
	when 25..27
		"#{hour}時半"
	when 28..32
		"#{hour}時半ちょうど"
	when 33..35
		"#{hour}時半"
	when 36..41
		"#{hour}時半すぎ"
	when 42..48
		"#{hour}時45分"
	when 49..54
		"#{nexthour}時まえ"
	when 55..58
		"#{nexthour}時"
	when 59..60
		"#{nexthour}時ちょうど"
	end).tr("0-9", "０-９")
end

nobi = /[ー～ぁぃぅぇぉっ！？\-=!?]+/
sink = /[ー～、。・,.！？\-=!?]+/
na = ->{
	["ハロロース！"]+
	((rand(2)==0)? ["なー", "なー！"] : [])+
	((rand(6)==0)? ["ハロロロース！"] : [])+ # すいません調子乗りました
	((rand(10)==0)? ["ハムロース！"] : [])+
	((rand(30)==0)? ["豚ロース！"] : [])+
	((rand(100)==0)? ["ロースかつ丼"] : [])+
	[]
}
morning = ->{
	["おはようですー", "あ、おはようですー", "おっはー", "おはー"]+
	na.()
}
daytime = ->{
	["あ、こん", "こんですー", "こんにちはー", "やっはろー"]+
	((rand(6)==0)? ["cons"] : [])+
	na.()
}
night = ->{
	["あ、こんですー", "こんばんはー"]+
	((rand(4)==0)? ["こんばんわに", "こんばんわんこ"] : [])+ # 大体1/3
	na.()
}
good_night = ->{
	["おやすみですー", "おやすみなさいですー", "おつです。おやすみですー", "おつかれさまでした！"]+
	((rand(3)==0)? ["おやすみんみんぜみー"] : [])
}
late_night_drop = ->{
	good_night.().select{rand(2)==0}+
	["長時間お疲れ様ですー！", ".....:zzz:"]
}
cases = [
	{r:/おっ?は($|#{nobi}|よ)/o, skip:60,
		res:->(t){
			case t.hour
			when 4..10
				morning.()
			when 11..12
				["おそよー、もう#{roughly_time_to_s(t)}ですよー", "おそようですー"]+na.().select{rand(1)==0}
			when 13..15
				["もう昼過ぎですよー", "おそようですー"]+na.().select{rand(1)==0}
			when 16..17
				["もう夕方ですよー", "えっと、今は#{roughly_time_to_s(t)}ですが・・"]+na.().select{rand(1)==0}
			else
				["えっと、今は夜ですよ・・？まさか・・・", "えっと、今は#{roughly_time_to_s(t)}ですが・・"]+na.().select{rand(1)==0}
			end}},
	{r:/
		こん(#{nobi}|に?(ち|#{nobi})|です)|(^|#{nobi}|#{sink})こん$|
		(^|#{sink})ど(う|#{nobi}|)も|
		^.{,5}(hello|はろ).{,5}$|
		^(hi#{sink}?|ひ)$|
		^ち[わは]/xo, skip:60,
		res:->(t){
			case t.hour
			when 9..16
				daytime.()
			when 17..23, 0..3
				night.()
			else
				morning.()
			end}},
	{r:/こんば#{nobi}?$|ばん(わ|は|#{nobi})/o, skip:60,
		res:->(t){
			case t.hour
			when 16..23, 0..3
				night.()
			when 4..9
				["もう朝ですー", "もう#{roughly_time_to_s(t)}ですよー"]+na.().select{rand(1)==0}
			else
				["もう昼ですー！", "#{roughly_time_to_s(t)}ですよー！"]+na.().select{rand(1)==0}
			end}},
	{r:/(では|じゃ(ぁ|あ|))(おつ|乙)|(?<!が)(落|お)ち($|ま|る([わねか]))|^(落|お)ちる/o, skip:0, # 返事のことを考えて
		res:->(t){
			case t.hour
			when 21..23, 0..1
				good_night.()
			when 2..5
				late_night_drop.()
			else
				["あ、乙ですー", "おつかれさまでした！", "乙ー", "おつですー！"]
			end}},
	{r:/
		((?<![で])寝|(^|#{nobi}|#{sink})ね)(ます|よ|て(?!る(?!ー|ね|$))|る(ね(?!る)|#{nobi}|$))|
		お(やす|休)み|(眠|ねむ)([りる]|い(?!け))|💤/xo, skip:60,
		res:->(t){
			case t.hour
			when 20..23, 0..1
				good_night.()+["あ、おやすみですー", "自分はまだ起きてますねー"]
			when 2..8
				late_night_drop.()
			when 9..15
				["えっと、昼ですよ？", "えっと、まだ#{roughly_time_to_s(t)}ですよ・・？"]
			when 16..19
				["えっと、まだ夕方ですよ？", "えっと、まだ#{roughly_time_to_s(t)}ですよ・・？"]
			end}},
	{r:/
		(?<!い)(つか|疲)れ[たま]|
		(?<!ら)お(疲|つか)れ(?!の)|
		(^|は|#{nobi})(乙|おつ)($|で|か|し|#{nobi})/xo, skip:60,
		res:->(t){
			case t.hour
			when 9..23
				["おつかれさまです！", "おつかれさまでした！", "おつです"]
			when 0..8
				["遅くまでおつかれさまです！", "遅くまでお疲れ様です！", "おつかれさまです、おやすみです"]
			end
			}},
	{r:/(初|はじ)めまして/o, skip:300, # 挨拶は若干遅れてもやると思うので、skip:は長め
		res:->(t){["はっじめまっしてー！", "初めましてー", "はじめましてですー"]+na.().select{rand(2)==0}}},
	{r:/ただい?ま(?![はかと])|(もど|もっど|戻)(り($|だ|で|まし|#{nobi})|#{nobi}?$)/o, skip:0,
		res:->(t){["あ、おかえりですー", "おかえりですー", "おかかー"]}},
	{r:/
		((^|[にらは]|#{sink}|#{nobi})(?<!で)い|(?<!どうやって|くらい|後|日|で)行)
			(き|くる|っ?て(くる|き(ま|$))|く(?![けにらとつの]|か(?!な(?!#{nobi})|$|#{sink}|#{nobi})))|
		(といれ|お(手|て)(洗|あら)い|お(花|はな)(摘|つ)み|(雉|きじ)((撃|う)ち|(狩|が|か)り))#{nobi}?#{sink}?$|
		(出|で)かけて/xo, skip:0,
		res:->(t){["あ、いってらっしゃいですー", "いってらですー", "あーいってらっしゃいですー"]}},
	{r:/\A\^\^\#\z/o, skip:0,
		res:->(t){["かわいいにゃ"]}},
	{r:/\Aせや\z/o, skip:0,
		res:->(t){["なー\n\n\t・・・これでいい？"]}},
	{r:/(今|い#{nobi}?ま)#{nobi}?は?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(時|じ)/o, skip:0,
		res:->(t){["#{roughly_time_to_s(t)}ですー\n`#{t}`"]}},
	{r:/(今|い#{nobi}?ま|今日|き#{nobi}?ょ#{nobi}?う)は?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(日|に#{nobi}?ち)/o, skip:0,
		res:->(t){["今日は#{t.day}日ですー\n`#{t}`"]}},
	{r:/<@#{client_id}>/o, skip:0, # メンション
		res:->(t){
			helpmsg = "コマンドの一覧なら`n.help`だよー"
			case t.hour
			when 2..5
				[
					"ふにゃー・・？\n#{helpmsg}をみて・・. . :zzz:", # 半角スペースはディスコード上ではかなり小さく表示されるため
					". . . . :zzz: (もう一度呼んでみましょう)\n(コマンドの一覧は`n.help`で見れます)",
				]
			when 23, 0..10
				["ふにゃー・・？\n#{helpmsg}・・. . :zzz:"]
			when 11..22
				["こんー・・\n#{helpmsg}"]
			end}},
	{r:/^n\.help$/o, skip:0,
		res:->(t){[
			"#{greeting(cases)} Command List\n"+
			"`n.help` : このコマンドです。\n"+
			"`n.info` : このbotのことを教えてくれます。招待URLもこちらから。\n"+
			"`n.test` : ボットの自動テストを実行します。\n"+
			"\n`こん` と入力してみると？"]}},
	{r:/^n\.info$/o, skip:0,
		res:->(t){
			(
				[
					"`@sou7#0094`(soukouki)が作ったbotですー。",
					"おはよう、こんにちは、落ちます、おやすみ、初めまして、ただいま、行ってきます いま何時？ 今日何日？ に対応してます。",
					"`^^#` `せや`", "連続だと反応しないようにしてあるものもあります。",
					"`d-数字おはよう`でその時間の返事が聞けます。",
				]+
				["招待URLはこちら！ https://discordapp.com/oauth2/authorize?client_id=394876010438328321&scope=bot&permissions=2048"]*2
			)
				.map{|s|((rand(2)==0)? greeting(cases)+"。" : "")+s} # TODO : 連続排除がうまく働かなくなる。後処理をつければいいかな？
		}},
	{r:/^n\.test$/o, skip:0,
		res:->(t){
			puts "(テスト開始)"
			# {"テストする文字列", マッチするかどうか(boolean)}
			testcase = {
				# その他
				"あいう"=>false,
				"こん"=>true,
				"ほーい"=>false,
				"ただいまから復活薬を破格の..."=>false,
				"なっ"=>false,
				# こんなど
				"かばんさんこんですー"=>true,
				"アイコン"=>false,
				"コンストラクタ"=>false,
				"どうもー"=>true,
				"ちわー"=>true,
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
				# おつかれ系統
				"追いつかれたんじゃ？"=>false,
				"おつかれ"=>true,
				"だったらお疲れって感じ…？"=>false,
				"回復薬の価格が落ちるかな"=>false,
				"もうつかれました"=>true,
				"眠いし落ちる・・"=>true,
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
				# テストケース以上
			}
			sel = testcase
				.map{|s,e|[s,e,!!(find_case(cases, s)) == e]}
				.select{|s,e,r|!r}
			["テスト\n"+
				((sel.empty?)? "すべて成功 全#{testcase.length}パターン" : (sel
					.map{|s,e,r|"#{s}\n\t期待 : #{e}"}
					.join("\n")))]
		}},
]

# スキップ用前処理
cases.each{|h|h[:last_greeting] = {}; h[:last_time_res] = {}}

bot.message{|e|
	msg = e.content
	isdebug = msg =~ /\Ad-/
	hour = (msg =~ /\Ad-\d+/)? msg.match(/\Ad-(\d+)/)[1].to_i : nil
	msg = msg.gsub(/\Ad-\d*/){""} if isdebug
	puts msg+" : デバッグモード。skip判定を飛ばします" if isdebug
	
	match = find_case(cases, msg)
	puts "\nregexp : #{match[:r]}" if isdebug && !!match
	
	if match.nil?
		puts "#{msg} => (マッチしませんでした)" if isdebug
		next
	end
	
	# これより後にしないといらない時まで出力するため
	# 上の部分が時間がかかるようになって来たらまた考える
	unless bot.profile.on(e.server).permission?(:send_messages, e.channel)
		puts "#{msg} => (#{e.server.name}の#{e.channel.name}ではbotの権限が足りないためカット)"
		next
	end
	if match[:last_greeting].key?(e.channel.id) && (!isdebug && (Time.now-match[:last_greeting][e.channel.id]) <= match[:skip])
		puts "#{msg} => (#{e.server.name}の#{e.channel.name}では前回の挨拶から#{match[:skip]}秒以内のためカット)"
		next
	end
	if e.author.bot_account?
		puts "#{msg} => (botからのメッセージのためカット)"
		next
	end
	if msg.length>50
		puts "#{msg} => (50文字を超えるメッセージのためカット)"
		next
	end
	if msg.count("`") >= 2
		puts "#{msg} => (バッククオートが2つ以上含まれるためカット)"
		next
	end
	
	match[:last_greeting][e.channel.id] = Time.now
	
	nowtime = (isdebug && hour)? Time.local(2000, nil, nil, hour) : Time.now
	puts "#{nowtime}として実行"
	ress = match[:res].(nowtime)
	res = loop{
		res = ress[rand(0..ress.length-1)]
		if res!=match[:last_time_res][e.channel.id] || ress.length<=1
			break res
		end
	}
	match[:last_time_res][e.channel.id] = res
	
	puts msg+" => "+res
	e.respond res
}

bot.ready{|e|bot.game = "挨拶bot|n.help"}

bot.server_create{|e|
	(e.server.default_channel||e.server.text_channels.first)
		.send_message(
			"#{find_case(cases, "こんにちは")[:res].(Time.now).sample}。詳しくは`n.help`にて！\n\n"+
			"This bot does job only in Japanese text."
		)
}

bot.run :async

puts find_case(cases, "n.test")[:res].(Time.now).sample # 正規表現を作るのにある程度の時間がかかるため

bot.sync
