require 'set'

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

def empty_glo_indices(glo_board)
  glo_board.reject { |s| ['X', 'O', 'D', 'NA'].include?(s) }
end

def empty_lo_indices(open_boards, lo_boards)
  empty_spots = []
  open_boards.each do |open_board|
    if lo_boards[open_board].is_a?(Array)
      empty_spots.push(lo_boards[open_board].map.with_index { |sq, index| (sq != 'X' && sq != 'O') ? index : nil }.compact)
    else
      empty_spots.push([])
    end
  end
  return empty_spots
end

def all_x_or_o(board)
  return false unless board.is_a?(Array)
  board.all? { |cell| cell == 'X' || cell == 'O' }
end

def winning(board, player)
  if (
    (board[0] == player && board[1] == player && board[2] == player) ||
    (board[3] == player && board[4] == player && board[5] == player) ||
    (board[6] == player && board[7] == player && board[8] == player) ||
    (board[0] == player && board[3] == player && board[6] == player) ||
    (board[1] == player && board[4] == player && board[7] == player) ||
    (board[2] == player && board[5] == player && board[8] == player) ||
    (board[0] == player && board[4] == player && board[8] == player) ||
    (board[2] == player && board[4] == player && board[6] == player)
  )
    true
  else
    false
  end
end



def minimax(glo_mo, lo_mo, los, player, depth, alpha, beta, maxDepth)
  score = eval_board(glo_mo, los)
  return { score: score } if depth == maxDepth

  glo_board_minimax = []
  los.each_with_index do |lo, i|
      if winning(lo, 'O')
      glo_board_minimax[i] = 'O'
      elsif winning(lo, 'X')
      glo_board_minimax[i] = 'X'
      elsif all_x_or_o(lo)
      glo_board_minimax[i] = 'D'
      else
      glo_board_minimax[i] = i
      end
  end

  return { score: -100000 + depth } if winning(glo_board_minimax, @com_player)
  return { score: 100000 - depth } if winning(glo_board_minimax, @hum_player)

  if glo_board_minimax[lo_mo].is_a?(Numeric) || glo_board_minimax[lo_mo] == 'NA'
    glo_board_minimax.each_with_index do |lo_board_minimax, j|
      glo_board_minimax[j] = 'NA' if lo_board_minimax.is_a?(Numeric)
    end
  end

  glo_board_minimax[lo_mo] = lo_mo if glo_board_minimax[lo_mo] == 'NA'
  open_boards_minimax = empty_glo_indices(glo_board_minimax)
  return { score: score } if open_boards_minimax.length.zero?

  empty_spots_in_lo_boards = empty_lo_indices(open_boards_minimax, los);
  
  if player == @hum_player
      max_val = -Float::INFINITY
      best_move = nil
      open_boards_minimax.each do |glo_move|
        empty_spots_in_lo_boards[open_boards_minimax.index(glo_move)].each do |lo_move|
          los[glo_move][lo_move] = 'X'
          move = minimax(glo_move, lo_move, los, @com_player, depth + 1, alpha, beta, maxDepth)
          los[glo_move][lo_move] = ' '
      
          if move[:score] > max_val
            max_val = move[:score]
            best_move = { gloIndex: glo_move, loIndex: lo_move, score: move[:score] }
          end
      
          alpha = [alpha, max_val].max
          break if beta <= alpha
        end
      end
      return best_move
  else
      min_val = Float::INFINITY
      best_move = nil
      
      
      open_boards_minimax.each do |glo_move|
        empty_spots_in_lo_boards[open_boards_minimax.index(glo_move)].each do |lo_move|
          los[glo_move][lo_move] = 'O'
          move = minimax(glo_move, lo_move, los, @hum_player, depth + 1, alpha, beta, maxDepth)
          los[glo_move][lo_move] = ' '
      
          if move[:score] < min_val
            min_val = move[:score]
            best_move = { gloIndex: glo_move, loIndex: lo_move, score: move[:score] }
          end
      
          beta = [beta, min_val].min
          break if beta <= alpha
        end
      end
      return best_move
  end
end

def eval_board(current, los)
  all_winning_combos = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
  position_scores = [0.3, 0.2, 0.3, 0.2, 0.4, 0.2, 0.3, 0.2, 0.3]
  lo_board_weightings = [1.35, 1, 1.35, 1, 1.7, 1, 1.35, 1, 1.35]

  def row_score(arr)
    o_count = 0
    x_count = 0
    num_count = 0
    arr.each do |element|
      case element
      when 'O'
        o_count += 1
      when 'X'
        x_count += 1
      else
        num_count += 1
      end
    end

    return -12 if o_count == 3
    return -6 if o_count == 2 && num_count == 1
    return 6 if x_count == 2 && num_count == 1
    return -9 if x_count == 2 && o_count == 1
    return 12 if x_count == 3
    return 9 if o_count == 2 && x_count == 1

    0
  end

  score = 0
  glo = []

  los.each_with_index do |lo, i|
    if winning(lo,'O')
      glo[i] = 'O'
      score -= position_scores[i] * 150
    elsif winning(lo, 'X')
      glo[i] = 'X'
      score += position_scores[i] * 150
    elsif all_x_or_o(lo)
      glo[i] = 'D'
    else
      glo[i] = i
    end
  end

  score -= 50000 if winning(glo, @com_player)
  score += 50000 if winning(glo, @hum_player)

  (0..8).each do |i|
    (0..8).each do |j|
      if los[i][j] == @com_player
        if i == current
          score -= position_scores[j] * 1.5 * lo_board_weightings[i]
        else
          score -= position_scores[j] * lo_board_weightings[i]
        end
      elsif los[i][j] == @hum_player
        if i == current
          score += position_scores[j] * 1.5 * lo_board_weightings[i]
        else
          score += position_scores[j] * lo_board_weightings[i]
        end
      end
    end

    row_scores = Set.new
    all_winning_combos.each do |combo|
      lo_arr = [los[i][combo[0]], los[i][combo[1]], los[i][combo[2]]]
      row_score_val = row_score(lo_arr)
      if !row_scores.include?(row_score_val)
        if (combo[0] == 0 && combo[1] == 4 && combo[2] == 8) || (combo[0] == 2 && combo[1] == 4 && combo[2] == 6)
          if row_score_val == 6 || row_score_val == -6
            if i == current
              score += row_score_val * 1.2 * 1.5 * lo_board_weightings[i]
            else
              score += row_score_val * 1.2 * lo_board_weightings[i]
            end
          end
        else
          if i == current
            score += row_score_val * 1.5 * lo_board_weightings[i]
          else
            score += row_score_val * lo_board_weightings[i]
          end
        end
        row_scores.add(row_score_val)
      end
    end
  end

  row_scores = Set.new
  all_winning_combos.each do |combo|
    glo_arr = [glo[combo[0]], glo[combo[1]], glo[combo[2]]]
    row_score_val = row_score(glo_arr)
    if !row_scores.include?(row_score_val)
      if (combo[0] == 0 && combo[1] == 4 && combo[2] == 8) || (combo[0] == 2 && combo[1] == 4 && combo[2] == 6)
        if row_score_val == 6 || row_score_val == -6
          score += row_score_val * 1.2 * 150
        end
      else
        score += row_score_val * 150
      end
      row_scores.add(row_score_val)
    end
  end

  score
end

def ai_player
    empty_spots_in_lo_boards = empty_lo_indices(@open_boards, @lo_boards)
    minimum_score = Float::INFINITY
    board = nil
    square = nil
    @open_boards.length.times do |o|
      empty_spots_in_lo_boards[o].length.times do |i|
        glo_move = @open_boards[o]
        lo_move = empty_spots_in_lo_boards[o][i]
        @lo_boards[glo_move][lo_move] = 'O'
        move = minimax(glo_move, lo_move, @lo_boards, @hum_player, 0, -Float::INFINITY, Float::INFINITY, 4)
        @lo_boards[glo_move][lo_move] = ' '
        if move[:score] < minimum_score
          minimum_score = move[:score]
          board = glo_move
          square = lo_move
        end
      end
    end

    @lo_boards[board][square] = 'O'

    @lo_boards.each_with_index do |board, i|
      if winning(board, @com_player)
        @glo_board[i] = 'O'
      elsif winning(board, @hum_player)
        @glo_board[i] = 'X'
      elsif all_x_or_o(board)
        @glo_board[i] = 'D'
      else
        @glo_board[i] = i
      end
    end

    if @glo_board[square].is_a?(Numeric) || @glo_board[square] == 'NA'
      @glo_board.each_with_index do |lo_board, i|
        @glo_board[i] = 'NA' if lo_board.is_a?(Numeric)
      end
    end

    @glo_board[square] = square if @glo_board[square] == 'NA'
    @open_boards = empty_glo_indices(@glo_board)
   
end
  
def display_board
    puts "#{style_board('-', 0)}" * 13 + "#{style_board('-', 1)}" * 13 + "#{style_board('-', 2)}" * 13
    puts "#{style_board('|', 0)} #{style_board(@lo_boards[0][0], 0)} #{style_board('|', 0)} #{style_board(@lo_boards[0][1], 0)} #{style_board('|', 0)} #{style_board(@lo_boards[0][2], 0)} #{style_board('|', 0)}#{style_board('|', 1)} #{style_board(@lo_boards[1][0], 1)} #{style_board('|', 1)} #{style_board(@lo_boards[1][1], 1)} #{style_board('|', 1)} #{style_board(@lo_boards[1][2], 1)} #{style_board('|', 1)}#{style_board('|', 2)} #{style_board(@lo_boards[2][0], 2)} #{style_board('|', 2)} #{style_board(@lo_boards[2][1], 2)} #{style_board('|', 2)} #{style_board(@lo_boards[2][2], 2)} #{style_board('|', 2)}"
    puts "#{style_board('-', 0)}" * 13 + "#{style_board('-', 1)}" * 13 + "#{style_board('-', 2)}" * 13
    puts "#{style_board('|', 0)} #{style_board(@lo_boards[0][3], 0)} #{style_board('|', 0)} #{style_board(@lo_boards[0][4], 0)} #{style_board('|', 0)} #{style_board(@lo_boards[0][5], 0)} #{style_board('|', 0)}#{style_board('|', 1)} #{style_board(@lo_boards[1][3], 1)} #{style_board('|', 1)} #{style_board(@lo_boards[1][4], 1)} #{style_board('|', 1)} #{style_board(@lo_boards[1][5], 1)} #{style_board('|', 1)}#{style_board('|', 2)} #{style_board(@lo_boards[2][3], 2)} #{style_board('|', 2)} #{style_board(@lo_boards[2][4], 2)} #{style_board('|', 2)} #{style_board(@lo_boards[2][5], 2)} #{style_board('|', 2)}"
    puts "#{style_board('-', 0)}" * 13 + "#{style_board('-', 1)}" * 13 + "#{style_board('-', 2)}" * 13
    puts "#{style_board('|', 0)} #{style_board(@lo_boards[0][6], 0)} #{style_board('|', 0)} #{style_board(@lo_boards[0][7], 0)} #{style_board('|', 0)} #{style_board(@lo_boards[0][8], 0)} #{style_board('|', 0)}#{style_board('|', 1)} #{style_board(@lo_boards[1][6], 1)} #{style_board('|', 1)} #{style_board(@lo_boards[1][7], 1)} #{style_board('|', 1)} #{style_board(@lo_boards[1][8], 1)} #{style_board('|', 1)}#{style_board('|', 2)} #{style_board(@lo_boards[2][6], 2)} #{style_board('|', 2)} #{style_board(@lo_boards[2][7], 2)} #{style_board('|', 2)} #{style_board(@lo_boards[2][8], 2)} #{style_board('|', 2)}"
    puts "#{style_board('-', 0)}" * 13 + "#{style_board('-', 1)}" * 13 + "#{style_board('-', 2)}" * 13
    puts "#{style_board('-', 3)}" * 13 + "#{style_board('-', 4)}" * 13 + "#{style_board('-', 5)}" * 13
    puts "#{style_board('|', 3)} #{style_board(@lo_boards[3][0], 3)} #{style_board('|', 3)} #{style_board(@lo_boards[3][1], 3)} #{style_board('|', 3)} #{style_board(@lo_boards[3][2], 3)} #{style_board('|', 3)}#{style_board('|', 4)} #{style_board(@lo_boards[4][0], 4)} #{style_board('|', 4)} #{style_board(@lo_boards[4][1], 4)} #{style_board('|', 4)} #{style_board(@lo_boards[4][2], 4)} #{style_board('|', 4)}#{style_board('|', 5)} #{style_board(@lo_boards[5][0], 5)} #{style_board('|', 5)} #{style_board(@lo_boards[5][1], 5)} #{style_board('|', 5)} #{style_board(@lo_boards[5][2], 5)} #{style_board('|', 5)}"
    puts "#{style_board('-', 3)}" * 13 + "#{style_board('-', 4)}" * 13 + "#{style_board('-', 5)}" * 13
    puts "#{style_board('|', 3)} #{style_board(@lo_boards[3][3], 3)} #{style_board('|', 3)} #{style_board(@lo_boards[3][4], 3)} #{style_board('|', 3)} #{style_board(@lo_boards[3][5], 3)} #{style_board('|', 3)}#{style_board('|', 4)} #{style_board(@lo_boards[4][3], 4)} #{style_board('|', 4)} #{style_board(@lo_boards[4][4], 4)} #{style_board('|', 4)} #{style_board(@lo_boards[4][5], 4)} #{style_board('|', 4)}#{style_board('|', 5)} #{style_board(@lo_boards[5][3], 5)} #{style_board('|', 5)} #{style_board(@lo_boards[5][4], 5)} #{style_board('|', 5)} #{style_board(@lo_boards[5][5], 5)} #{style_board('|', 5)}"
    puts "#{style_board('-', 3)}" * 13 + "#{style_board('-', 4)}" * 13 + "#{style_board('-', 5)}" * 13
    puts "#{style_board('|', 3)} #{style_board(@lo_boards[3][6], 3)} #{style_board('|', 3)} #{style_board(@lo_boards[3][7], 3)} #{style_board('|', 3)} #{style_board(@lo_boards[3][8], 3)} #{style_board('|', 3)}#{style_board('|', 4)} #{style_board(@lo_boards[4][6], 4)} #{style_board('|', 4)} #{style_board(@lo_boards[4][7], 4)} #{style_board('|', 4)} #{style_board(@lo_boards[4][8], 4)} #{style_board('|', 4)}#{style_board('|', 5)} #{style_board(@lo_boards[5][6], 5)} #{style_board('|', 5)} #{style_board(@lo_boards[5][7], 5)} #{style_board('|', 5)} #{style_board(@lo_boards[5][8], 5)} #{style_board('|', 5)}"
    puts "#{style_board('-', 3)}" * 13 + "#{style_board('-', 4)}" * 13 + "#{style_board('-', 5)}" * 13
    puts "#{style_board('-', 6)}" * 13 + "#{style_board('-', 7)}" * 13 + "#{style_board('-', 8)}" * 13
    puts "#{style_board('|', 6)} #{style_board(@lo_boards[6][0], 6)} #{style_board('|', 6)} #{style_board(@lo_boards[6][1], 6)} #{style_board('|', 6)} #{style_board(@lo_boards[6][2], 6)} #{style_board('|', 6)}#{style_board('|', 7)} #{style_board(@lo_boards[7][0], 7)} #{style_board('|', 7)} #{style_board(@lo_boards[7][1], 7)} #{style_board('|', 7)} #{style_board(@lo_boards[7][2], 7)} #{style_board('|', 7)}#{style_board('|', 8)} #{style_board(@lo_boards[8][0], 8)} #{style_board('|', 8)} #{style_board(@lo_boards[8][1], 8)} #{style_board('|', 8)} #{style_board(@lo_boards[8][2], 8)} #{style_board('|', 8)}"
    puts "#{style_board('-', 6)}" * 13 + "#{style_board('-', 7)}" * 13 + "#{style_board('-', 8)}" * 13
    puts "#{style_board('|', 6)} #{style_board(@lo_boards[6][3], 6)} #{style_board('|', 6)} #{style_board(@lo_boards[6][4], 6)} #{style_board('|', 6)} #{style_board(@lo_boards[6][5], 6)} #{style_board('|', 6)}#{style_board('|', 7)} #{style_board(@lo_boards[7][3], 7)} #{style_board('|', 7)} #{style_board(@lo_boards[7][4], 7)} #{style_board('|', 7)} #{style_board(@lo_boards[7][5], 7)} #{style_board('|', 7)}#{style_board('|', 8)} #{style_board(@lo_boards[8][3], 8)} #{style_board('|', 8)} #{style_board(@lo_boards[8][4], 8)} #{style_board('|', 8)} #{style_board(@lo_boards[8][5], 8)} #{style_board('|', 8)}"
    puts "#{style_board('-', 6)}" * 13 + "#{style_board('-', 7)}" * 13 + "#{style_board('-', 8)}" * 13
    puts "#{style_board('|', 6)} #{style_board(@lo_boards[6][6], 6)} #{style_board('|', 6)} #{style_board(@lo_boards[6][7], 6)} #{style_board('|', 6)} #{style_board(@lo_boards[6][8], 6)} #{style_board('|', 6)}#{style_board('|', 7)} #{style_board(@lo_boards[7][6], 7)} #{style_board('|', 7)} #{style_board(@lo_boards[7][7], 7)} #{style_board('|', 7)} #{style_board(@lo_boards[7][8], 7)} #{style_board('|', 7)}#{style_board('|', 8)} #{style_board(@lo_boards[8][6], 8)} #{style_board('|', 8)} #{style_board(@lo_boards[8][7], 8)} #{style_board('|', 8)} #{style_board(@lo_boards[8][8], 8)} #{style_board('|', 8)}"
    puts "#{style_board('-', 6)}" * 13 + "#{style_board('-', 7)}" * 13 + "#{style_board('-', 8)}" * 13
end

$current_player = "X"
  
 
def style_board(char, index)
  if char != 'O' && char != 'X'
    if @open_boards.include?(index)
      return "\e[32m#{char}\e[0m"
    elsif @glo_board[index] == @com_player
      return "\e[91m#{char}\e[0m"
    elsif @glo_board[index] == @hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if @glo_board[index] == @com_player
      return "\e[91m#{char}\e[0m"
    elsif @glo_board[index] == @hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if @glo_board[index] == @com_player
      return "\e[91m#{char}\e[0m"
    elsif @glo_board[index] == @hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end


  
  def check_winner(player)
    winning_combinations = [
      [[0, 0], [0, 1], [0, 2]], # rows
      [[1, 0], [1, 1], [1, 2]],
      [[2, 0], [2, 1], [2, 2]],
      [[0, 0], [1, 0], [2, 0]], # columns
      [[0, 1], [1, 1], [2, 1]],
      [[0, 2], [1, 2], [2, 2]],
      [[0, 0], [1, 1], [2, 2]], # diagonals
      [[0, 2], [1, 1], [2, 0]]
    ]
  
    winning_combinations.any? do |combination|
      combination.all? { |row, col| @lo_boards[row][col] == player }
    end
  end
  

def get_valid_move
  loop do
    display_board
    puts "Player #{$current_player}, enter your move (board square): "
    input = gets.chomp

    if input.match?(/^\d+\s+\d+$/)
      board, square = input.split.map(&:to_i)
      if board.between?(0, 8) && @open_boards.include?(board) && square.between?(0, 8) && @lo_boards[board][square] == " "
        return [board, square]
      end
    end
    puts "Invalid move. Please try again."
  end
end

def play_game
  game_over = false

  until game_over

    board, square = get_valid_move
    @lo_boards[board][square] = $current_player

    @lo_boards.each_with_index do |lo_board, i|
      if winning(lo_board, 'O')
        @glo_board[i] = 'O'
      elsif winning(lo_board, 'X')
        @glo_board[i] = 'X'
      elsif all_x_or_o(lo_board)
        @glo_board[i] = 'D'
      else
        @glo_board[i] = i
      end
    end

    if @glo_board[square].is_a?(Numeric) || @glo_board[square] == 'NA'
      @glo_board.each_with_index do |lo_board, i|
        @glo_board[i] = 'NA' if lo_board.is_a?(Numeric)
      end
    end

    @glo_board[square] = square if @glo_board[square] == 'NA'
    @open_boards = empty_glo_indices(@glo_board)


    if winning(@glo_board, @com_player)
      display_board
      puts "Player #{@com_player} wins!"
      game_over = true
    elsif winning(@glo_board, @hum_player)
      display_board
      puts "Player #{@hum_player} wins!"
      game_over = true
    elsif all_x_or_o(@glo_board)
      display_board
      puts "It's a draw!"
      game_over = true
    else
      $current_player = $current_player == "X" ? "O" : "X"
    end

    ai_player

    if winning(@glo_board, @com_player)
      display_board
      puts "Player #{@com_player} wins!"
      game_over = true
    elsif winning(@glo_board, @hum_player)
      display_board
      puts "Player #{@hum_player} wins!"
      game_over = true
    elsif all_x_or_o(@glo_board)
      display_board
      puts "It's a draw!"
      game_over = true
    else
      $current_player = $current_player == "X" ? "O" : "X"
    end
  end
end

play_game