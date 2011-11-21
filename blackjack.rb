CARDS = [2,3,4,5,6,7,8,9,10,"J","K","Q","A"]

class Player
  attr_accessor :cards, :money, :bet, :cur_playing, :index
  def initialize(cards,money,index)
    @cards = cards
    @money = money
    @bet = 0
    @cur_playing = true  # Indicates whether the player is currently in-game
    @index = index
  end

  def reset()
    @cards = Array.new
    @bet = 0
    @cur_playing = true
  end

end


class Blackjack

  def initialize()
    @cards = Array.new()
    @players = Array.new()
    @dealer = Array.new() # Dealer's cards
    game_loop()
  end

  # Calculates the value of a hand
  # If Ace is present, assume 11 unless it makes the hand go over 21
  # I think that's how it works in Blackjack
  def value(hand)
    # Sorting hack to get aces at the very end so we count them last
    hand.sort_by { |c| c.to_i != 0 ? c : c[0] - 81 }.reverse().inject(0) do |total,cur|
      if cur.to_i != 0
        total + cur # 2-10 case
      elsif ["J","Q","K"].include? cur
        total + 10 # J,Q, or K
      elsif cur == "A"
        if (total+11) > 21
          total + 1 # Count ace as 1
        else
          total+11 # Count ace as 11
        end
      end
    end
  end

  # Returns true if the hand is a blackjack
  def blackjack(hand)
    value(hand) == 21 && hand.length == 2
  end

  # Credits the player if he wins the round
  def credit_player(p, blackjack = false)
    if blackjack
      p.money += p.bet*1.5
    else
      p.money += p.bet
    end
  end

  # Player loses his bet if he lost
  def debit_player(p)
    p.money -= p.bet
  end

  # Sets up one game...
  def setup_game()
    @players.each { |p| p.reset() } # Reset the player
    @cards = Array.new # Reset cards 
    @dealer = Array.new # Reset dealer cards
    (@num_decks*4).times { @cards += CARDS }
    puts "Shuffling cards...."
    @cards = @cards.sort_by { rand } # Hack to shuffle. Ruby 1.9 has shuffling built-in!

    @players.find_all { |p| p.money <= 0}.each do |p|
      puts "Player #{p.index} is out of money, removing from game..."
    end
    @players.reject! { |p| p.money <= 0}
    if @players.length == 0
      puts "Everybody is out of money, quitting game..."
      exit()
    end


    @players.each do |p|
      p.cards = [@cards.pop, @cards.pop]
    end

    puts "Dealer taking cards...."
    2.times { @dealer.push @cards.pop }

    get_player_bets()
  end


  def table_setup()
    puts "How many players at the table?"
    @num_players = gets.to_i
    puts "How many decks of cards are we playing with?"
    @num_decks = gets.to_i

    # Initialize the players....
    @num_players.times do |i|
      p = Player.new(Array.new, 1000, i)
      @players.push p
    end

  end

  def get_player_bets()
    @players.each do |p|
      done = false
      while(!done)
        print "Player #{p.index}, please enter your bet for this round: "
        bet = gets.to_i
        if(bet > 0 && bet <= p.money)
          p.bet = bet
          done = true
        end
      end
    end
  end

  def print_state()
    puts "------- CURRENT BOARD STATE ---------"
    puts "DEALER: #{@dealer[0]}, X \n\n"

    @players.each do |p|
      puts "PLAYER #{p.index} \t #{p.cur_playing ? "(in game)" : "(lost)"}"
      puts "\t money: \t #{p.money}"
      puts "\t bet: \t\t #{p.bet}"
      puts "\t cards: \t #{p.cards.join(',')}"
      puts "\t value: \t #{value p.cards}"
    end
    puts "\n------- END CURRENT BOARD STATE ---------"
  end


  def help()
    puts "available commands for a player: split, double, stand, hit"
  end

  def dealer_reveal_cards()
    puts "Delear reveals his second card...."
    puts "Dealers cards are #{@dealer.join(',')}"

    d = value(@dealer)
    # Dealer hits on <= 16
    while d < 17
      puts "Dealer takes a new card..."
      @dealer << @cards.pop
      puts "Dealers' cards are #{@dealer.join(',')}"
      d = value(@dealer)
    end

    # By now,  17 <= value(@dealer) <= 26
  end


  # This runs after the initial round, and after the dealer reveals his cards
  # We compare the hand of the dealer with every players hands, and act accordingly
  def final_round()
    d = value(@dealer)
    puts "--- Check Round --- "
    puts "Dealers' cards are #{@dealer.join(',')} for a value #{d}"

    # Iterate over all players who are still in the game,
    # as in they haven't lost in the initial round doing 'hits'
    #
    # Precondition: forall p in players where p.cur_playing == false, value(p.cards) <= 21
    @players.find_all{|p| p.cur_playing}.each do |p|
      if value(p.cards) < d && d <= 21 # Dealer Wins
        puts "Player #{p.index} has deck worth #{value p.cards}, and loses to the dealer..."
        debit_player(p)
      elsif (value(p.cards) > d && d <= 21) || d > 21  # Player Wins
        puts "Player #{p.index} has deck worth #{value p.cards}, and wins with the dealer..."
        credit_player(p)
      elsif value(p.cards) == d
        puts "Player #{p.index} has deck worth #{value p.cards}, and draws with the dealer..."
      end
    end
  end


  # Main game loop
  def game_loop()
    table_setup() # Get num players and number of decks to use

    while true
      puts "----- STARTING A NEW GAME ------"
      setup_game()    # Shuffle cards, etc...
      one_game_loop() # Have one game
    end 

  end



  # Loop for one game of blackjack
  def one_game_loop()

    # Initial loop to go through players and get their choices
    @players.each do |pl|
      playing = true

      while (playing)
        print_state()

        # Check if player has a blackjack at the very beginning
        if blackjack(pl.cards)
          puts "Player #{pl.index} has a blackjack!"
          credit_player(pl,blackjack=true)
          playing = false
          pl.cur_playing = false    # Player has already won, don't include in final round
          next
        end

        print "Player #{pl.index}, what would you like to do: "
        action = gets.chomp

        case action
        when "hit"
          new_card = @cards.pop 
          pl.cards << new_card
        when "split"
          puts "not implemented, I have to go do homework!"
        when "double"
          new_card = @cards.pop
          pl.cards << new_card
          playing = false
        when "stand"
          playing = false
        else
          puts "no such action, try again..."
        end

        if value(pl.cards) > 21 # Lost :(
          puts "Player #{pl.index}, you lost..."
          debit_player(pl)
          playing = false
          pl.cur_playing = false    # Player has already lost, don't inlude in final round
        elsif value(pl.cards) == 21 # 21, but not blackjack, so maybe we draw with the dealer, we check later
          puts "Player #{pl.index} has 21 points - we await for the final round to compare with the dealer"
          playing = false
        end
      end
    end

    # By this point, the first round is finished. Dealer starts revealing cards...
    
    dealer_reveal_cards()
    final_round()

  end
end

b = Blackjack.new()
