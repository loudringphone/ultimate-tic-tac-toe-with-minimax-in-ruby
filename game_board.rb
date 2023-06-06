# Ultimate Tic Tac Toe game board
class GameBoard
  attr_accessor :lo_boards, :glo_board, :open_boards
  attr_reader :com_player, :hum_player

  def initialize
    @lo_boards = [
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']
    ]
    @glo_board = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    @open_boards = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    @com_player = 'O'
    @hum_player = 'X'
  end

  def empty_glo_indices(glo_board)
    glo_board.reject { |s| %w[X O D NA].include?(s) }
  end

  def empty_lo_indices(open_boards, lo_boards)
    empty_spots = []
    open_boards.each do |open_board|
      if lo_boards[open_board].is_a?(Array)
        empty_spots.push(lo_boards[open_board].map.with_index { |sq, index| sq != 'X' && sq != 'O' ? index : nil }.compact)
      else
        empty_spots.push([])
      end
    end
    empty_spots
  end

  def all_x_or_o(board)
    return false unless board.is_a?(Array)

    board.all? { |cell| %w[X O].include? cell }
  end

  def winning(board, player)
    if (board[0] == player && board[1] == player && board[2] == player) ||
       (board[3] == player && board[4] == player && board[5] == player) ||
       (board[6] == player && board[7] == player && board[8] == player) ||
       (board[0] == player && board[3] == player && board[6] == player) ||
       (board[1] == player && board[4] == player && board[7] == player) ||
       (board[2] == player && board[5] == player && board[8] == player) ||
       (board[0] == player && board[4] == player && board[8] == player) ||
       (board[2] == player && board[4] == player && board[6] == player)
      true
    else
      false
    end
  end
end
