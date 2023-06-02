require 'set'

$lo_boards = [
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '], [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '], [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '], [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '], [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '], [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '], [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']
  ]
$glo_board = [0, 1, 2, 3, 4, 5, 6, 7, 8]

$com_player = 'O'
$hum_player = 'X'
$open_boards = [0, 1, 2, 3, 4, 5, 6, 7, 8]


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

def all_x_or_o(board)
  return false unless board.is_a?(Array)
  board.all? { |cell| cell == 'X' || cell == 'O' }
end

def minimax(mo, los, player, depth, alpha, beta, maxDepth)
  score = eval_board(mo[:gloIndex], los)
  return { score: score } if depth == maxDepth

  glo_board_minimax = []
  (0..8).each do |i|
      if winning(los[i], $com_player)
      glo_board_minimax[i] = 'O'
      elsif winning(los[i], $hum_player)
      glo_board_minimax[i] = 'X'
      elsif all_x_or_o(los[i])
      glo_board_minimax[i] = 'D'
      else
      glo_board_minimax[i] = i
      end
  end

  return { score: -100000 + depth } if winning(glo_board_minimax, $com_player)
  return { score: 100000 - depth } if winning(glo_board_minimax, $hum_player)

  if glo_board_minimax[mo[:loIndex]].is_a?(Numeric) || glo_board_minimax[mo[:loIndex]] == 'NA'
      (0..8).each do |j|
      glo_board_minimax[j] = 'NA' if glo_board_minimax[j].is_a?(Numeric)
      end
  end

  glo_board_minimax[mo[:loIndex]] = mo[:loIndex] if glo_board_minimax[mo[:loIndex]] == 'NA'
  open_boards_minimax = empty_glo_indices(glo_board_minimax)
  return { score: score } if open_boards_minimax.length.zero?

  empty_spots_in_lo_boards = empty_lo_indices(open_boards_minimax, los);
  
  if player == $hum_player
      max_val = -Float::INFINITY
      best_move = nil
      (0..open_boards_minimax.length-1).each do |o|
        (0..empty_spots_in_lo_boards[o].length-1).each do |i|
          los[open_boards_minimax[o]][empty_spots_in_lo_boards[o][i]] = 'X'
          move = { gloIndex: open_boards_minimax[o], loIndex: empty_spots_in_lo_boards[o][i] }
          result = minimax(move, los, $com_player, depth + 1, alpha, beta, maxDepth)
          move[:score] = result[:score]
          los[open_boards_minimax[o]][empty_spots_in_lo_boards[o][i]] = ' '
          if move[:score] > max_val
          max_val = move[:score]
          best_move = move
          end
          alpha = [alpha, max_val].max
          break if beta <= alpha
      end
      end
      return best_move
  else
      min_val = Float::INFINITY
      best_move = nil
      
      
      (0..open_boards_minimax.length-1).each do |o|
        (0..empty_spots_in_lo_boards[o].length-1).each do |i|
          los[open_boards_minimax[o]][empty_spots_in_lo_boards[o][i]] = 'O'
          move = { gloIndex: open_boards_minimax[o], loIndex: empty_spots_in_lo_boards[o][i] }
          result = minimax(move, los, $hum_player, depth + 1, alpha, beta, maxDepth)
          move[:score] = result[:score]
          los[open_boards_minimax[o]][empty_spots_in_lo_boards[o][i]] = ' '
          if move[:score] < min_val
          min_val = move[:score]
          best_move = move
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

  (0..8).each do |i|
    if winning(los[i], $com_player)
      glo[i] = 'O'
      score -= position_scores[i] * 150
    elsif winning(los[i], $hum_player)
      glo[i] = 'X'
      score += position_scores[i] * 150
    elsif all_x_or_o(los[i])
      glo[i] = 'D'
    else
      glo[i] = i
    end
  end

  score -= 50000 if winning(glo, $com_player)
  score += 50000 if winning(glo, $hum_player)

  (0..8).each do |i|
    (0..8).each do |j|
      if los[i][j] == $com_player
        if i == current
          score -= position_scores[j] * 1.5 * lo_board_weightings[i]
        else
          score -= position_scores[j] * lo_board_weightings[i]
        end
      elsif los[i][j] == $hum_player
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
    empty_spots_in_lo_boards = empty_lo_indices($open_boards, $lo_boards)
    minimum_score = Float::INFINITY
    best_move = nil

    $open_boards.length.times do |o|
      empty_spots_in_lo_boards[o].length.times do |i|
        $lo_boards[$open_boards[o]][empty_spots_in_lo_boards[o][i]] = 'O'
        move = { gloIndex: $open_boards[o], loIndex: empty_spots_in_lo_boards[o][i] }
        result = minimax(move, $lo_boards, $hum_player, 0, -Float::INFINITY, Float::INFINITY, 6)
        move[:score] = result[:score]
        $lo_boards[$open_boards[o]][empty_spots_in_lo_boards[o][i]] = ' '

        if move[:score] < minimum_score
          minimum_score = move[:score]
          best_move = move
        end
      end
    end

    board = best_move[:gloIndex]
    square = best_move[:loIndex]
    $lo_boards[board][square] = 'O'

    (0..8).each do |i|
      if winning($lo_boards[i], $com_player)
        $glo_board[i] = 'O'
      elsif winning($lo_boards[i], $hum_player)
        $glo_board[i] = 'X'
      elsif all_x_or_o($lo_boards[i])
        $glo_board[i] = 'D'
      else
        $glo_board[i] = i
      end
    end

    if $glo_board[square].is_a?(Numeric) || $glo_board[square] == 'NA'
      (0..8).each do |j|
      $glo_board[j] = 'NA' if $glo_board[j].is_a?(Numeric)
      end
    end

    $glo_board[square] = square if $glo_board[square] == 'NA'
    $open_boards = empty_glo_indices($glo_board)
   
end









  
def display_board
    puts "#{style_board_0('-')}" * 13 + "#{style_board_1('-')}" * 13 + "#{style_board_2('-')}" * 13
    puts "#{style_board_0('|')} #{style_board_0($lo_boards[0][0])} #{style_board_0('|')} #{style_board_0($lo_boards[0][1])} #{style_board_0('|')} #{style_board_0($lo_boards[0][2])} #{style_board_0('|')}#{style_board_1('|')} #{style_board_1($lo_boards[1][0])} #{style_board_1('|')} #{style_board_1($lo_boards[1][1])} #{style_board_1('|')} #{style_board_1($lo_boards[1][2])} #{style_board_1('|')}#{style_board_2('|')} #{style_board_2($lo_boards[2][0])} #{style_board_2('|')} #{style_board_2($lo_boards[2][1])} #{style_board_2('|')} #{style_board_2($lo_boards[2][2])} #{style_board_2('|')}"
    puts "#{style_board_0('-')}" * 13 + "#{style_board_1('-')}" * 13 + "#{style_board_2('-')}" * 13
    puts "#{style_board_0('|')} #{style_board_0($lo_boards[0][3])} #{style_board_0('|')} #{style_board_0($lo_boards[0][4])} #{style_board_0('|')} #{style_board_0($lo_boards[0][5])} #{style_board_0('|')}#{style_board_1('|')} #{style_board_1($lo_boards[1][3])} #{style_board_1('|')} #{style_board_1($lo_boards[1][4])} #{style_board_1('|')} #{style_board_1($lo_boards[1][5])} #{style_board_1('|')}#{style_board_2('|')} #{style_board_2($lo_boards[2][3])} #{style_board_2('|')} #{style_board_2($lo_boards[2][4])} #{style_board_2('|')} #{style_board_2($lo_boards[2][5])} #{style_board_2('|')}"
    puts "#{style_board_0('-')}" * 13 + "#{style_board_1('-')}" * 13 + "#{style_board_2('-')}" * 13
    puts "#{style_board_0('|')} #{style_board_0($lo_boards[0][6])} #{style_board_0('|')} #{style_board_0($lo_boards[0][7])} #{style_board_0('|')} #{style_board_0($lo_boards[0][8])} #{style_board_0('|')}#{style_board_1('|')} #{style_board_1($lo_boards[1][6])} #{style_board_1('|')} #{style_board_1($lo_boards[1][7])} #{style_board_1('|')} #{style_board_1($lo_boards[1][8])} #{style_board_1('|')}#{style_board_2('|')} #{style_board_2($lo_boards[2][6])} #{style_board_2('|')} #{style_board_2($lo_boards[2][7])} #{style_board_2('|')} #{style_board_2($lo_boards[2][8])} #{style_board_2('|')}"
    puts "#{style_board_0('-')}" * 13 + "#{style_board_1('-')}" * 13 + "#{style_board_2('-')}" * 13
    puts "#{style_board_3('-')}" * 13 + "#{style_board_4('-')}" * 13 + "#{style_board_5('-')}" * 13
    puts "#{style_board_3('|')} #{style_board_3($lo_boards[3][0])} #{style_board_3('|')} #{style_board_3($lo_boards[3][1])} #{style_board_3('|')} #{style_board_3($lo_boards[3][2])} #{style_board_3('|')}#{style_board_4('|')} #{style_board_4($lo_boards[4][0])} #{style_board_4('|')} #{style_board_4($lo_boards[4][1])} #{style_board_4('|')} #{style_board_4($lo_boards[4][2])} #{style_board_4('|')}#{style_board_5('|')} #{style_board_5($lo_boards[5][0])} #{style_board_5('|')} #{style_board_5($lo_boards[5][1])} #{style_board_5('|')} #{style_board_5($lo_boards[5][2])} #{style_board_5('|')}"
    puts "#{style_board_3('-')}" * 13 + "#{style_board_4('-')}" * 13 + "#{style_board_5('-')}" * 13
    puts "#{style_board_3('|')} #{style_board_3($lo_boards[3][3])} #{style_board_3('|')} #{style_board_3($lo_boards[3][4])} #{style_board_3('|')} #{style_board_3($lo_boards[3][5])} #{style_board_3('|')}#{style_board_4('|')} #{style_board_4($lo_boards[4][3])} #{style_board_4('|')} #{style_board_4($lo_boards[4][4])} #{style_board_4('|')} #{style_board_4($lo_boards[4][5])} #{style_board_4('|')}#{style_board_5('|')} #{style_board_5($lo_boards[5][3])} #{style_board_5('|')} #{style_board_5($lo_boards[5][4])} #{style_board_5('|')} #{style_board_5($lo_boards[5][5])} #{style_board_5('|')}"
    puts "#{style_board_3('-')}" * 13 + "#{style_board_4('-')}" * 13 + "#{style_board_5('-')}" * 13
    puts "#{style_board_3('|')} #{style_board_3($lo_boards[3][6])} #{style_board_3('|')} #{style_board_3($lo_boards[3][7])} #{style_board_3('|')} #{style_board_3($lo_boards[3][8])} #{style_board_3('|')}#{style_board_4('|')} #{style_board_4($lo_boards[4][6])} #{style_board_4('|')} #{style_board_4($lo_boards[4][7])} #{style_board_4('|')} #{style_board_4($lo_boards[4][8])} #{style_board_4('|')}#{style_board_5('|')} #{style_board_5($lo_boards[5][6])} #{style_board_5('|')} #{style_board_5($lo_boards[5][7])} #{style_board_5('|')} #{style_board_5($lo_boards[5][8])} #{style_board_5('|')}"
    puts "#{style_board_3('-')}" * 13 + "#{style_board_4('-')}" * 13 + "#{style_board_5('-')}" * 13
    puts "#{style_board_6('-')}" * 13 + "#{style_board_7('-')}" * 13 + "#{style_board_8('-')}" * 13
    puts "#{style_board_6('|')} #{style_board_6($lo_boards[6][0])} #{style_board_6('|')} #{style_board_6($lo_boards[6][1])} #{style_board_6('|')} #{style_board_6($lo_boards[6][2])} #{style_board_6('|')}#{style_board_7('|')} #{style_board_7($lo_boards[7][0])} #{style_board_7('|')} #{style_board_7($lo_boards[7][1])} #{style_board_7('|')} #{style_board_7($lo_boards[7][2])} #{style_board_7('|')}#{style_board_8('|')} #{style_board_8($lo_boards[8][0])} #{style_board_8('|')} #{style_board_8($lo_boards[8][1])} #{style_board_8('|')} #{style_board_8($lo_boards[8][2])} #{style_board_8('|')}"
    puts "#{style_board_6('-')}" * 13 + "#{style_board_7('-')}" * 13 + "#{style_board_8('-')}" * 13
    puts "#{style_board_6('|')} #{style_board_6($lo_boards[6][3])} #{style_board_6('|')} #{style_board_6($lo_boards[6][4])} #{style_board_6('|')} #{style_board_6($lo_boards[6][5])} #{style_board_6('|')}#{style_board_7('|')} #{style_board_7($lo_boards[7][3])} #{style_board_7('|')} #{style_board_7($lo_boards[7][4])} #{style_board_7('|')} #{style_board_7($lo_boards[7][5])} #{style_board_7('|')}#{style_board_8('|')} #{style_board_8($lo_boards[8][3])} #{style_board_8('|')} #{style_board_8($lo_boards[8][4])} #{style_board_8('|')} #{style_board_8($lo_boards[8][5])} #{style_board_8('|')}"
    puts "#{style_board_6('-')}" * 13 + "#{style_board_7('-')}" * 13 + "#{style_board_8('-')}" * 13
    puts "#{style_board_6('|')} #{style_board_6($lo_boards[6][6])} #{style_board_6('|')} #{style_board_6($lo_boards[6][7])} #{style_board_6('|')} #{style_board_6($lo_boards[6][8])} #{style_board_6('|')}#{style_board_7('|')} #{style_board_7($lo_boards[7][6])} #{style_board_7('|')} #{style_board_7($lo_boards[7][7])} #{style_board_7('|')} #{style_board_7($lo_boards[7][8])} #{style_board_7('|')}#{style_board_8('|')} #{style_board_8($lo_boards[8][6])} #{style_board_8('|')} #{style_board_8($lo_boards[8][7])} #{style_board_8('|')} #{style_board_8($lo_boards[8][8])} #{style_board_8('|')}"
    puts "#{style_board_6('-')}" * 13 + "#{style_board_7('-')}" * 13 + "#{style_board_8('-')}" * 13
end

$current_player = "X"
  
 
def style_board_0(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(0)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[0] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[0] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[0] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[0] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[0] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[0] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_1(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(1)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[1] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[1] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[1] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[1] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[1] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[1] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_2(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(2)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[2] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[2] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[2] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[2] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[2] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[2] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_3(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(3)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[3] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[3] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[3] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[3] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[3] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[3] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_4(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(4)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[4] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[4] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[4] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[4] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[4] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[4] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_5(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(5)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[5] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[5] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[5] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[5] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[5] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[5] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_6(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(6)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[6] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[6] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[6] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[6] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[6] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[6] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_7(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(7)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[7] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[7] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[7] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[7] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[7] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[7] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[94m#{char}\e[0m"
    end
  end
end
def style_board_8(char)
  if char != 'O' && char != 'X'
    if $open_boards.include?(8)
      return "\e[32m#{char}\e[0m"
    elsif $glo_board[8] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[8] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return char
    end
  elsif char == 'O'
    if $glo_board[8] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[8] == $hum_player
      return "\e[94m#{char}\e[0m"
    else
      return "\e[91m#{char}\e[0m"
    end
  else
    if $glo_board[8] == $com_player
      return "\e[91m#{char}\e[0m"
    elsif $glo_board[8] == $hum_player
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
      combination.all? { |row, col| $lo_boards[row][col] == player }
    end
  end
  

def get_valid_move
  loop do
    display_board
    puts "Player #{$current_player}, enter your move (board square): "
    input = gets.chomp

    if input.match?(/^\d+\s+\d+$/)
      board, square = input.split.map(&:to_i)
      if board.between?(0, 8) && $open_boards.include?(board) && square.between?(0, 8) && $lo_boards[board][square] == " "
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
    $lo_boards[board][square] = $current_player

    (0..8).each do |i|
      if winning($lo_boards[i], $com_player)
        $glo_board[i] = 'O'
      elsif winning($lo_boards[i], $hum_player)
        $glo_board[i] = 'X'
      elsif all_x_or_o($lo_boards[i])
        $glo_board[i] = 'D'
      else
        $glo_board[i] = i
      end
    end

    if $glo_board[square].is_a?(Numeric) || $glo_board[square] == 'NA'
      (0..8).each do |j|
      $glo_board[j] = 'NA' if $glo_board[j].is_a?(Numeric)
      end
    end

    $glo_board[square] = square if $glo_board[square] == 'NA'
    $open_boards = empty_glo_indices($glo_board)


    if winning($glo_board, $com_player)
      display_board
      puts "Player #{$com_player} wins!"
      game_over = true
    elsif winning($glo_board, $hum_player)
      display_board
      puts "Player #{$hum_player} wins!"
      game_over = true
    elsif all_x_or_o($glo_board)
      display_board
      puts "It's a draw!"
      game_over = true
    else
      $current_player = $current_player == "X" ? "O" : "X"
    end

    ai_player
    if winning($glo_board, $com_player)
      display_board
      puts "Player #{$com_player} wins!"
      game_over = true
    elsif winning($glo_board, $hum_player)
      display_board
      puts "Player #{$hum_player} wins!"
      game_over = true
    elsif all_x_or_o($glo_board)
      display_board
      puts "It's a draw!"
      game_over = true
    else
      $current_player = $current_player == "X" ? "O" : "X"
    end
  end
end

play_game