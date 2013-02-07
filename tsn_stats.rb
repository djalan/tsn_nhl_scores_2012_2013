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

my_goalers = {}
my_goalers['Jonathan Quick'] = 'Los Angeles'
my_goalers['Jimmy Howard'] = 'Detroit'

my_skaters = my_defenders + my_forwards

my_players = my_skaters + my_goalers.keys



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
GOALIES_WIN = 3
GOALIES_OT = 1

puts "G  A  F  Players"
puts "----------------"

#games_list = ['17150']
games_list.each do |game|
	html = Nokogiri::HTML(File.open(File.expand_path("#{game}.html")))

	boxscore = html.css('div.boxScoreBg table.boxScore tr')
	period = boxscore[0].children[0].text
	teams_score = {}
	teams_score[boxscore[1].css('td a').text] = boxscore[1].css('td b').text.to_i
	teams_score[boxscore[2].css('td a').text] = boxscore[2].css('td b').text.to_i
	
	playing = html.css('div#tsnStats table.siPlayerBoxStats tr').select { |tr| my_players.include? tr.css('a').text }

	p_skaters = playing.select { |tr| my_skaters.include? tr.css('a').text }
	p_goalers = playing.select { |tr| my_goalers.keys.include? tr.css('a').text }
	goalers_array << p_goalers unless p_goalers.empty?
	
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

		puts "#{goal}g #{assist}a #{fantasy_points}f #{name}#{name.length >= 15 ? "\t" : "\t\t"}#{teams_score.keys[0]} #{teams_score.values[0]} vs #{teams_score.keys[1]} #{teams_score.values[1]} - #{period}"
	end

	unless p_goalers.empty?
		p_goalers.each do |p_goaler|
			name = p_goaler.css('a').text
			goalie_team = my_goalers[name]
			opponent = (teams_score.reject{ |team,score| team =~ /#{goalie_team}/ }).keys[0]
			fantasy_goalie_points = 0
			if teams_score[goalie_team] > teams_score[opponent] && (period == "FINAL" || period == "FINAL (OT)")
				fantasy_goalie_points = GOALIES_WIN
				puts "1w 0o #{fantasy_goalie_points}f #{name}#{name.length >= 15 ? "\t" : "\t\t"}#{teams_score.keys[0]} #{teams_score.values[0]} vs #{teams_score.keys[1]} #{teams_score.values[1]} - #{period}"
			elsif period == 'FINAL (OT)'
				fantasy_goalie_points = GOALIES_OT
				puts "0w 1o #{fantasy_goalie_points}f #{name}#{name.length >= 15 ? "\t" : "\t\t"}#{teams_score.keys[0]} #{teams_score.values[0]} vs #{teams_score.keys[1]} #{teams_score.values[1]} - #{period}"
			else
				fantasy_goalie_points = 0
				puts "0w 0o #{fantasy_goalie_points}f #{name}#{name.length >= 15 ? "\t" : "\t\t"}#{teams_score.keys[0]} #{teams_score.values[0]} vs #{teams_score.keys[1]} #{teams_score.values[1]} - #{period}"
			end
			fantasy_points_total += fantasy_goalie_points
		end
	end
end

puts "----------------"
puts "#{'%02d' % goal_total} #{'%02d' % assist_total} #{'%02d' % fantasy_points_total} Total"
if goalers_array.empty?
	puts 'No goalie playing tonight'
end


Dir.glob('*.html') { |file| File.delete(file) }


__END__

