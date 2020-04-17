
TESTMODE = false

SHARDS_COUNT = ARGV[0].to_i
SHARD_ID = ARGV[1].to_i
TOKEN = ARGV[2]

MAX_MSG_LENGTH = 50
MAX_MSG_BACK_QUOTE_COUNT = 2


require "csv"

require "discordrb"
require "moji"
require "romaji"


require_relative "./test_patterns"
require_relative "./greeting_cases"


bot = Discordrb::Bot.new(token: TOKEN, num_shards: SHARDS_COUNT, shard_id: SHARD_ID)

LastGreetingKey = Struct.new(:channel, :pattern)
LastGreetingValue = Struct.new(:time, :response)
last_greeting = {}

# 魔境。整理しないといけないなぁ・・・
bot.message{|event|
	# ログ出力
	debug_log = "#{Time.now} @#{SHARD_ID.to_s.rjust(Math.log(SHARDS_COUNT, 10).ceil)} : "+
	"#{event.server&.name || "DM"}(#{event.server&.id || "DM"}) "+
	"# #{event.channel.name}(#{event.channel.id}) "+
	"@ #{event.author.distinct}(#{event.author.id})(bot?:#{event.author.bot_account?})"
	print(debug_log+"        \r")
	
	
	# 前処理
	content = event.content
	isdebug = (content =~ /\Ad\d*-/)
	
	# 多いので先に
	if event.author.bot_account?
		puts "#{msg} => (botからのメッセージのためカット)" if isdebug
		next
	end
	
	# 前処理の続き
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
	
	log_file = File.expand_path(File.dirname(__FILE__))+"/responses_log.csv"
	CSV.open(log_file, "a") do |csv|
		csv << [msg, processed_response]
	end
}


bot.ready{|event|
	bot.game = "挨拶bot|n.help"
}

bot.server_create{|event|
	next if TESTMODE
	puts "\n#{event.server.name}に参加しました。"
	(p event.server.default_channel||event.server.text_channels.first)
		.send_message(
			<<~EOS
				#{GreetingCases.greeting}。詳しくは`n.help`にて！
				
				This bot only works in Japanese text.
			EOS
		)
}


bot.run
