require 'set'
require_relative 'game_board'

@game_board = GameBoard.new
@lo_boards = @game_board.lo_boards
@glo_board = @game_board.glo_board
@open_boards = @game_board.open_boards
@com_player = @game_board.com_player
@hum_player = @game_board.hum_player

def minimax(glo_mo, lo_mo, los, player, depth, alpha, beta, max_depth)
  score = eval_board(glo_mo, los)
  return { score: score } if depth == max_depth

  glo_board_minimax = []
  los.each_with_index do |lo, i|
    glo_board_minimax[i] = if @game_board.winning(lo, 'O')
                             'O'
                           elsif @game_board.winning(lo, 'X')
                             'X'
                           elsif @game_board.all_x_or_o(lo)
                             'D'
                           else
                             i
                           end
  end

  return { score: score + depth } if @game_board.winning(glo_board_minimax, 'O')
  return { score: score - depth } if @game_board.winning(glo_board_minimax, 'X')

  if glo_board_minimax[lo_mo].is_a?(Numeric) || glo_board_minimax[lo_mo] == 'NA'
    glo_board_minimax.each_with_index do |lo_board_minimax, j|
      glo_board_minimax[j] = 'NA' if lo_board_minimax.is_a?(Numeric)
    end
  end

  glo_board_minimax[lo_mo] = lo_mo if glo_board_minimax[lo_mo] == 'NA'
  open_boards_minimax = @game_board.empty_glo_indices(glo_board_minimax)
  return { score: score } if open_boards_minimax.length.zero?

  empty_spots_in_lo_boards = @game_board.empty_lo_indices(open_boards_minimax, los)
  if player == @hum_player
    max_val = -Float::INFINITY
    best_move = nil
    open_boards_minimax.each do |glo_move|
      empty_spots_in_lo_boards[open_boards_minimax.index(glo_move)].each do |lo_move|
        los[glo_move][lo_move] = 'X'
        result = minimax(glo_move, lo_move, los, @com_player, depth + 1, alpha, beta, max_depth)
        los[glo_move][lo_move] = ' '
        if result[:score] > max_val
          max_val = result[:score]
          best_move = { gloIndex: glo_move, loIndex: lo_move, score: result[:score] }
        end
        alpha = [alpha, max_val].max
        break if beta <= alpha
      end
    end
  else
    min_val = Float::INFINITY
    best_move = nil
    open_boards_minimax.each do |glo_move|
      empty_spots_in_lo_boards[open_boards_minimax.index(glo_move)].each do |lo_move|
        los[glo_move][lo_move] = 'O'
        result = minimax(glo_move, lo_move, los, @hum_player, depth + 1, alpha, beta, max_depth)
        los[glo_move][lo_move] = ' '
        if result[:score] < min_val
          min_val = result[:score]
          best_move = { gloIndex: glo_move, loIndex: lo_move, score: result[:score] }
        end
        beta = [beta, min_val].min
        break if beta <= alpha
      end
    end
  end
  best_move
end

def eval_board(current, los)
  all_winning_combos = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
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
    if @game_board.winning(lo, 'O')
      glo[i] = 'O'
      score -= position_scores[i] * 150
    elsif @game_board.winning(lo, 'X')
      glo[i] = 'X'
      score += position_scores[i] * 150
    elsif @game_board.all_x_or_o(lo)
      glo[i] = 'D'
    else
      glo[i] = i
    end
  end

  score -= 50_000 if @game_board.winning(glo, @com_player)
  score += 50_000 if @game_board.winning(glo, @hum_player)

  9.times do |i|
    9.times do |j|
      score_adjustment = if los[i][j] == @com_player
                           i == current ? -position_scores[j] * 1.5 * lo_board_weightings[i] : -position_scores[j] * lo_board_weightings[i]
                         elsif los[i][j] == @hum_player
                           i == current ? position_scores[j] * 1.5 * lo_board_weightings[i] : position_scores[j] * lo_board_weightings[i]
                         end
      score += score_adjustment if score_adjustment
    end

    row_scores = Set.new
    all_winning_combos.each do |combo|
      lo_arr = [los[i][combo[0]], los[i][combo[1]], los[i][combo[2]]]
      row_score_val = row_score(lo_arr)
      next if row_scores.include?(row_score_val)

      if (combo[0].zero? && combo[1] == 4 && combo[2] == 8) || (combo[0] == 2 && combo[1] == 4 && combo[2] == 6)
        if [-6, 6].include? row_score_val
          score_adjustment = if i == current
                               row_score_val * 1.2 * 1.5 * lo_board_weightings[i]
                             else
                               row_score_val * 1.2 * lo_board_weightings[i]
                             end
          score += score_adjustment if score_adjustment
        end
      else
        score_adjustment = if i == current
                             row_score_val * 1.5 * lo_board_weightings[i]
                           else
                             row_score_val * lo_board_weightings[i]
                           end
        score += score_adjustment if score_adjustment
      end
      row_scores.add(row_score_val)
    end
  end

  row_scores = Set.new
  all_winning_combos.each do |combo|
    glo_arr = [glo[combo[0]], glo[combo[1]], glo[combo[2]]]
    row_score_val = row_score(glo_arr)
    next if row_scores.include?(row_score_val)

    if (combo[0].zero? && combo[1] == 4 && combo[2] == 8) || (combo[0] == 2 && combo[1] == 4 && combo[2] == 6)
      score += row_score_val * 1.2 * 150 if [-6, 6].include? row_score_val

    else
      score += row_score_val * 150
    end
    row_scores.add(row_score_val)
  end

  score
end

def ai_player
  empty_spots_in_lo_boards = @game_board.empty_lo_indices(@open_boards, @lo_boards)
  minimum_score = Float::INFINITY
  board = nil
  square = nil
  @open_boards.length.times do |o|
    empty_spots_in_lo_boards[o].length.times do |i|
      glo_move = @open_boards[o]
      lo_move = empty_spots_in_lo_boards[o][i]
      @lo_boards[glo_move][lo_move] = 'O'
      result = minimax(glo_move, lo_move, @lo_boards, @hum_player, 0, -Float::INFINITY, Float::INFINITY, 4)
      @lo_boards[glo_move][lo_move] = ' '
      next unless result[:score] < minimum_score

      minimum_score = result[:score]
      board = glo_move
      square = lo_move
    end
  end

  @lo_boards[board][square] = 'O'

  @glo_board = @lo_boards.map.with_index do |lo_board, i|
    if @game_board.winning(lo_board, @com_player)
      'O'
    elsif @game_board.winning(lo_board, @hum_player)
      'X'
    elsif @game_board.all_x_or_o(lo_board)
      'D'
    else
      i
    end
  end

  if @glo_board[square].is_a?(Numeric) || @glo_board[square] == 'NA'
    @glo_board.each_with_index do |lo_board, i|
      @glo_board[i] = 'NA' if lo_board.is_a?(Numeric)
    end
  end

  @glo_board[square] = square if @glo_board[square] == 'NA'
  @open_boards = @game_board.empty_glo_indices(@glo_board)
end

def display_board
  puts style_board('-', 0) * 13 + style_board('-', 1) * 13 + style_board('-', 2) * 13
  puts "#{style_board('|',
                      0)} #{style_board(@lo_boards[0][0],
                                        0)} #{style_board('|',
                                                          0)} #{style_board(@lo_boards[0][1],
                                                                            0)} #{style_board('|',
                                                                                              0)} #{style_board(@lo_boards[0][2],
                                                                                                                0)} #{style_board('|',
                                                                                                                                  0)}#{style_board('|',
                                                                                                                                                   1)} #{style_board(@lo_boards[1][0],
                                                                                                                                                                     1)} #{style_board('|',
                                                                                                                                                                                       1)} #{style_board(@lo_boards[1][1],
                                                                                                                                                                                                         1)} #{style_board('|',
                                                                                                                                                                                                                           1)} #{style_board(@lo_boards[1][2],
                                                                                                                                                                                                                                             1)} #{style_board('|',
                                                                                                                                                                                                                                                               1)}#{style_board('|',
                                                                                                                                                                                                                                                                                2)} #{style_board(@lo_boards[2][0],
                                                                                                                                                                                                                                                                                                  2)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    2)} #{style_board(@lo_boards[2][1],
                                                                                                                                                                                                                                                                                                                                      2)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 2
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[2][2], 2
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 2
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 0) * 13 + style_board('-', 1) * 13 + style_board('-', 2) * 13
  puts "#{style_board('|',
                      0)} #{style_board(@lo_boards[0][3],
                                        0)} #{style_board('|',
                                                          0)} #{style_board(@lo_boards[0][4],
                                                                            0)} #{style_board('|',
                                                                                              0)} #{style_board(@lo_boards[0][5],
                                                                                                                0)} #{style_board('|',
                                                                                                                                  0)}#{style_board('|',
                                                                                                                                                   1)} #{style_board(@lo_boards[1][3],
                                                                                                                                                                     1)} #{style_board('|',
                                                                                                                                                                                       1)} #{style_board(@lo_boards[1][4],
                                                                                                                                                                                                         1)} #{style_board('|',
                                                                                                                                                                                                                           1)} #{style_board(@lo_boards[1][5],
                                                                                                                                                                                                                                             1)} #{style_board('|',
                                                                                                                                                                                                                                                               1)}#{style_board('|',
                                                                                                                                                                                                                                                                                2)} #{style_board(@lo_boards[2][3],
                                                                                                                                                                                                                                                                                                  2)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    2)} #{style_board(@lo_boards[2][4],
                                                                                                                                                                                                                                                                                                                                      2)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 2
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[2][5], 2
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 2
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 0) * 13 + style_board('-', 1) * 13 + style_board('-', 2) * 13
  puts "#{style_board('|',
                      0)} #{style_board(@lo_boards[0][6],
                                        0)} #{style_board('|',
                                                          0)} #{style_board(@lo_boards[0][7],
                                                                            0)} #{style_board('|',
                                                                                              0)} #{style_board(@lo_boards[0][8],
                                                                                                                0)} #{style_board('|',
                                                                                                                                  0)}#{style_board('|',
                                                                                                                                                   1)} #{style_board(@lo_boards[1][6],
                                                                                                                                                                     1)} #{style_board('|',
                                                                                                                                                                                       1)} #{style_board(@lo_boards[1][7],
                                                                                                                                                                                                         1)} #{style_board('|',
                                                                                                                                                                                                                           1)} #{style_board(@lo_boards[1][8],
                                                                                                                                                                                                                                             1)} #{style_board('|',
                                                                                                                                                                                                                                                               1)}#{style_board('|',
                                                                                                                                                                                                                                                                                2)} #{style_board(@lo_boards[2][6],
                                                                                                                                                                                                                                                                                                  2)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    2)} #{style_board(@lo_boards[2][7],
                                                                                                                                                                                                                                                                                                                                      2)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 2
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[2][8], 2
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 2
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 0) * 13 + style_board('-', 1) * 13 + style_board('-', 2) * 13
  puts style_board('-', 3) * 13 + style_board('-', 4) * 13 + style_board('-', 5) * 13
  puts "#{style_board('|',
                      3)} #{style_board(@lo_boards[3][0],
                                        3)} #{style_board('|',
                                                          3)} #{style_board(@lo_boards[3][1],
                                                                            3)} #{style_board('|',
                                                                                              3)} #{style_board(@lo_boards[3][2],
                                                                                                                3)} #{style_board('|',
                                                                                                                                  3)}#{style_board('|',
                                                                                                                                                   4)} #{style_board(@lo_boards[4][0],
                                                                                                                                                                     4)} #{style_board('|',
                                                                                                                                                                                       4)} #{style_board(@lo_boards[4][1],
                                                                                                                                                                                                         4)} #{style_board('|',
                                                                                                                                                                                                                           4)} #{style_board(@lo_boards[4][2],
                                                                                                                                                                                                                                             4)} #{style_board('|',
                                                                                                                                                                                                                                                               4)}#{style_board('|',
                                                                                                                                                                                                                                                                                5)} #{style_board(@lo_boards[5][0],
                                                                                                                                                                                                                                                                                                  5)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    5)} #{style_board(@lo_boards[5][1],
                                                                                                                                                                                                                                                                                                                                      5)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 5
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[5][2], 5
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 5
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 3) * 13 + style_board('-', 4) * 13 + style_board('-', 5) * 13
  puts "#{style_board('|',
                      3)} #{style_board(@lo_boards[3][3],
                                        3)} #{style_board('|',
                                                          3)} #{style_board(@lo_boards[3][4],
                                                                            3)} #{style_board('|',
                                                                                              3)} #{style_board(@lo_boards[3][5],
                                                                                                                3)} #{style_board('|',
                                                                                                                                  3)}#{style_board('|',
                                                                                                                                                   4)} #{style_board(@lo_boards[4][3],
                                                                                                                                                                     4)} #{style_board('|',
                                                                                                                                                                                       4)} #{style_board(@lo_boards[4][4],
                                                                                                                                                                                                         4)} #{style_board('|',
                                                                                                                                                                                                                           4)} #{style_board(@lo_boards[4][5],
                                                                                                                                                                                                                                             4)} #{style_board('|',
                                                                                                                                                                                                                                                               4)}#{style_board('|',
                                                                                                                                                                                                                                                                                5)} #{style_board(@lo_boards[5][3],
                                                                                                                                                                                                                                                                                                  5)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    5)} #{style_board(@lo_boards[5][4],
                                                                                                                                                                                                                                                                                                                                      5)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 5
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[5][5], 5
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 5
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 3) * 13 + style_board('-', 4) * 13 + style_board('-', 5) * 13
  puts "#{style_board('|',
                      3)} #{style_board(@lo_boards[3][6],
                                        3)} #{style_board('|',
                                                          3)} #{style_board(@lo_boards[3][7],
                                                                            3)} #{style_board('|',
                                                                                              3)} #{style_board(@lo_boards[3][8],
                                                                                                                3)} #{style_board('|',
                                                                                                                                  3)}#{style_board('|',
                                                                                                                                                   4)} #{style_board(@lo_boards[4][6],
                                                                                                                                                                     4)} #{style_board('|',
                                                                                                                                                                                       4)} #{style_board(@lo_boards[4][7],
                                                                                                                                                                                                         4)} #{style_board('|',
                                                                                                                                                                                                                           4)} #{style_board(@lo_boards[4][8],
                                                                                                                                                                                                                                             4)} #{style_board('|',
                                                                                                                                                                                                                                                               4)}#{style_board('|',
                                                                                                                                                                                                                                                                                5)} #{style_board(@lo_boards[5][6],
                                                                                                                                                                                                                                                                                                  5)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    5)} #{style_board(@lo_boards[5][7],
                                                                                                                                                                                                                                                                                                                                      5)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 5
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[5][8], 5
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 5
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 3) * 13 + style_board('-', 4) * 13 + style_board('-', 5) * 13
  puts style_board('-', 6) * 13 + style_board('-', 7) * 13 + style_board('-', 8) * 13
  puts "#{style_board('|',
                      6)} #{style_board(@lo_boards[6][0],
                                        6)} #{style_board('|',
                                                          6)} #{style_board(@lo_boards[6][1],
                                                                            6)} #{style_board('|',
                                                                                              6)} #{style_board(@lo_boards[6][2],
                                                                                                                6)} #{style_board('|',
                                                                                                                                  6)}#{style_board('|',
                                                                                                                                                   7)} #{style_board(@lo_boards[7][0],
                                                                                                                                                                     7)} #{style_board('|',
                                                                                                                                                                                       7)} #{style_board(@lo_boards[7][1],
                                                                                                                                                                                                         7)} #{style_board('|',
                                                                                                                                                                                                                           7)} #{style_board(@lo_boards[7][2],
                                                                                                                                                                                                                                             7)} #{style_board('|',
                                                                                                                                                                                                                                                               7)}#{style_board('|',
                                                                                                                                                                                                                                                                                8)} #{style_board(@lo_boards[8][0],
                                                                                                                                                                                                                                                                                                  8)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    8)} #{style_board(@lo_boards[8][1],
                                                                                                                                                                                                                                                                                                                                      8)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 8
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[8][2], 8
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 8
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 6) * 13 + style_board('-', 7) * 13 + style_board('-', 8) * 13
  puts "#{style_board('|',
                      6)} #{style_board(@lo_boards[6][3],
                                        6)} #{style_board('|',
                                                          6)} #{style_board(@lo_boards[6][4],
                                                                            6)} #{style_board('|',
                                                                                              6)} #{style_board(@lo_boards[6][5],
                                                                                                                6)} #{style_board('|',
                                                                                                                                  6)}#{style_board('|',
                                                                                                                                                   7)} #{style_board(@lo_boards[7][3],
                                                                                                                                                                     7)} #{style_board('|',
                                                                                                                                                                                       7)} #{style_board(@lo_boards[7][4],
                                                                                                                                                                                                         7)} #{style_board('|',
                                                                                                                                                                                                                           7)} #{style_board(@lo_boards[7][5],
                                                                                                                                                                                                                                             7)} #{style_board('|',
                                                                                                                                                                                                                                                               7)}#{style_board('|',
                                                                                                                                                                                                                                                                                8)} #{style_board(@lo_boards[8][3],
                                                                                                                                                                                                                                                                                                  8)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    8)} #{style_board(@lo_boards[8][4],
                                                                                                                                                                                                                                                                                                                                      8)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 8
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[8][5], 8
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 8
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 6) * 13 + style_board('-', 7) * 13 + style_board('-', 8) * 13
  puts "#{style_board('|',
                      6)} #{style_board(@lo_boards[6][6],
                                        6)} #{style_board('|',
                                                          6)} #{style_board(@lo_boards[6][7],
                                                                            6)} #{style_board('|',
                                                                                              6)} #{style_board(@lo_boards[6][8],
                                                                                                                6)} #{style_board('|',
                                                                                                                                  6)}#{style_board('|',
                                                                                                                                                   7)} #{style_board(@lo_boards[7][6],
                                                                                                                                                                     7)} #{style_board('|',
                                                                                                                                                                                       7)} #{style_board(@lo_boards[7][7],
                                                                                                                                                                                                         7)} #{style_board('|',
                                                                                                                                                                                                                           7)} #{style_board(@lo_boards[7][8],
                                                                                                                                                                                                                                             7)} #{style_board('|',
                                                                                                                                                                                                                                                               7)}#{style_board('|',
                                                                                                                                                                                                                                                                                8)} #{style_board(@lo_boards[8][6],
                                                                                                                                                                                                                                                                                                  8)} #{style_board('|',
                                                                                                                                                                                                                                                                                                                    8)} #{style_board(@lo_boards[8][7],
                                                                                                                                                                                                                                                                                                                                      8)} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 8
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        @lo_boards[8][8], 8
                                                                                                                                                                                                                                                                                                                                      )} #{style_board(
                                                                                                                                                                                                                                                                                                                                        '|', 8
                                                                                                                                                                                                                                                                                                                                      )}"
  puts style_board('-', 6) * 13 + style_board('-', 7) * 13 + style_board('-', 8) * 13
end

@current_player = 'X'

def style_board(char, index)
  if char != 'O' && char != 'X'
    if @open_boards.include?(index)
      "\e[32m#{char}\e[0m"
    elsif @glo_board[index] == @com_player
      "\e[91m#{char}\e[0m"
    elsif @glo_board[index] == @hum_player
      "\e[94m#{char}\e[0m"
    else
      char
    end
  elsif char == 'O'
    if @glo_board[index] == @com_player
      "\e[91m#{char}\e[0m"
    elsif @glo_board[index] == @hum_player
      "\e[94m#{char}\e[0m"
    else
      "\e[91m#{char}\e[0m"
    end
  elsif @glo_board[index] == @com_player
    "\e[91m#{char}\e[0m"
  elsif @glo_board[index] == @hum_player
    "\e[94m#{char}\e[0m"
  else
    "\e[94m#{char}\e[0m"
  end
end

def valid_move
  loop do
    display_board
    puts "Player #{@current_player}, enter your move (board square): "
    input = gets.chomp

    if input.match?(/^\d+\s+\d+$/)
      board, square = input.split.map(&:to_i)
      if board.between?(0,
                        8) && @open_boards.include?(board) && square.between?(0, 8) && @lo_boards[board][square] == ' '
        return [board, square]
      end
    end
    puts 'Invalid move. Please try again.'
  end
end

def play_game
  game_over = false
  until game_over
    board, square = valid_move
    @lo_boards[board][square] = @current_player
    @lo_boards.each_with_index do |lo_board, i|
      @glo_board[i] = if @game_board.winning(lo_board, 'O')
                        'O'
                      elsif @game_board.winning(lo_board, 'X')
                        'X'
                      elsif @game_board.all_x_or_o(lo_board)
                        'D'
                      else
                        i
                      end
    end
    if @glo_board[square].is_a?(Numeric) || @glo_board[square] == 'NA'
      @glo_board.each_with_index do |lo_board, i|
        @glo_board[i] = 'NA' if lo_board.is_a?(Numeric)
      end
    end
    @glo_board[square] = square if @glo_board[square] == 'NA'
    @open_boards = @game_board.empty_glo_indices(@glo_board)
    if @game_board.winning(@glo_board, @com_player)
      display_board
      puts "Player #{@com_player} wins!"
      game_over = true
    elsif @game_board.winning(@glo_board, @hum_player)
      display_board
      puts "Player #{@hum_player} wins!"
      game_over = true
    elsif @game_board.all_x_or_o(@glo_board)
      display_board
      puts "It's a draw!"
      game_over = true
    else
      @current_player = @current_player == 'X' ? 'O' : 'X'
    end
    ai_player
    if @game_board.winning(@glo_board, @com_player)
      display_board
      puts "Player #{@com_player} wins!"
      game_over = true
    elsif @game_board.winning(@glo_board, @hum_player)
      display_board
      puts "Player #{@hum_player} wins!"
      game_over = true
    elsif @game_board.all_x_or_o(@glo_board)
      display_board
      puts "It's a draw!"
      game_over = true
    else
      @current_player = @current_player == 'X' ? 'O' : 'X'
    end
  end
end

play_game
