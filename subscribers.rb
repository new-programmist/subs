LOGFILE = "subs_log.txt"
URL = "https://www.youtube.com/@ゆっくりhonebone"
prev_output = ""

loop do
  time = Time.now
  timestamp = time.strftime("%Y/%m/%d %H:%M:%S")

  # yt-dlp + jq 実行
  output = %x{ yt-dlp -j "#{URL}" | jq -r 'select(.channel != null) | "\\(.channel) \\(.channel_follower_count) subscribers"' | head -n 1 }.chomp

  # 出力が無ければスキップ
  if output.nil? || output.strip.empty?
    puts "#{timestamp} [skip] no output"
    sleep 60
    next
  end

  line = "#{timestamp} #{output}"
  puts line

  # 変化があったときのみ追記＋git push
  if prev_output != output
    File.open(LOGFILE, "a:utf-8") { |f| f.puts line }

    # git操作を非同期で実行
    Thread.new do
      system("git add #{LOGFILE}")
      system("git commit -m 'update at #{timestamp}'")
      system("git push")
    end
  end

  prev_output = output
  sleep 60  # 1分間待機
end

