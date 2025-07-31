LOGFILE = "subs_log.txt"
URL = "https://www.youtube.com/@ゆっくりhonebone"
USE_API = !(ENV["YOUTUBE_API_KEY"].nil?)
if !USE_API
  puts "\e[31mYOUTUBE_API_KEY is not set, using slow method\e[0m"
end
def get_subscribers(url)
  if !USE_API
    return %x{ yt-dlp -j "#{url}" | jq -r 'select(.channel != null) | "\\(.channel) \\(.channel_follower_count) subscribers"' | head -n 1 }.chomp
  end

  `curl -fsS "https://www.googleapis.com/youtube/v3/channels?key=#{ENV["YOUTUBE_API_KEY"]}&forHandle=@#{url[url.index("@") + 1..].bytes.map{"%" + _1.to_s(16).rjust(2, "0")}.join}&part=snippet,statistics" | jq -r '.items[] | [(.snippet.title | gsub(" "; "\\\\40")), .statistics.subscriberCount + " subscribers"] | join(" ")'`
end
prev_output = ""
prev_save = ""
prev_save_time = Time.now - 3000
loop do
  time = Time.now
  timestamp = time.strftime("%Y/%m/%d %H:%M:%S")

  output = get_subscribers(URL)#%x{ yt-dlp -j "#{URL}" | jq -r 'select(.channel != null) | "\\(.channel) \\(.channel_follower_count) subscribers"' | head -n 1 }.chomp

  if output.nil? || output.strip.empty?
    puts "#{timestamp} [skip] no output"
    sleep 60
    next
  end

  line = "#{timestamp} #{output}"
  puts line

  if prev_output != output
    File.open(LOGFILE, "a:utf-8") { |f| f.puts line }
  end
  if prev_save != output && time - prev_save_time > 300
    prev_save = output
    prev_save_time = time
    Thread.new do
      system("git add #{LOGFILE} > /dev/null 2>&1")
      system("git commit -m 'update at #{timestamp}' > /dev/null 2>&1")
      system("git push > /dev/null 2>&1")
    end
  end

  prev_output = output
  if USE_API
    sleep 20
  else
    sleep 60
  end
end

