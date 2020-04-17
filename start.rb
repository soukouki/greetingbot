
token = ARGV[0]
shards_num = ARGV[1].to_i

usage = <<~EOS
	$ruby start.rb [token] [shards_num]
EOS
if token.nil? || token.empty?
	abort "tokenが設定されていません。\n"+usage
end
if shards_num==0
	abort "shards_numが設定されていません。\n"+usage
end

shards_num
	.times
	.map do |i|
		Thread.new do
			file_name = File.expand_path(File.dirname(__FILE__))+"/greetingbot.rb"
			loop do
				system("ruby #{file_name} #{shards_num} #{i} #{token}")
			end
		end
	end
	.each(&:join)
