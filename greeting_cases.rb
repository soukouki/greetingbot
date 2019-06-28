
module GreetingCases
	module_function
	
	refine Array do
		# select{rand(n)==0}
		def select_rand n
			self.select{rand(n) == 0}
		end
	end
	refine Time do
		def weekday
			%w[日 月 火 水 木 金 土][wday]
		end
		
		def roughly_time_slot
			case hour
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
			end
		end
		def roughly_min
			hour12 = hour % 12
			nexthour12 = (hour+1) % 12
			case min
			when 0..1
				"#{hour12}時ちょうど"
			when 2..5
				"#{hour12}時"
			when 6..11
				"#{hour12}時すぎ"
			when 12..18
				"#{hour12}時15分"
			when 19..24
				"#{hour12}時半まえ"
			when 25..27
				"#{hour12}時半"
			when 28..32
				"#{hour12}時半ちょうど"
			when 33..35
				"#{hour12}時半"
			when 36..41
				"#{hour12}時半すぎ"
			when 42..48
				"#{hour12}時45分"
			when 49..54
				"#{nexthour12}時まえ"
			when 55..58
				"#{nexthour12}時"
			when 59..60
				"#{nexthour12}時ちょうど"
			end
		end
		def roughly_time
			roughly_time_slot + "の" + roughly_min
		end
	end
	using self
	
	class Pattern
		attr_reader :regexp, :skip
		def initialize regexp:, skip: 20, responses:, add_process: ->(s, t){s}
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
		def add_process text, time
			@add_process.call(text, time)
		end
	end
	
	def find text
		[
			text,
			Moji.kata_to_hira(Moji.han_to_zen(text, Moji::HAN_KATA)).tr("A-Z", "a-z"),
			Romaji.romaji2kana(text),
		]
			.lazy
			.map do |text_pattern|
				CASES
					.lazy
					.map{|pattern|pattern.match(text_pattern)}
					.reject{|md|md.nil?}
					.first
			end
			.reject{|md|md.nil?}
			.first
	end
	
	def greeting text="こんにちは"
		md = find(text)
		md.pattern.responses(Time.now, md.match_data).sample
	end
	
	
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
	
	sink = /[ー～、。・,.！？\-=!? 　]+/
	nobi = /([ぁぃぅぇぉっ]|#{sink})+/
	christmas = ->(t){
		["メリクリ～！", "メリクリ！", "メリークリスマス！"]+
		["ケーキ！ケーキ！チキン！チキン！"].select_rand(5)
	}
	new_year = ->(t){
		["あけおめ～！", "あけましておめでとー！", "ハッピニューイヤー！", "新年明けましておめでとうございます！\n今年もよろしくおねがいします！"]
	}
	na = ->(t){
		["ハロロース！"]+
		["なー", "なー！", "はにゃー！"].select_rand(2)+
		["ハロロロース！", "はっにゃにゃー！", "はっにゃー！"].select_rand(8)+
		["ハムロース！", "はにゃにゃにゃにゃーー！"].select_rand(15)+
		["豚ロース！", "ハロロースかつ丼"].select_rand(150)+
		((christmas.(t) if t.month==10 && t.day==31) || []) +
		((new_year.(t) if (t.month==12 && t.day==31 && t.hour > 20) or (t.month==1 && t.day==1)) || [])+
		[]
	}
	morning = ->(t){
		["おはようですー", "あ、おはようですー", "おっはー", "おはー", "おはようございますー！"]+
		["おはようなぎ"].select_rand(4)+
		na.(t)
	}
	daytime = ->(t){
		["あ、こん", "こんですー", "こんにちはー", "やっはろー", "はろー！", "こんにちはー！", "こんちはー！"]+
		["こんスタンティノープル"].select_rand(4)+
		["cons"].select_rand(10)+
		na.(t)
	}
	night = ->(t){
		["こんですー", "あ、こんですー", "こんばんはー", "こんばんはー！"]+
		["こんばんわに", "こんばんわんこ"].select_rand(8)+
		na.(t)
	}
	good_night = ->(t){
		["おやすみですー", "おやすみなさいですー", "おつです。おやすみですー", "おつかれさまでした！"]+
		["おやすみんみんぜみー"].select_rand(3)
	}
	late_night_drop = ->(t){
		["長時間お疲れ様ですー！", ".....:zzz:", "よ、夜遅くまでお疲れ様ですー・・・"]+
		good_night.(t).select_rand(2)
	}
	desu = [
		"です", "です！", "ですー", "ですー！", "！"
	]
	
	CASES = [
		Pattern.new(
			# おはよう
			regexp: /
				(?<!ばい)おっ?#{sink}?は($|#{nobi}|よ|ざ)|
				むにゃ$|(むにゃ){2,}/xo,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 4..10
					morning.(t)
				when 11..15
					["もう#{t.roughly_time}ですよー"].select_rand(3)+
					["もう#{t.roughly_time_slot}ですよー", "おそようですー"]+
					na.(t).sample(3)
				when 16..17
					["えっと、今は#{t.roughly_time}ですが・・"].select_rand(3)+
					["もう夕方ですよー", "えっと、今は#{t.roughly_time_slot}ですが・・"]+
					na.(t).sample(3)
				else
					["えっと、今は#{t.roughly_time}ですが・・"].select_rand(3)+
					["えっと、今は夜ですよ・・？", "えっと、今は#{t.roughly_time_slot}ですが・・","もう夜ですよー！"]+
					na.(t).sample(3)
				end
			},
		),
		Pattern.new(
			# こんにちは
			regexp: /
				(?<!あい)こ#{nobi}?ん#{nobi}?(に#{nobi}?(#{nobi}|ち)|ち|です)|(^|#{nobi})こん#{nobi}?$|
				(^|#{sink})(?<!こー)ど(う|#{nobi}|)も(#{nobi}|[どで]|$)|
				\A.{,3}(hello|はろ(?!うぃん|り)).{,3}\Z|
				\A.+はろー#{nobi}\Z|
				\Aはろー.+\Z|
				^(おっす)+$|
				\A(hi#{sink}?|ひ)\Z|
				^ち[わは]/xo,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 9..16
					daytime.(t)
				when 17..23, 0..3
					night.(t)
				when 4..6
					morning.(t).select_rand(3)+
					morning.(t).select_rand(3).map{|s|s+"早起きはいいぞ！"}+
					morning.(t).select_rand(6).map{|s|s+"早起きは三文の得！"}
				else
					morning.(t)
				end
			}
		),
		Pattern.new(
			# こんばんは
			regexp: /
				こ#{nobi}?ん#{nobi}?ば#{nobi}?(ん#{nobi}?[はわ]|$)|
				(^|#{nobi})ば#{nobi}?ん#{nobi}?(わ|は|#{nobi}|$)/xo,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 16..23, 0..3
					night.(t)
				when 4..9
					["もう#{t.roughly_time}ですよー"].select_rand(3)+
					["もう朝ですー", "もう#{t.roughly_time_slot}ですよー", "・・・チュンチュン:bird:"]+
					na.(t).sample(3)
				else
					["#{t.roughly_time}ですよー！"].select_rand(3)+
					["まだ昼ですー！", "#{t.roughly_time_slot}ですよー！"]+
					na.(t).sample(2)
				end
			},
		),
		Pattern.new(
			# 乙、落ちます
			regexp: /
				(では|じゃ(ぁ|あ|))(おつ|乙)|
				(おつ|乙)(#{nobi}|$)|
				(?<![ながい]|する)(落|お)ち($|ま|る([わねか]))|
				^(落|お)ちる(?!に)/xo,
			responses: lambda{|t, md|
				case t.hour
				when 21..23, 0..1
					good_night.(t)
				when 2..5
					late_night_drop.(t)
				else
					["あ、乙ですー", "おつかれさまでした！", "乙ー", "おつですー！", "おつかれさまでしたー！"]
				end
			},
		),
		Pattern.new(
			# おやすみ
			regexp: /
				((?<![で])寝|(^|#{nobi}|#{sink})ね)(ます|よ|て($|#{nobi}|る[ねー])|る(ね(?!る)|か(?!も)|#{nobi}|$))|
				お(やす|休)み|
				(眠|ねむ)([たる]|り(?!の)|い(?!け))|
				^ねむ$|
				💤|
				\bzzz\b/xo,
			skip: 60,
			responses: lambda{|t, md|
				osoyo =
					["おそよー", "おそよーですー", "おそようですー"]+
					add_nobi_or_nn_to_end("まだ#{t.roughly_time}ですよ").sample(2)+
					na.(t).sample(2)
				case t.hour
				when 20..23, 0..1
					good_night.(t)+["あ、おやすみですー", "自分はまだ起きてますねー"]
				when 2..8
					late_night_drop.(t)
				when 9..15
					osoyo
				when 16..19
					osoyo
				end
			},
		),
		Pattern.new(
			# おつかれさまでした
			regexp: /
				(?<!い|を)(つか|疲)れ(?!って|て|たこと(とか)?は?ない)|
				(?<!ら)お(疲|つか)れ(?!の|た)|
				(^|は|#{nobi})(乙|おつ)($|で|か|し|#{nobi})/xo,
			skip: 60,
			responses: lambda{|t, md|
				case t.hour
				when 9..23
					["おつかれさまです！", "おつかれさまでした！", "おつです", "おつです！"]
				when 0..8
					["遅くまでおつかれさまです！", "遅くまでお疲れ様です！", "おつかれさまです、おやすみです", "おつです！おやすみです！", "乙です！おやすみですー"]
				end
			},
		),
		Pattern.new(
			# はじめまして
			regexp: /(初|はっ?じ)めまして/o,
			skip: 900, # 挨拶は若干遅れてもやると思うので、skip:は長め
			responses: lambda{|t, md|
				["はっじめまっしてー！", "初めましてー", "はじめましてですー", "よろしくー！", "よろしくですー！"]+
				na.(t).sample(2)
			},
		),
		Pattern.new(
			# よろしく
			regexp: /^よろ#{nobi}|宜しく|よろ(しく|で)|夜露死苦/o,
			skip: 300, # 挨拶は若干遅れてもやると思うので、skip:は長め
			responses: lambda{|t, md|
				case t.hour
				when 9..16
					daytime.(t)
				when 17..23, 0..3
					night.(t)
				else
					morning.(t)
				end +
				["よろしくです！", "よろしくですー！", "よろです！", "よろー"]
			},
		),
		Pattern.new(
			# ただいま
			regexp: /
				ただい?ま(#{nobi}|で|$)|(もど|もっど|戻)(り($|だ|で|まし|#{nobi})|#{nobi}?$)|
				^がこおわ/xo,
			responses: lambda{|t, md|
				["あ、おかえりですー", "おかえりですー", "おかかー", "おかえりなさいませー！"]+
				["おっかかー", "おかかですー"].select_rand(2)+
				["おかかおいしいよね"].select_rand(5)+
				["おかえりなさいませ。ご主人様。"].select_rand(50)
			},
		),
		Pattern.new(
			# いってきます
			regexp: /
				(
					(
						(^|[にらは]|#{sink}|#{nobi})(?<!で)い|
						(?<!どうやって|くらい|後|日|で)行
					)
					(きま(?!した)|っ?て(くる|き(?!た|ました))|く(?!って)(ね|か(?!な|行|い|ら)|#{sink}|#{nobi}|$))
				)|
				(?<![なの])(といれ|お(手|て)(洗|あら)い|お(花|はな)(摘|つ)み|(雉|きじ)((撃|う)ち|(狩|が|か)り))#{nobi}?#{sink}?$|
				(出|で)かけて/xo,
			responses: lambda{|t, md|
				[
					"あ、いってらっしゃいですー",
					"いってらですー",
					"あーいってらっしゃいですー",
					"いってらっさいー！",
					"いってらっさいですー",
					"いってらっさいですんー",
				]
			},
		),
		Pattern.new(
			regexp: /\A\^\^\#\z/o,
			responses: lambda{|t, md|
				["かわいいにゃ", "かわいいにゃー...", "にゃぁ～....ってあっ！"]
			},
		),
		Pattern.new(
			regexp: /\Aせや\z/o,
			responses: lambda{|t, md|
				["なー", "なー！"]
			},
		),
		Pattern.new(
			regexp: /(今|い#{nobi}?ま)#{nobi}?(は|って)?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(分|ふん|秒|びょう)(?!分|残)/o,
			responses: lambda{|t, md|
				desu
			},
			add_process: lambda{|s, t|
				"#{t.roughly_time_slot}の#{t.hour}時#{t.min}分#{t.sec}秒#{s}"
			},
		),
		Pattern.new(
			regexp: /
				(今|い#{nobi}?ま)#{nobi}?(は|って)?#{nobi}?(何|な#{nobi}?ん)#{nobi}?(時|じ|どき)(?!分|残)|
				(今|いま)(の(時間|じかん))?(は|は?(([零〇一二三四五六七八九十]+|\d+)(時|じ)?))(?!ー)#{nobi}$/xo,
			responses: lambda{|t, md|
				desu
			},
			add_process: lambda{|s, t|
				"#{t.roughly_time}#{s}"
			},
		),
		Pattern.new(
			regexp: /(今|い#{nobi}?ま|今日|き#{nobi}?ょ(#{nobi}?う)?)#{nobi}?(は|って)?#{nobi}?(何|な#{nobi}?ん)#{nobi}?((日|に#{nobi}?ち)(?!分|残)|(曜日|ようび))/o,
			responses: lambda{|t, md|
				desu
			},
			add_process: lambda{|s, t|
				"#{t.year}年#{t.month}月#{t.day}日で#{t.weekday}曜日#{s}"
			},
		),
		Pattern.new(
			regexp: /メリー?クリ(スマス|#{nobi}?$)|merry (christ|x'?)mas/o,
			skip: 60*10,
			responses: lambda{|t,md|
				christmas.(t)
			},
		),
		Pattern.new(
			regexp: /(あ|明)け(まして)?おめ|ハッピーニューイヤー|happy new year/o,
			skip: 60*10,
			responses: lambda{|t,md|
				new_year.(t)
			},
		),
		Pattern.new(
			regexp: /^お前を消す方法$/,
			skip: 60,
			responses: lambda do |t,md|
				["そんなー", "消さないでくださいよー"]
			end,
		),
		Pattern.new(
			regexp: /<@!?394876010438328321>/o,
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
				`n.ruby [いろいろ]`
					詳しくは `n.ruby help` をご覧ください。
				`n.bots`
					兄弟ボットを紹介します！ぜひ導入してみてください！
				
				`こん` と入力してみると？
				EOS
			},
		),
		Pattern.new(
			regexp: /^n\.info$/o,
			skip: 0,
			responses: lambda{|t, md|
				[
					"`@sou7#0094`(soukouki)が作ったbotですー。",
					"おはよう、こんにちは、落ちます、おやすみ、初めまして、ただいま、行ってきます いま何時？ 今日何日？ に対応してます。",
					"`^^#` `せや`", "連続だと反応しないようにしてあるものもあります。",
					"`d[聞く時間]-おはよう`でその時間の返事が聞けます。",
				]
			},
			add_process: lambda{|s, t|
				<<~EOS
				#{((rand(2)==0)? greeting+"\n" : "")}#{s}
				
				
				招待URLはこちら！ https://discordapp.com/oauth2/authorize?client_id=394876010438328321&scope=bot&permissions=2048
				EOS
			},
		),
		Pattern.new(
			regexp: /^n\.test$/o,
			responses: lambda{|t, md|
				sel = TEST_PATTERN
					.map{|s,event|[s,event,!!(find(s)) == event]}
					.select{|s,event,r|!r}
				res = if sel.empty?
					"テストはすべて成功でした！(全#{TEST_PATTERN.length}パターン)"
				else
					"失敗したテストがあります。(全#{TEST_PATTERN.length}パターン中、失敗#{sel.length}パターン)\n"+
						sel
							.map{|s,event,r|"#{s}\n\t期待 : #{event}"}
							.join("\n")
							.yield_self{|s|"```\m"+s+"```"}
				end
				[res]
			},
		),
		Pattern.new(
			regexp: /
				(?<name>[a-zA-Z_][a-zA-Z0-9_]*){0}
				(?<operator>\||^|&|<=>|==|===|=~|>|>=|<|<=|<<|>>|\+|-|\*|\/|%|\*\*|~|\+@|-@|\[\]|\[\]=|`|!|!=|!~){0}
				(?<module_name>[A-Z][a-zA-Z_]*){0}
				(?<nested_module_name>\g<module_name>(?:::\g<module_name>)*?){0}
				(?<method_name>\g<name>[!?]?|\g<operator>|\g<name>=){0}
				(?<const_name>[A-Z_]+){0}
				(?<variable_name>[~*$?!@\/\\;,=:<>"'.&+`]|-\w|[A-Za-z_][A-Za-z0-9_]*|[0-9]+){0}
				\An\.ruby\s+\g<nested_module_name>(::\g<const_name>|(?<call>\#|\.|\.\#)\g<method_name>)?\z|
				\An\.ruby\s+\$\g<variable_name>\z|
				\An\.ruby\s+(?<help>help)\z/xo,
			skip: 0,
			responses: lambda{|t, md|
				p md
				if md[:help]
					return [<<~EOS]
						rubyの公式ドキュメントのリンクを教えてくれます。
						以下このコマンドの例です。
						
						`n.ruby help`
							このコマンドのヘルプです。
							
						`n.ruby Random`
							`Random`クラスのドキュメントへのリンクを教えてくれます。
							
						`n.ruby Random.new`
							`Random`クラスの`new`特異メソッドのドキュメントへのリンクを教えてくれます。
							メモ : `[クラス].[メソッド名]`の形で呼び出すメソッドが特異メソッドです。
							
						`n.ruby Random#rand`
							`Random`クラスの`rand`インスタンスメソッドへのドキュメントへのリンクを教えてくれます。
							メモ : `[クラスのインスタンス].[メソッド名]`の形で呼び出すメソッドがインスタンスメソッドです。
							
						`n.ruby Math.sin` または `Math.#sin`
							`Math`クラスの`sin`モジュール関数へのドキュメントへのリンクを教えてくれます。
							メモ : `[モジュール].[メソッド名]`の形で呼び出すメソッドがモジュール関数です。
							メモ : また、`loop{}`や`puts`は`Kernel`モジュールの関数なので、`n.ruby Kernel.#loop`で教えてくれます。
							
						`n.ruby Random::DEFAULT`
							`Random`クラスの`DEFAULT`定数へのドキュメントへのリンクを教えてくれます。
							
						`n.ruby $LOAD_PATH`
							特殊変数`$LOAD_PATH`のドキュメントへのリンクを教えてくれます。
							
						反応しない場合は、入力の仕方が間違っているか、こちら側のバグが考えられます。
					EOS
				end
				encode = ->(s){s.gsub(/([^a-zA-Z0-9_])/){"="+$1.ord.to_s(16)}}
				md[:nested_module_name] && encoded_module_name   = encode.(md[:nested_module_name])
				md[:method_name]        && encoded_method_name   = encode.(md[:method_name])
				md[:const_name]         && encoded_const_name    = encode.(md[:const_name])
				md[:variable_name]      && encoded_variable_name = encode.(md[:variable_name])
				url = case
				when md[:const_name] # 定数
					<<~EOS
						2つの可能性があります。
							クラス・モジュールの場合 https://docs.ruby-lang.org/ja/latest/class/#{encode.(md[:nested_module_name]+"::"+md[:const_name])}.html
							定数の場合 https://docs.ruby-lang.org/ja/latest/method/#{encoded_module_name}/c/#{encoded_const_name}.html
					EOS
				when md[:call] == "." # 特異メソッド or モジュール関数
					<<~EOS
						2つの可能性があります。
							特異メソッドの場合 https://docs.ruby-lang.org/ja/latest/method/#{encoded_module_name}/s/#{encoded_method_name}.html
							モジュール関数の場合 https://docs.ruby-lang.org/ja/latest/method/#{encoded_module_name}/m/#{encoded_method_name}.html
					EOS
				when md[:call] == "#" # インスタンスメソッド
					"https://docs.ruby-lang.org/ja/latest/method/#{encoded_module_name}/i/#{encoded_method_name}.html"
				when md[:call] == ".\#" # モジュール関数
					"https://docs.ruby-lang.org/ja/latest/method/#{encoded_module_name}/m/#{encoded_method_name}.html"
				when md[:variable_name] # 特殊変数
					"https://docs.ruby-lang.org/ja/latest/method/Kernel/v/#{encoded_variable_name}.html"
				else # クラス・モジュール
					"https://docs.ruby-lang.org/ja/latest/class/#{encoded_module_name}.html"
				end
				[url]
			}
		),
		Pattern.new(
			regexp: /^n\.solve\s+(.+)$/o,
			skip: 0,
			responses: lambda{|t, md|
				require_relative "./solve_liner"
				puts "方程式解くよ！"
				text = md[1]
				p "#{text}"
				a = SolveLiner.parse(text)
				pp a
				b = SolveLiner.solve(a[:a], a[:b])
				pp b
				if b.kind_of?(String)
					puts b
					return [b]
				end
				ret = SolveLiner.to_s(b, a[:vars])
				p ret
				["解けたー！`#{ret}`"]
			},
		),
		Pattern.new(
			regexp: /^n\.bots$/o,
			responses: lambda{|t,md|
				[<<~EOS]
					兄弟bot一覧！
					__Greetingbot__
						挨拶botです！挨拶に関してはかなりのものだと思ってます！
							導入url : <https://discordapp.com/oauth2/authorize?client_id=394876010438328321&scope=bot&permissions=2048>
							prefix : `n.`
					__M-putit__
						気象・地震・津波情報関連のbotです！気象庁が発表する色んな情報をチャンネルに流せます！(設定に時間がかかります。ご了承ください)
							導入url <https://discordapp.com/oauth2/authorize?scope=bot&client_id=505357370306592788&permissions=2048>
							prefix : `m.`
					__BlockKing__
						:crossed_swords: **アイテムを集めてクラフトし、強力な剣で王座を狙うゲームです！** :fire:
							導入url : <https://discordapp.com/oauth2/authorize?client_id=555753809834409987&permissions=2048&scope=bot>
							公式サーバー(プレイもできる) : <https://discord.gg/nJ5QVJu>
							prefix : `B`
				EOS
			}
		),
	]
end
