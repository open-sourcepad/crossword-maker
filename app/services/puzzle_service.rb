load 'lib/crossword.rb'
class PuzzleService
  def self.call
    puzzle = Crossword::Puzzle.new(4, 4, %W{ ASIA BEER BRAY EASE EVIL RAVE REAL YELL })
    # binding.pry
  end
end