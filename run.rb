#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require "socket"
require 'simplegrowl'
require 'trollop'
SimpleGrowl.set_password('growl')

# Need option to turn off growl

class IRC
  attr_reader :channel
  attr_reader :nick
  
  def initialize(server, port, nick, channel)
      @server = server
      @port = port
      @nick = nick
      @channel = channel
  end
  def send(s)
      # Send a message to the irc server and print it to the screen
      # puts "--> #{s}"
      @irc.send "#{s}\n", 0 
  end
  def send_msg(msg)
    send("PRIVMSG #{@channel} :#{msg}")
  end
  def connect()
      # Connect to the IRC server
      @irc = TCPSocket.open(@server, @port)
      send "USER blah blah blah :blah blah"
      send "NICK #{@nick}"
      ## Reister
      send "PRIVMSG NickServ :identify jmoses"
      send "JOIN #{@channel}"
  end
  
  def loop( times = 1)
    while true
      # puts " loop: #{i}"
      ready = select([@irc, $stdin], nil, nil, nil)
      next if ! ready
    
      for s in ready[0]
          if s == $stdin then
              return if $stdin.eof
              s = $stdin.gets
              send s
          elsif s == @irc then
              return if @irc.eof
              s = @irc.gets
              ##handle_server_input(s)
              if s =~ /^PING :(.*)/
                send("PONG :#{$1} #{@server}")
              end
              puts s
          end
      end
      sleep 1 ## Jesus, the CPU cycles...
    end
  end

  
end


opts = Trollop::options do
  opt :viewer, "Which viewer to use", :default => "quicklook"
  opt :console, "Only output to the console", :default => false
end

viewer = opts[:viewer]

unless %w( quicklook preview ).include?(viewer)
  Trollop::die "viewer must be one of 'quicklook', 'preview'"
end

uri = "http://live.gizmodo.com"

posts = []

@thread = nil

# @@bot = IRC.new('irc.freenode.net', '6667', "GizmodoBot", "#gizmodo_live_blog")
# 
# Thread.new(@@bot) do |bot|
#   bot.connect
#   
#   # lock channel
#   bot.send("MODE #{bot.channel} +ov #{bot.nick}")
#   bot.send("MODE #{bot.channel} +mt")
#   bot.send("TOPIC #{bot.channel} :Gizmodo Live Blog Coverage")
#   
#   bot.loop  
# end

@output = ['[37m', '[37;1m']
@output_index = 0
def colorize_output( output )
  puts 27.chr + @output[@output_index] + output + 27.chr + '[0m'
  @output_index = ( @output_index == 0 ? 1 : 0 )
end



def images( str )
  str.scan( /\[img:(.*?)\]/ )
end

# @thread = Thread.new(bot, posts) do |bot, posts|
  loop do
    tmp_posts = []
    doc = Hpricot(open(uri) {|f| f.read })
    (doc/".post-excerpt").each do |post|
      who = post.children.first.to_plain_text.strip
      what = post.children.reject {|c| c.class.name == "Hpricot::Text" }.detect {|c| c['class'] =~ /snap_preview/ }
      text = "#{who}: #{what.to_plain_text}"

      if ! posts.include?(text)
        tmp_posts << text
        posts << text
      end

    end

    tmp_posts.reverse.each do |p|
      if imgs = images(p) and imgs.size > 0 and !opts[:console]
        is = imgs.collect {|i| i[0] }
        is.each {|i| `curl -s --output /tmp/#{File.basename(i)} #{i} > /dev/null` }
        image_string = is.collect {|i| "\"/tmp/#{File.basename(i)}\"" }.join(' ')
        case viewer
        when 'quicklook'
          `qlmanage -p #{image_string} &> /dev/null &`
        when 'preview'
          `open -a Preview #{image_string} &`
        end
        # imgs.each {|i| i = i[0]; `curl -s --output /tmp/#{File.basename(i)} #{i} > /dev/null && open -a Preview /tmp/#{File.basename(i)}`}
      end
      colorize_output p
      SimpleGrowl.notify(p) unless opts[:console]
      #@@bot.send_msg(p); 
      puts
    end

    

    # puts "Resting..."
    sleep 30
  end
# end

# bot.connect