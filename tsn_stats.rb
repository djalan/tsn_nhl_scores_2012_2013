#!/usr/bin/env ruby
# coding: utf-8



require 'nokogiri'
require 'open-uri'



# ==============
# Download games
# ==============
SCORES_FILE = 'scores.html'

File::open(SCORES_FILE, 'w') do |f|
	f << open('http://www.tsn.ca/nhl/scores').read
end

games_list = []
html = Nokogiri::HTML(File.open(File.expand_path(SCORES_FILE)))
html.css('div#tsnMain div.alignRight a').select { |link| link['href'] =~ %r{/nhl/scores/boxscore/} }.each do |link|
	game_id = link['href'].split('=')[-1]
	games_list << game_id
	File::open("#{game_id}.html", 'w') do |f|
		f << open("http://www.tsn.ca/nhl/scores/boxscore/?id=#{game_id}").read
	end
end



# =================
# Define my players
# =================
my_defenders = ['Joe Corvo', 'Tobias Enstrom', 'Erik Karlsson', 'Dustin Bufyglien', 'Michael Del Zotto', 'John-Michael Liles']

my_forwards = ['Travis Zajac', 'Joe Pavelski', 'Logan Couture', 'Tyler Seguin',
	'Curtis Glencross', 'Tyler Ennis', 'Milan Lucic', 'Michael Ryder', 'Kyle Okposo', 'Scott Hartnell', 'Justin Williams', 'Joffrey Lupul']

my_goalers = ['Jonathan Quick', 'Jimmy Howard']

my_skaters = my_defenders + my_forwards

my_players = my_skaters + my_goalers



# ================
# Print statistics
# ================
goal_total = 0
assist_total = 0
fantasy_points_total = 0
goalers_array = []
DEFENDERS_GOAL_VALUE = 3
DEFENDERS_ASSIST_VALUE = 2
DEFENDERS_HAT_TRICK_VALUE = 4
FORWARDS_GOAL_VALUE = 2
FORWARDS_ASSIST_VALUE = 1
FORWARDS_HAT_TRICK_VALUE = 3

puts "G  A  F  Players"
puts "----------------"

games_list.each do |game|
	html = Nokogiri::HTML(File.open(File.expand_path("#{game}.html")))
	playing = html.css('div#tsnStats table.siPlayerBoxStats tr').select { |tr| my_players.include? tr.css('a').text }

	p_skaters = playing.select { |tr| my_skaters.include? tr.css('a').text }
	p_goalers = playing.select { |tr| my_goalers.include? tr.css('a').text }
	goalers_array << p_goalers	
	
	p_skaters.each do |tr|
		name = tr.css('a').text
		goal = tr.children[1].text.to_i
		assist = tr.children[2].text.to_i

		if my_defenders.include? name
			fantasy_goal = goal * DEFENDERS_GOAL_VALUE
			fantasy_assist  = assist * DEFENDERS_ASSIST_VALUE
			fantasy_hat_trick = (goal / 3) * DEFENDERS_HAT_TRICK_VALUE
		elsif my_forwards.include? name
			fantasy_goal = goal * FORWARDS_GOAL_VALUE
			fantasy_assist  = assist * FORWARDS_ASSIST_VALUE
			fantasy_hat_trick = (goal / 3) * FORWARDS_HAT_TRICK_VALUE
		end
		fantasy_points = fantasy_goal + fantasy_assist + fantasy_hat_trick
		goal_total += goal
		assist_total += assist
		fantasy_points_total += fantasy_points

		puts "#{goal}g #{assist}a #{fantasy_points}f #{name}"
	end
end

puts "----------------"
puts "#{'%02d' % goal_total} #{'%02d' % assist_total} #{'%02d' % fantasy_points_total} Total"
#puts goalers_array.empty?
#puts goalers_array.size
#puts goalers_array.length
if goalers_array.empty?
	puts 'No goalie playing tonight'
else	
	goalers_array.each do |p_goaler|
		p_goaler.each { |tr| puts "#{tr.css('a').text} is playing tonight" }
	end
end


Dir.glob('*.html') { |file| File.delete(file) }


__END__
