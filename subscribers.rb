LOGFILE = "subs_log.txt"
URL = "https://www.youtube.com/@ゆっくりhonebone"
prev_output = ""
loop do
  time = Time.now
  timestamp = time.strftime("%Y/%m/%d %H:%M:%S")
  # yt-dlp + jq コマンドを実行し1行だけ取得
  output = %x{ yt-dlp -j "#{URL}" | jq -r 'select(.channel != null) | "\\(.channel) \\(.channel_follower_count) subscribers"' | head -n 1 }.chomp

  line = "#{timestamp} #{output}"
  puts line

  # ファイルに追記
  if prev_output != output
    File.open(LOGFILE, "a:utf-8") do |f|
      f.puts line
    end
  end
  prev_output = output
  until time + 60 < Time.now
    sleep 5 
  end
end

