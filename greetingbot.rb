
CLIENT_ID = ARGV[0].to_i
TOKEN = ARGV[1]

require "timeout"

require "discordrb"
require "moji"
require "romaji"

module GreetingCases
	module_function
	
	# once_in_times 3 => 3回に1回の確率でtrueそれ以外はfalse
	def once_in_times times
		rand(times) == 0
	end
	
	class Pattern
		attr_reader :regexp, :skip
		def initialize regexp:, skip: 0, responses:, add_process: ->(s){s}
			@regexp = regexp
			@skip = skip
			@responses = responses
			@add_process = add_process
		end
		def == pair
			pair.regexp == @regexp
		end
		
		MatchData = Struct.new(:match_data, :pattern)
		def match text
			if (match_data = text.match @regexp).nil?
				return nil
			end
			MatchData.new(match_data, self)
		end
		def responses time, match_data
			@responses.call(time, match_data)
		end
		def add_process text
			@add_process.call(text)
		end
	end
	
	def find text
		CASES
			.lazy
			.map{|pattern|pattern.match(Moji.kata_to_hira(Moji.han_to_zen(text, Moji::HAN_KATA)).tr("A-Z", "a-z"))}
			.reject{|md|md.nil?}
			.first
	end
	
	def greeting text="こんにちは"
		md = find(text)
		md.pattern.responses(Time.now, md.match_data).sample
	end
	
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
		when 15
			"おやつ"
		when 16..18
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
		end)
	end
	
	# 6倍の重りがついてしまうので、他を増やすか、.sampleをかけるように
	# といっていたら`ん`の条件分岐のせいでなんとも言えないことに・・うーん
	def add_nobi_or_nn_to_end str
		[
			str,
			str+"ー",
			str+"。"
		]+
		if str[-1] != "ん"
			[
				str+"ん",
				str+"んー",
				str+"ん。"
			]
		else
			[]
		end
	end
	def add_nobi_or_nn_to_end_length
		6
	end
	
	sink = /[ー～、。・,.！？\-=!? 　]+/
	nobi = /([ぁぃぅぇぉっ]|#{sink})+/
	na = ->{
		["ハロロース！"]+
		((rand(2)==0)? ["なー", "なー！", "はにゃー！"] : [])+
		((rand(6)==0)? ["ハロロロース！", "はっにゃにゃー！", "はっにゃー！"] : [])+
		((rand(10)==0)? ["ハムロース！", "はにゃにゃにゃにゃーー！"] : [])+
		((rand(30)==0)? ["豚ロース！"] : [])+
		((rand(100)==0)? ["ロースかつ丼"] : [])+
		[]
	}
	morning = ->{
		["おはようですー", "あ、おはようですー", "おっはー", "おはー", "おはようございますー！"]+
		((rand(4)==0)? ["おはようなぎ"] : [])
		na.()
	}
	daytime = ->{
		["あ、こん", "こんですー", "こんにちはー", "やっはろー", "はろー！", "こんにちはー！"]+
		((rand(4)==0)? ["こんスタンティノープル"] : [])
		((rand(10)==0)? ["cons"] : [])+
		na.()
	}
	night = ->{
		["こんですー", "あ、こんですー", "こんばんはー", "こんばんはー！"]+
		["こんばんわに", "こんばんわんこ"].select{rand(8)==1}+
		na.()
	}
	good_night = ->{
		["おやすみですー", "おやすみなさいですー", "おつです。おやすみですー", "おつかれさまでした！"]+
		["おやすみんみんぜみー"].select{rand(3)==0}
	}
	late_night_drop = ->{
		["長時間お疲れ様ですー！", ".....:zzz:"]+
		good_night.().select{rand(2)==0}
	}
	CASES = [
		Pattern.new(
			regexp: /おっ?#{sink}?は($|#{nobi}|よ)/o,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 4..10
					morning.()
				when 11..12
					["おそよー、もう#{roughly_time_to_s(t)}ですよー", "おそようですー"]+
					na.().select{rand(1)==0}
				when 13..15
					["もう昼過ぎですよー", "おそようですー"]+
					na.().select{rand(1)==0}
				when 16..17
					["もう夕方ですよー", "えっと、今は#{roughly_time_to_s(t)}ですが・・"]+
					na.().select{rand(1)==0}
				else
					["えっと、今は夜ですよ・・？まさか・・・", "えっと、今は#{roughly_time_to_s(t)}ですが・・"]+
					na.().select{rand(1)==0}
				end
			},
		),
		Pattern.new(
			regexp: /
				こ#{nobi}?ん#{nobi}?(に#{nobi}?(#{nobi}|ち)|ち|です)|(^|#{nobi}|#{sink})こん$|
				(^|#{sink})(?<!こー)ど(う|#{nobi}|)も|
				^.{,5}(hello|はろ).{,5}$|
				^(hi#{sink}?|ひ)$|
				^ち[わは]/xo,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 9..16
					daytime.()
				when 17..23, 0..3
					night.()
				else
					morning.()
				end
			}
		),
		Pattern.new(
			regexp: /こ#{nobi}?ん#{nobi}?ば#{nobi}?$|ば#{nobi}?ん#{nobi}?(わ|は|#{nobi})/o,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 16..23, 0..3
					night.()
				when 4..9
					["もう朝ですー", "もう#{roughly_time_to_s(t)}ですよー", "・・・チュンチュン:bird:"]+
					na.().select{rand(2)==0} # na側を減らしてもう朝です側を少し増やす
				else
					["もう昼ですー！", "#{roughly_time_to_s(t)}ですよー！"]+
					na.().select{rand(1)==0}
				end
			},
		),
		Pattern.new(
			regexp: /(では|じゃ(ぁ|あ|))(おつ|乙)|(?<!が)(落|お)ち($|ま|る([わねか]))|^(落|お)ちる(?!に)/o,
			responses: lambda{|t, md|
				case t.hour
				when 21..23, 0..1
					good_night.()
				when 2..5
					late_night_drop.()
				else
					["あ、乙ですー", "おつかれさまでした！", "乙ー", "おつですー！"]
				end
			},
		),
		Pattern.new(
			regexp: /
				((?<![で])寝|(^|#{nobi}|#{sink})ね)(ます|よ|て(?!な|る(?!ー|ね|$))|る(ね(?!る)|#{nobi}|$))|
				お(やす|休)み|(眠|ねむ)([りる]|い(?!け))|💤|zzz/xo,
			skip: 60,
			responses: lambda{|t, md|
				osoyo =
					["おそよー", "おそよーですー", "おそようですー"]+
					add_nobi_or_nn_to_end("まだ#{roughly_time_to_s(t)}ですよ").select{rand(add_nobi_or_nn_to_end_length/2)==0}+ # 2つ分残るように
					na.().select{rand(2)==0}
				case t.hour
				when 20..23, 0..1
					good_night.()+["あ、おやすみですー", "自分はまだ起きてますねー"]
				when 2..8
					late_night_drop.()
				when 9..15
					osoyo
				when 16..19
					osoyo
				end
			},
		),
		Pattern.new(
			regexp: /
				(?<!い)(つか|疲)れ[たま]|
				(?<!ら)お(疲|つか)れ(?!の)|
				(^|は|#{nobi})(乙|おつ)($|で|か|し|#{nobi})/xo,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 9..23
					["おつかれさまです！", "おつかれさまでした！", "おつです"]
				when 0..8
					["遅くまでおつかれさまです！", "遅くまでお疲れ様です！", "おつかれさまです、おやすみです"]
				end
			},
		),
		Pattern.new(
			regexp: /(初|はじ)めまして/o,
			skip: 300, # 挨拶は若干遅れてもやると思うので、skip:は長め
			responses: lambda{|t, md|
				["はっじめまっしてー！", "初めましてー", "はじめましてですー", "よろしくー！", "よろしくですー！"]+
				na.().select{rand(4)==0}
			},
		),
		Pattern.new(
			regexp: /ただい?ま(?![はかと])|(もど|もっど|戻)(り($|だ|で|まし|#{nobi})|#{nobi}?$)/o,
			responses: lambda{|t, md|
				["あ、おかえりですー", "おかえりですー", "おかかー", "おかえりなさいませー！"]+
				["おっかかー", "おかかですー"].select{rand(2)==0}+
				["おかかおいしいよね"].select{rand(5)==0}
			},
		),
		Pattern.new(
			regexp: /
				((^|[にらは]|#{sink}|#{nobi})(?<!で)い|(?<!どうやって|くらい|後|日|で)行)
					(きま|っ?て(くる|き(ま|$))|く(ね|か(?!な|行|い|ら)|#{sink}|#{nobi}|$))(?<!っ)|
				(?<![なの])(といれ|お(手|て)(洗|あら)い|お(花|はな)(摘|つ)み|(雉|きじ)((撃|う)ち|(狩|が|か)り))#{nobi}?#{sink}?$|
				(出|で)かけて/xo,
			responses: lambda{|t, md|
				[
					"あ、いってらっしゃいですー",
					"いってらですー",
					"あーいってらっしゃいですー",
					"いってらっさいー！",
					"いってらっさいですー",
					"いってらっさいですんー"
				]
			},
		),
		Pattern.new(
			regexp: /\A\^\^\#\z/o,
			responses: lambda{|t, md|
				["かわいいにゃ", "かわいいにゃん"]
			},
		),
		Pattern.new(
			regexp: /\Aせや\z/o,
			responses: lambda{|t, md|
				["なー"]
			},
		),
		Pattern.new(
			regexp: /(今|い#{nobi}?ま)#{nobi}?は?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(分|ふん|秒|びょう)/o,
			responses: lambda{|t, md|
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒です")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒・・・です")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒です・・たぶん")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒・・・です・・たぶん")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒・・・たぶん")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒のはず・・です")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒のはず・・です・・・たぶん")+
				add_nobi_or_nn_to_end("今は#{t.hour}時#{t.min}分#{t.sec}秒のはず・・・たぶん")+
				[]
			},
		),
		Pattern.new(
			regexp: /(今|い#{nobi}?ま)#{nobi}?は?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(時|じ|どき)/o,
			responses: lambda{|t, md|
				add_nobi_or_nn_to_end("#{roughly_time_to_s(t)}です").map{|s|s+"\n`#{t}`"}
			},
		),
		Pattern.new(
			regexp: /(今|い#{nobi}?ま|今日|き#{nobi}?ょ(#{nobi}?う)?)#{nobi}?は?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(日|に#{nobi}?ち)/o,
			responses: lambda{|t, md|
				add_nobi_or_nn_to_end("今日は#{t.day}日です").map{|s|s+"\n`#{t}`"}
			},
		),
		Pattern.new(
			regexp: /<@#{CLIENT_ID}>/o,
			responses: lambda{|t, md|
				helpmsg = "コマンドの一覧なら`n.help`"
				case t.hour
				when 2..5
					[
						"ふにゃー・・？。#{helpmsg}をみて・・. . :zzz:", # 半角スペースはディスコード上ではかなり小さく表示されるため
						". . . . :zzz: (もう一度呼んでみましょう)\n(コマンドの一覧は`n.help`で見れます)",
					]
				when 23, 0..10
					["ふにゃー・・？。#{helpmsg}・・. . :zzz:"]
				when 11..22
					["#{greeting}・・。#{helpmsg}だよー"]
				end
			},
		),
		Pattern.new(
			regexp: /^n\.help$/o,
			responses: lambda{|t, md|
				[<<~EOS]
				Command List
				`n.help`
					このコマンドです。
				`n.info`
					このbotのことを教えてくれます。招待URLもこちらから。
				`n.test`
					ボットの自動テストを実行します。
				`n.calc`
					簡単な計算機。ダイズ記法に対応。
					`n.calc bnf`
						BNF式を表示します。
				
				`こん` と入力してみると？
				EOS
			},
		),
		Pattern.new(
			regexp: /^n\.info$/o,
			responses: lambda{|t, md|
				[
					"`@sou7#0094`(soukouki)が作ったbotですー。",
					"おはよう、こんにちは、落ちます、おやすみ、初めまして、ただいま、行ってきます いま何時？ 今日何日？ に対応してます。",
					"`^^#` `せや`", "連続だと反応しないようにしてあるものもあります。",
					"`d[聞く時間]-おはよう`でその時間の返事が聞けます。",
				]+
				["招待URLはこちら！ https://discordapp.com/oauth2/authorize?client_id=394876010438328321&scope=bot&permissions=2048"]*2
			},
			add_process: lambda{|s|
				((rand(2)==0)? greeting+"\n" : "")+s
			},
		),
		Pattern.new(
			regexp: /^n\.calc\s((.|\s)*)$/o,
			responses: lambda do |t, md|
				begin
					require_relative "../dice.rb/dice"
				rescue LoadError
					puts <<~EOS
						`../dice.rb`に https://github.com/soukouki/dice.rb を導入し、
						このファイルの相対パスとして、`../dice.rb/dice` が読み込める状況にしてください。
					EOS
					return [<<~EOS]
						申し訳ありません。現在、計算機能は使用できません。
						どうしても使いたい場合は、botの実行者へ連絡してください。
					EOS
				end
				p text = md[1]
				return [<<~EOS] if text.downcase == "bnf"
					```BNF
					expression := mul_div { ( "+" | "-" ) mul_div }
					mul_div :=  pow { ( "*" | "/" ) pow }
					pow := dice_int | dice_int "^" pow
					dice_int := int_parentheses | int_parentheses "d" int_parentheses
					int_parentheses := int | "(" expression ")"
					int := int_l | ( "+" | "-" ) int_l
					```
				EOS
				begin
					Timeout::timeout(3) do
						formula = Dice.new(text)
						[<<~EOS]
						`#{text.inspect}`の計算結果
						
						最大値 : #{formula.max}
						最小値 : #{formula.min}
						サンプル : #{formula.sample}
						EOS
					end
				rescue Dice::DiceRuntimeError => err
					[<<~EOS]
					`#{text.inspect}`の計算結果
					
					**#{err}**
					式の記述方法が間違っています。
					
					`1d10`
						10面ダイズを一回振ります。
					`1+2` `3-4` `5*6` `7/8`
						見ての通り。
						ただし、小数には対応していないため`7/8`は`0`になります。
					`1/(1d2*2-3)`
						こんな風にもできます。
					`1/(1d2*2-2)`
						このような式は、ゼロ除算の可能性があるため実行できません。
					
					2d2d2は成立しません。(2d2)d2または2d(2d2)と書いてください。
					EOS
				rescue Timeout::Error => err
					[<<~EOS]
					`#{text.inspect}`の計算結果
					
					タイムアウトしました。
					EOS
				end
			end,
		),
		Pattern.new(
			regexp: /^n\.test$/o,
			responses: lambda{|t, md|
				# {"テストする文字列", マッチするかどうか(boolean)}
				testcase = {
					# その他
					"あいう"=>false,
					"こん"=>true,
					"コン"=>true,
					"ｺﾝ"=>true,
					"ほーい"=>false,
					"ただいまから復活薬を破格の..."=>false,
					"なっ"=>false,
					"💤"=>true,
					"zzz"=>true,
					":zzz:"=>true,
					"おーはーよー"=>true,
					# こんなど
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
					# おつかれ系統
					"追いつかれたんじゃ？"=>false,
					"おつかれ"=>true,
					"だったらお疲れって感じ…？"=>false,
					"回復薬の価格が落ちるかな"=>false,
					"もうつかれました"=>true,
					"眠いし落ちる・・"=>true,
					"落ちるに反応したんや…すげえ"=>false,
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
					# テストケース以上
				}
				sel = testcase
					.map{|s,event|[s,event,!!(find(s)) == event]}
					.select{|s,event,r|!r}
				["テスト\n"+
					((sel.empty?)? "すべて成功 全#{testcase.length}パターン" : (sel
						.map{|s,event,r|"#{s}\n\t期待 : #{event}"}
						.join("\n")))]
			},
		),
	]
end



bot = Discordrb::Bot.new(token: TOKEN, client_id: CLIENT_ID)

LastGreetingKey = Struct.new(:channel, :pattern)
LastGreetingValue = Struct.new(:time, :response)
last_greeting = {}

MAX_MSG_LENGTH = 50
MAX_MSG_BACK_QUOTE_COUNT = 2

bot.message{|event|
	print "\r#{Time.now.strftime("%F %T %3N")} @#{event.author.name} : #{event.server.name} # #{event.channel.name} からのメッセージイベント      "
	# 前処理など
	content = event.content
	isdebug = (content =~ /\Ad\d*-/)
	msg = (isdebug)? content.gsub(/\Ad-\d*/){""} : content
	time = if isdebug && (content =~ /\Ad\d+-/)
		Time.local(2000, nil, nil, msg.match(/\Ad(\d+)-/)[1].to_i)
	else
		Time.now
	end
	
	match_data = nil
	# マッチ
	# バグっぽい何かがあるようなので
	begin
		Timeout::timeout 10 do
			match_data = GreetingCases.find(msg)
		end
	rescue Timeout::Error
		puts "*** timeout ***"
		puts msg
	end
	
	Timeout::timeout 10 do
		match_data = GreetingCases.find(Romaji.romaji2kana(msg))
		unless match_data.nil?
			puts "\n#{msg} => ローマ字に変換したらマッチしたよ!"
		end
	end if match_data.nil?
	
	if match_data.nil?
		puts "#{msg} => (マッチしませんでした)" if isdebug
		next
	end
	
	print "\n" # 上のメッセージイベント通知の最後にputsがないため
	
	last_greeting_key = LastGreetingKey.new(event.channel, match_data.pattern)
	last_greeting[last_greeting_key] ||= LastGreetingValue.new(Time.now-match_data.pattern.skip, nil)
	puts content+" : デバッグモード。skip判定を飛ばします" if isdebug
	
	# スキップ処理
	puts "regexp : #{match_data.pattern.regexp}" if isdebug
	
	unless bot.profile.on(event.server).permission?(:send_messages, event.channel)
		puts "#{msg} => (#{event.server.name}の#{event.channel.name}ではbotの権限が足りないためカット)"
		next
	end
	if event.author.bot_account?
		puts "#{msg} => (botからのメッセージのためカット)"
		next
	end
	if msg.length>=MAX_MSG_LENGTH
		puts "#{msg} => (#{MAX_MSG_LENGTH}文字を超えるメッセージのためカット)"
		next
	end
	if msg.count("`") >= MAX_MSG_BACK_QUOTE_COUNT
		puts "#{msg} => (バッククオートが#{MAX_MSG_BACK_QUOTE_COUNT}つ以上含まれるためカット)"
		next
	end
	if (Time.now-match_data.pattern.skip < last_greeting[last_greeting_key].time) && !isdebug
		puts "#{msg} => (#{event.server.name}の#{event.channel.name}では前回の挨拶から#{match_data[:skip]}秒以内のためカット)"
		next
	end
	
	responses = match_data.pattern.responses(time, match_data.match_data)
	response = loop{
		res = responses.sample
		if res!=last_greeting[last_greeting_key].response || responses.length<=1
			break res
		end
	}
	
	# 後処理
	last_greeting[last_greeting_key] = LastGreetingValue.new(Time.now, response)
	puts time
	puts "#{msg}\n=> #{response}"
	event.respond match_data.pattern.add_process(response)
}


bot.ready{|event|bot.game = "挨拶bot|n.help"}

bot.server_create{|event|
	puts "", event.server.name+"に参加しました。"
	(event.server.default_channel||event.server.text_channels.first)
		.send_message(
			<<~EOS
				#{GreetingCases.greeting}。詳しくは`n.help`にて！
				
				This bot doesn't run outside of Japanese text.
			EOS
		)
}


# 初回のfindは正規表現を組み立てたりするので時間がかかるため、起動時に正規表現を組み立てるように
puts GreetingCases.greeting("n.test")

bot.run
