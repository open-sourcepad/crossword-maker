module Crossword
  class Cell
    attr_reader   :x, :y
    attr_accessor :letter

    def initialize(x, y)
      @x = x
      @y = y
      @letter = "_"
    end
  end
end
