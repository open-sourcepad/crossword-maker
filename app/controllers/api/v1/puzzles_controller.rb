class Api::V1::PuzzlesController < API::V1::BaseController
  def create
    binding.pry
    puzzle = Crossword::Puzzle.new(15, 15, puzzle_params.values)
    puzzle.build!
    render json: {data: puzzle}.merge(@meta), status: 200
  end

  private

  def puzzle_params
    params.require(:words)
  end
end
