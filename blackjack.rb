require 'pp'

CARDS = [["2",2],["3",3],["4",4],["5",5],["6",6],["7",7],["8",8],["9",9],["10",10],["J",10],["K",10],["Q",10],["A",0]]

class Player
  attr_accessor :cards, :money, :bet
  def initialize(cards,money)
    @cards = cards
    @money = money
    @bet = 0
    @cur_playing = true
  end

  def lost()
    value() > 21
  end

  def finished()
    @cur_playing = false
  end
  
  def lose_money()
    @money -= @bet
  end

  def blackjack_money()
    @money += @bet*1.5
  end

  def win_money
    @money += @bet
  end

  #calculate value of given hand
  def value()
    @cards.map{|c| c[1]}.inject{|r,cur| r + cur}
  end

  def blackjack()
    value() == 21 && @cards.length == 2
  end



end


class Blackjack

  def initialize()
    @cards = Array.new()
    @players = Array.new()
    @dealer = Array.new()
    setup_game()
  end

  def setup_game()
    #puts "How many players at the table?"
    #@num_players = gets.to_i
    #puts "How many decks of cards are we playing with?"
    #@num_decks = gets.to_i
    @num_players = 4
    @num_decks = 4
    (@num_decks*4).times { @cards += CARDS }
    @cards = @cards.sort_by { rand }

    @num_players.times do |i|
      two_cards = [@cards.pop, @cards.pop]
      p = Player.new(two_cards, 1000)
      @players.push p
    end

    2.times { @dealer.push @cards.pop }

    get_player_bets()
    player_get_ace_values()
    print_state()
    game_loop()
  end

  def get_player_bets()
    @players.each_with_index do |p,i|
      done = false
      while(!done)
        print "Player #{i}, please enter your bet for this round: "
        bet = gets.to_i
        if(bet > 0 && bet <= p.money)
          p.bet = bet
          done = true
        end
      end
    end
  end

  # Handling of aces, player has to decide whether he wants ace to be 1 or 11
  # This is pretty bad code, but I need to go and do coursework....
  def player_get_ace_values()
    puts "calling get ace values"
    @players.each_with_index do |p,i|
      p.cards.each_with_index do |c,i2|
        if c[1] == 0
          done = false
          while(!done)
            puts "Player #{i}, you have an ace. Please fix its value to either 1 or 11: "
            puts "Your current hand is #{p.cards.map{ |c| "(#{c[0]}, value: #{c[1]})"}.join(',')}"
            print "1 or 11: "
            v = gets.to_i
            if (v == 1 || v == 11)
              p.cards[i2][1] = v
              done = true
            end
          end
        end
      end
    end
  end


  def print_state()
    puts "------- CURRENT BOARD STATE ---------"
    puts "DEALER: #{@dealer.join(',')} \n\n"

    @players.each_with_index do |p,i|
      puts "PLAYER #{i}"
      puts "\t money: \t #{p.money}"
      puts "\t bet: \t\t #{p.bet}"
      puts "\t cards: \t #{p.cards.map{ |c| "(#{c[0]}, value: #{c[1]})"}.join(',')}"
    end
    puts "\n------- END CURRENT BOARD STATE ---------"

    pp @cards
  end


  def help()
    puts "available commands for a player: split, double, stand, hit"
  end


  def game_loop()
    cur_player = 0

    # Initial loop to go through players and get their choices
    while(cur_player < @num_players)
      pl = @players[cur_player]
      player_done = false

      while (!player_done)
        print_state()
        print "Player #{cur_player}, what would you like to do: "
        action = gets.chomp
        case action

        when "hit"
          new_card = @cards.pop 
          pl.cards << new_card
          player_get_ace_values if new_card[0] == "A"

        when "split"
          puts "not implemented"

        when "double"
          new_card = @cards.pop
          pl.cards.push new_card
          player_get_ace_values if new_card[0] == "A"
          player_done = true

        when "stand"
          player_done = true

        else
          puts "no such action, try again..."
        end

        if pl.blackjack()
          puts "Player #{cur_player} has a blackjack!"
          pl.blackjack_money()
          pl.finished()
        elsif pl.lost()
          puts "Player #{cur_player}, you lost..."
          pl.lose_money()
          pl.finished()
        end
        player_done = true
      end
        cur_player += 1
    end


  end



end

b = Blackjack.new()
