
if ARGV[0] == "-t"
	TESTMODE = true
	TOKEN = ARGV[1] || "1234abcd"
else
	TESTMODE = false
	TOKEN = ARGV[0]
end

puts "[|-t] [token]"


MAX_MSG_LENGTH = 50
MAX_MSG_BACK_QUOTE_COUNT = 2


require "timeout"

require "discordrb"
require "moji"
require "romaji"


require_relative "./test_patterns"
require_relative "./greeting_cases"


bot = Discordrb::Bot.new(token: TOKEN)

Thread.new do
	# 初回のfindは正規表現を組み立てたりするので時間がかかるため、起動時に正規表現を組み立てるように
	puts GreetingCases.greeting("n.test")
end

LastGreetingKey = Struct.new(:channel, :pattern)
LastGreetingValue = Struct.new(:time, :response)
last_greeting = {}

# 魔境。整理しないといけないなぁ・・・
bot.message{|event|
	# ログ出力
	print(
		"#{Time.now} : "+
		"#{event.server&.name || "DM"}(#{event.server&.id || "DM"}) "+
		"# #{event.channel.name}(#{event.channel.id}) "+
		"@ #{event.author.distinct}(#{event.author.id})(bot?:#{event.author.bot_account?})    \r"
	)
	
	
	# 前処理
	content = event.content
	isdebug = (content =~ /\Ad\d*-/)
	msg = (isdebug)? content.gsub(/\Ad-\d*/){""} : content
	time = if isdebug && (content =~ /\Ad\d+-/)
		now = Time.now
		Time.local(now.year, now.month, now.day, msg.match(/\Ad(\d+)-/)[1].to_i)
	else
		Time.now
	end
	
	if msg.length>=(MAX_MSG_LENGTH) && !isdebug
		puts "(#{MAX_MSG_LENGTH}文字を超えるメッセージのためカット)" if isdebug
		next
	end
	if msg.count("`") >= MAX_MSG_BACK_QUOTE_COUNT
		puts "(バッククオートが#{MAX_MSG_BACK_QUOTE_COUNT}つ以上含まれるためカット)" if isdebug
		next
	end
	if event.author.bot_account?
		puts "#{msg} => (botからのメッセージのためカット)" if isdebug
		next
	end
	unless bot.profile.on(event.server).permission?(:send_messages, event.channel)
		puts "#{msg} => (#{event.server&.name}の#{event.channel.name}ではbotの権限が足りないためカット)" if isdebug
		next
	end
	
	
	# 検索後処理
	match_data = GreetingCases.find(msg)
	
	if match_data.nil?
		puts "#{msg} => (マッチしませんでした)" if isdebug
		next
	end
	
	last_greeting_key = LastGreetingKey.new(event.channel, match_data.pattern)
	last_greeting[last_greeting_key] ||= LastGreetingValue.new(Time.now-match_data.pattern.skip, nil)
	puts content+" : デバッグモード。skip判定を飛ばします" if isdebug
	
	# スキップ処理
	puts "regexp : #{match_data.pattern.regexp.inspect}" if isdebug
	
	if (Time.now-match_data.pattern.skip < last_greeting[last_greeting_key].time) && !isdebug
		puts "#{msg} => (#{event.server&.name}の#{event.channel.name}では前回の挨拶から#{match_data.pattern.skip}秒以内のためカット)"
		next
	end
	
	responses = match_data.pattern.responses(time, match_data.match_data)
	# 取り出し
	response = if responses.length <= 1
		responses.sample
	else
		(responses - [last_greeting[last_greeting_key].response]).sample
	end
	
	processed_response = match_data.pattern.add_process(response, time)
	
	last_greeting[last_greeting_key] = LastGreetingValue.new(Time.now, response)
	
	
	# 出力
	puts time
	puts "#{msg}\n=> #{response}(#{event.server&.name}の#{event.channel.name})"
	if TESTMODE
		puts "\"#{processed_response}\"(TESTMODE)"
	else
		event.respond processed_response
	end
}


bot.ready{|event|
	bot.game = "挨拶bot|n.help 導入サーバー数#{bot.servers.count}"
}

bot.server_create{|event|
	next if TESTMODE
	puts "\n#{event.server.name}に参加しました。"
	(p event.server.default_channel||event.server.text_channels.first)
		.send_message(
			<<~EOS
				#{GreetingCases.greeting}。詳しくは`n.help`にて！
				
				This bot run only Japanese text.
			EOS
		)
	bot.game = "挨拶bot|n.help 導入サーバー数#{bot.servers.count}"
}


bot.run
