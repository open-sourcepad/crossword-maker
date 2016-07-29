module Crossword
  class Puzzle
    attr_reader :grid, :word_list, :vertical_words

    def initialize(width, height=width, word_list=Crossword::Loader.load_word_list_file)
      @grid      = Grid.new(width, height=width)
      @word_list = WordList.new(word_list)
      @vertical_words_on_grid = []
      @horizontal_words_on_grid = []
      @no_connect_words = []
      @fill_row_count = 0
    end

    def build!
      @word_list = @word_list.words.sort_by(&:length).reverse
      @word_list.each_with_index do |word, i|
        fill_grid(word, i)
      end
      @no_connect_words.sort_by(&:length).reverse.each do |word|
        insert_anywhere_available word
      end
    end

    def valid?
      down_words.each do |word|
        return false unless word_list.has_word? word
      end
      true
    end

    def print
      puts "Fill row count: #{@fill_row_count}"
      across_words.each do |word|
        word.each_char { |c| printf "#{c} " }; printf "\n"
      end
      nil
    end

    private

    def fill_grid(word, i)
      if i == 0
        cells = grid.cells_in_row(grid.height/2 - 1)
        word.chars.each_with_index do |letter, i|
          cells[i].letter = letter
        end
        @horizontal_words_on_grid.push word
      else
        all_letters_on_grid_from_horizontal = @horizontal_words_on_grid.join.split('')
        crossed_letters_from_horizontal = word.split('') & all_letters_on_grid_from_horizontal
        word_already_used = false
        crossed_letters_from_horizontal.each do |letter|
          grid.cells.select{|s| s.letter == letter}.each do |cell|
            word_already_used = check_vertical cell, word
            if word_already_used
              break
            end
          end
          if word_already_used
            break
          end
        end

        if !word_already_used
          all_letters_on_grid_from_vertical = @vertical_words_on_grid.join.split('')
          crossed_letters_from_vertical = word.split('') & all_letters_on_grid_from_vertical
          crossed_letters_from_vertical.each do |letter|
            grid.cells.select{|s| s.letter == letter}.each do |cell|
              word_already_used = check_horizontal cell, word
              if word_already_used
                break
              end
            end
            if word_already_used
              break
            end
          end
        end

        if !word_already_used
          @no_connect_words.push word
        end 
      end
    end

    def insert_anywhere_available word
      valid = false
      #search by rows
      (0..9).each do |i|
        start_space = 0
        ctr = 0
        grid.cells_in_row(i).map(&:letter).join.split(/[a-zA-Z]/).map {|x| x.split('')}.each do |space|
          if space.count-1 >= word.length
            (start_space..(space.count-1)).each do |j|
              cell = grid.cells_in_row(i).find {|c| c.y==j}
              valid = check_all_sides(cell)
              if valid
                ctr = ctr + 1
              else
                ctr = 0
              end
              if valid && ctr == word.length
                cells = grid.cells_in_row(i)
                word.chars.each_with_index do |letter, index|
                  cells[start_space+index+1].letter = letter
                end
                break
              elsif !valid
                start_space = cell.y
              end
            end
          else
            start_space = start_space + space.count + 2
          end
          if valid && ctr == word.length
            break
          end
        end
        if valid && ctr == word.length
          break
        end
      end

      
      if !valid
        #search by columns
        (0..9).each do |i|
          start_space = 0
          ctr = 0
          grid.cells_in_column(i).map(&:letter).join.split(/[a-zA-Z]/).map {|x| x.split('')}.each do |space|
            if space.count-1 >= word.length
              (start_space..(space.count-1)).each do |j|
                cell = grid.cells_in_column(i).find {|c| c.x==j}
                valid = check_all_sides(cell)
                if valid
                  ctr = ctr + 1
                else
                  ctr = 0
                end
                if valid && ctr == word.length
                  cells = grid.cells_in_column(i)
                  word.chars.each_with_index do |letter, index|
                    cells[start_space+index].letter = letter
                  end
                  break
                elsif !valid
                  start_space = cell.x
                end
              end
            else
              start_space = start_space + space.count + 2
            end
            if valid && ctr == word.length
              break
            end
          end
          if valid && ctr == word.length
            break
          end
        end
      end
    end

    def check_all_sides cell
      return ( (grid.cells.find {|inner_cell| inner_cell.x==(cell.x-1) && inner_cell.y==(cell.y)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x-1) && inner_cell.y==(cell.y)}.letter == '_') && 
      (grid.cells.find {|inner_cell| inner_cell.x==(cell.x+1) && inner_cell.y==(cell.y)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x+1) && inner_cell.y==(cell.y)}.letter == '_') &&
      (grid.cells.find {|inner_cell| inner_cell.x==(cell.x) && inner_cell.y==(cell.y+1)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x) && inner_cell.y==(cell.y+1)}.letter == '_') &&
      (grid.cells.find {|inner_cell| inner_cell.x==(cell.x) && inner_cell.y==(cell.y-1)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x) && inner_cell.y==(cell.y-1)}.letter == '_')) && 
      validate_word_fit_corners(cell)
    end

    def check_vertical cell, word
      flag = true
      i=0
      initial_x = cell.x
      while i<word.index(cell.letter) do
        initial_x = initial_x - 1
        flag = validate_word_fit_vertically(initial_x, cell) && validate_word_fit_corners(cell)
        i = i + 1
      end

      i=0
      initial_x = cell.x
      while i<(word.length - word.index(cell.letter) - 1) do
        initial_x = initial_x + 1
        flag = validate_word_fit_vertically(initial_x, cell) && validate_word_fit_corners(cell)
        i = i + 1
      end

      if flag
        letters_above = word.chars[0..(word.index(cell.letter))]
        letters_above.pop
        letters_below = word.chars[(word.index(cell.letter))..word.length-1]
        letters_below.shift
        letters_above.reverse.each_with_index do |c, index|
          grid.cells.find {|cel| cel.x==cell.x-(index+1) && cel.y==cell.y}.letter = c
        end
        letters_below.each_with_index do |c, index|
          grid.cells.find {|cel| cel.x==cell.x+(index+1) && cel.y==cell.y}.letter = c
        end
        @vertical_words_on_grid.push word
      end
      flag
    end

    def check_horizontal cell, word
      flag = true
      i=0
      initial_y = cell.y
      while i<word.index(cell.letter) do
        initial_y = initial_y - 1
        flag = validate_word_fit_horizontally(initial_y, cell)
        i = i + 1
      end

      i=0
      initial_y = cell.y
      while i<(word.length - word.index(cell.letter) - 1) do
        initial_y = initial_y + 1
        flag = validate_word_fit_horizontally(initial_y, cell)
        i = i + 1
      end

      flag = validate_word_fit_corners(cell)

      if flag
        letters_left = word.chars[0..(word.index(cell.letter))]
        letters_left.pop
        letters_right = word.chars[(word.index(cell.letter))..word.length-1]
        letters_right.shift
        letters_left.reverse.each_with_index do |c, index|
          grid.cells.find {|cel| cel.y==cell.y-(index+1) && cel.x==cell.x}.letter = c
        end
        letters_right.each_with_index do |c, index|
          grid.cells.find {|cel| cel.y==cell.y+(index+1) && cel.x==cell.x}.letter = c
        end
        @horizontal_words_on_grid.push word
      end
      flag
    end

    def validate_word_fit_corners cell
      return ( (grid.cells.find {|inner_cell| inner_cell.x==(cell.x-1) && inner_cell.y==(cell.y-1)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x-1) && inner_cell.y==(cell.y-1)}.letter == '_') && 
      (grid.cells.find {|inner_cell| inner_cell.x==(cell.x+1) && inner_cell.y==(cell.y+1)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x+1) && inner_cell.y==(cell.y+1)}.letter == '_') &&
      (grid.cells.find {|inner_cell| inner_cell.x==(cell.x+1) && inner_cell.y==(cell.y-1)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x+1) && inner_cell.y==(cell.y-1)}.letter == '_') &&
      (grid.cells.find {|inner_cell| inner_cell.x==(cell.x-1) && inner_cell.y==(cell.y+1)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(cell.x-1) && inner_cell.y==(cell.y+1)}.letter == '_'))
    end

    def validate_word_fit_vertically initial_x, cell
      if grid.cells.find {|inner_cell| inner_cell.x==(initial_x)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==(initial_x) && inner_cell.y==cell.y}.letter != '_'
        return false
      end
      return true
    end

    def validate_word_fit_horizontally initial_y, cell
      if grid.cells.find {|inner_cell| inner_cell.y==(initial_y)}.nil? || grid.cells.find {|inner_cell| inner_cell.x==cell.x && inner_cell.y==(initial_y)}.letter != '_'
        return false
      end
      return true
    end

    def build_potential_solution
      rows.each do |row|
        fill_row(row)
      end
    end

    def pick_first_word
      pick_nth_word 1
    end

    def solve_puzzle
      (2..grid.height).each do |n|
        begin
          pick_nth_word n
        end while !next_word_is_valid?
      end

    end

    def pick_nth_word(n)
      n = n-1

      fill_row(n)
    end

    def next_word_is_valid?
      down_words.all? do |substring|
        puts substring
        vertical_words.any? {|word| word.start_with? substring }
      end
    end

    def rows
      (0..(grid.height - 1))
    end

    def columns
      (0..(grid.width - 1))
    end

    def across_words
      rows.map do |row|
        grid.cells_in_row(row).map(&:letter).join
      end
    end

    def down_words
      a = columns.map do |column|
        grid.cells_in_column(column).map(&:letter).join
      end
      a.delete("")
      a
    end

    def fill_row(row)
      @fill_row_count += 1
      puts "count: #{@fill_row_count}"
      word = word_list.pick_word(grid.width)
      cells = grid.cells_in_row(row)
      word.chars.each_with_index do |letter, i|
        cells[i].letter = letter
      end
    end
  end
end
