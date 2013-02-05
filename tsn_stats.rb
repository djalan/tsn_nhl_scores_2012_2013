#!/usr/bin/env ruby


require 'nokogiri'
require 'open-uri'


# ==============
# Download games
# ==============
scores_url = "http://www.tsn.ca/nhl/scores"
scores_file = "scores.html"
boxscore_url = "http://www.tsn.ca/nhl/scores/boxscore/?id="

File::open(scores_file, 'w') do |f|
	f << open(scores_url).read
end

html = Nokogiri::HTML(File.open(File.expand_path(scores_file)))
games_list = []

html.css('div#tsnMain div.alignRight a').select { |link| link['href'] =~ %r{/nhl/scores/boxscore/} }.each do |link|
	game_id = link['href'].split('=')[-1]
	games_list << game_id
	File::open("#{game_id}.html", 'w') do |f|
		f << open("#{boxscore_url}#{game_id}").read
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
goalers_status = []
defenders_goal_value = 3
defenders_assist_value = 2
defenders_hat_trick_value = 4
forwards_goal_value = 2
forwards_assist_value = 1
forwards_hat_trick_value = 3

puts "G  A  F  Players"
puts "----------------"

games_list.each do |game|
	html = Nokogiri::HTML(File.open(File.expand_path("#{game}.html")))
	playing = html.css('div#tsnStats table.siPlayerBoxStats tr').select { |tr| my_players.include? tr.css('a').text }

	p_skaters = playing.select { |tr| my_skaters.include? tr.css('a').text }
	p_goalers = playing.select { |tr| my_goalers.include? tr.css('a').text }
	goalers_status << p_goalers	
	
	p_skaters.each do |tr|
		children = tr.children

		name = tr.css('a').text
		goal = children[1].text.to_i
		assist = children[2].text.to_i

		if my_defenders.include? name
			fantasy_goal = goal * defenders_goal_value
			fantasy_assist  = assist * defenders_assist_value
			fantasy_hat_trick = (goal / 3) * defenders_hat_trick_value
		elsif my_forwards.include? name
			fantasy_goal = goal * forwards_goal_value
			fantasy_assist  = assist * forwards_assist_value
			fantasy_hat_trick = (goal / 3) * forwards_hat_trick_value
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
if goalers_status.nil?
	puts 'No goalie playing tonight'
else	
	goalers_status.each do |p_goaler|
		p_goaler.each { |tr| puts "#{tr.css('a').text} is playing tonight" }
	end
end


Dir.glob('*.html') { |file| File.delete(file) }


__END__
