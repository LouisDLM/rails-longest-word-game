require 'open-uri'
require 'json'

class PagesController < ApplicationController
  def game
    @grid = generate_grid(9)
  end

  def score
    @time = Time.now.to_i - params[:time].to_i
    @word = params[:query]
    @grid_keep = params[:grid_keep].gsub(/\W+/, '').split("")
    @is_included = included?(@word, @grid_keep)
    @count = @word.scan(/\w/).inject(Hash.new(0)){|h, c| h[c] += 1; h}
    @score = compute_score( @count, @time)

    @translation = get_translation(@word)

    @run_game = run_game(@word, @grid_keep, @time)

  end

  def generate_grid(grid_size)
      Array.new(grid_size) { ('a'..'z').to_a[rand(26)] }
    end

    def included?(guess, grid)
      guess.split("").all? { |letter| guess.count(letter) <= grid.count(letter) }
    end

    def compute_score(attempt, time_taken)
      (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
    end

    def run_game(attempt, grid, time)
      result = { time: time }

      result[:translation] = get_translation(attempt)
      result[:score], result[:message] = score_and_message(
        attempt, result[:translation], grid, result[:time])

      result
    end

    def score_and_message(attempt, translation, grid, time)
      if included?(attempt.upcase, grid)
        if translation
          score = compute_score(attempt, time)
          [score, "well done"]
        else
          [0, "not an english word"]
        end
      else
        [0, "not in the grid"]
      end
    end

    def get_translation(word)
      api_key = "YOUR_SYSTRAN_API_KEY"
      begin
        response = open("https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=ced26575-0219-42be-b940-32870edacf0a&input=#{word}")
        json = JSON.parse(response.read.to_s)
        if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
          return json['outputs'][0]['output']
        end
      rescue
        if File.read('/usr/share/dict/words').upcase.split("\n").include? word.upcase
          return word
        else
          return nil
        end
      end
    end
end
