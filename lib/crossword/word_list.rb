module Crossword
  class WordList
    attr_reader :words

    def initialize(words)
      @words = words
    end

    def of_length(length)
      WordList.new(words.select{|w| w.length == length})
    end

    def pick_word(length)
      of_length(length).words.sample
    end

    def has_word?(word)
      of_length(word.length).words.include? word
    end
  end
end
