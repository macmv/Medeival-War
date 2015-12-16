#! /usr/local/bin/ruby

require "gosu"
require "yaml"
require "./gosu_library.rb"
require "set"

class Set

  def [](thing)
    
  end

end

class Node

  attr_reader :x, :y, :parent

  def initialize(x, y, parent)
    @x = x
    @y = y
    @parent = parent
  end

  def ==(other)
    return false if other.class != Node
    @x.to_i == other.x.to_i && @y.to_i == other.y.to_i
  end

  def eql?(other)
    self == other
  end

  def hash
    [@x, @y].hash
  end

  def to_s
    return "Node <@x = #{@x}, @y = #{@y}, @parent = #{@parent.inspect}>"
  end
end

def find_path(x, y, grid, enemy = nil)
  end_loc = Node.new(enemy.x, enemy.y, nil) if enemy != nil
  start_loc = Node.new(x, y, nil)
  if enemy == nil
    grid.each_with_index do |row, y|
      row.each_with_index do |item, x|
        if item.type == "king"
          end_loc = Node.new(x, y, nil)
          break
        end
      end
    end
  end
  if end_loc == nil || start_loc == nil
    return nil
  end
  tip_nodes = [start_loc]
  explored_locs = Set.new
  until tip_nodes.length == 0
    new_tip_nodes = []
    tip_nodes.each do |node|
      extentions = [Node.new(node.x, node.y - 1, node), # up
                    Node.new(node.x, node.y + 1, node), # down
                    Node.new(node.x + 1, node.y, node), # right
                    Node.new(node.x - 1, node.y, node)] # left
      extentions.each do |extention|
        if (extention.y >= 0 && extention.y < MedivalWar::HEIGHT / MedivalWar::BLOCKSIZE &&
           extention.x >= 0 && extention.x     < MedivalWar::WIDTH  / MedivalWar::BLOCKSIZE &&
           grid[extention.y][extention.x].type != "wall" &&
           grid[extention.y][extention.x].type != "forge" &&
           grid[extention.y][extention.x].type != "iron_mine" &&
           grid[extention.y][extention.x].type != "gold_mine" &&
           !explored_locs.include?(extention))
          new_tip_nodes.push extention
          explored_locs.add extention
        end
      end
      path = []
      if node == end_loc
        until node.nil?
          path.push Node.new(node.x, node.y, nil)
          node = node.parent
        end
        path.reverse
        return path
      end
    end
    tip_nodes = new_tip_nodes
  end
  puts
  nil
end

module MedivalWar

private

WIDTH = 800
HEIGHT = 600
BLOCKSIZE = 40

IRON = 0
GOLD = 100

class Board

  attr_reader :scroll_x, :scroll_y, :grid

  def initialize
    #begin
    #  @grid = File.read("data/board.yaml")
    #  @grid = YAML::load @grid
    #rescue # data and/or board do not exist
      @grid = []
      100.times do |y|
        new_row = []
        100.times do |x|
          new_row.push Grass.new x, y
        end
        @grid.push new_row
      end
      @grid[10][10] = Wall.new 10, 10
      @grid[10][12] = Wall.new 12, 10
      @grid[11][10] = Wall.new 10, 11
      @grid[11][11] = King.new 11, 11
      @grid[11][12] = Wall.new 12, 11
      @grid[12][10] = Wall.new 10, 12
      @grid[12][11] = Wall.new 11, 12
      @grid[12][12] = Wall.new 12, 12
      #begin
      #  Dir.mkdir "data"
      #rescue
      #end
      #File.open("data/board.yaml", "w") { |f| f.write @grid.to_yaml }
    #end
    @ms_middle_down_click_x = nil
    @ms_middle_down_click_x = nil
    @scroll_x = 0
    @scroll_y = -60
    @mode = :build
    @moving_things = Set.new
    @moving_things.add Attacker.new 11, 10, 10, @grid
  end

  def draw
    Gosu::translate(-@scroll_x, -@scroll_y) do
      @grid.each do |row|
        row.each do |item|
          item.draw
        end
      end
      @moving_things.each do |thing|
        thing.draw
      end
    end
  end

  def update(mouse_x, mouse_y, seconds, menu)
    if @ms_middle_down_click_x != nil && @ms_middle_down_click_y != nil
      @scroll_x -= mouse_x - @ms_middle_down_click_x
      @scroll_y -= mouse_y - @ms_middle_down_click_y
    end
    to_delete_items = []
    @grid.each do |row|
      row.each do |item|
        thing = item.update seconds
        if thing.class == String
          menu.add_one_item thing
        elsif thing == :dead
          to_delete_items.push [thing.x, thing.y]
        end
      end
    end
    to_delete_items.each do |item|
      @grid[item[1]][item[0]] = Grass.new item[0], item[1]
    end
    enemies = Set.new
    people = Set.new
    @moving_things.each do |thing|
      if thing.class == Enemy
        enemies.add thing
      else
        people.add thing
      end
    end
    if @mode == :fight
      things_to_delete = Set.new
      @moving_things.each do |thing|
        dead = :not_dead
        if thing.class == Enemy
          dead = thing.update seconds, people
        else
          dead = thing.update seconds, enemies
        end
        if dead == :die
          things_to_delete.add thing
        end
      end
      things_to_delete.each do |item|
        @moving_things.delete item
      end
    end
  end

  def ms_middle_down(mouse_x, mouse_y)
    @ms_middle_down_click_x = mouse_x
    @ms_middle_down_click_y = mouse_y
  end

  def ms_middle_up
    @ms_middle_down_click_x = nil
    @ms_middle_down_click_y = nil
  end

  def set_block(x, y, type)
    if x >= 0 && x < 100 && y >= 0 && y < 100
      if type == "wall"
        if @grid[y][x].class == Wall
          return false
        end
        @grid[y][x] = Wall.new x, y
      elsif type == "grass"
        if @grid[y][x].class == Grass
          return false
        end
        @grid[y][x] = Grass.new x, y
      elsif type == "forge"
        if @grid[y][x].class == Forge
          return false
        end
        @grid[y][x] = Forge.new x, y
      elsif type == "attacker"
        if @grid[y][x].class == Attacker
          return false
        end
        @moving_things.add Attacker.new x, y, 10, @grid
      elsif type == "defender"
        if @grid[y][x].class == Defender
          return false
        end
        @moving_things.add Defender.new x, y, 10, @grid
      elsif type == "gold_mine"
        if @grid[y][x].class == GoldMine
          return false
        end
        @grid[y][x] = GoldMine.new x, y
      elsif type == "iron_mine"
        if @grid[y][x].class == IronMine
          return false
        end
        @grid[y][x] = IronMine.new x, y
      end
    end
    true
  end

  def set_forge_type(x, y, type)
    @grid[y][x].set_return_type type
  end

  def type_of_block(x, y)
    @moving_things.each do |thing|
      if thing.x.to_i == x.to_i && thing.y.to_i == y.to_i
        return thing.type
      end
    end
    @grid[y][x].type
  end

  def switch
    if @mode == :build
      @mode = :fight
    else
      @mode = :build
      # delete all enemies
      things_to_delete = Set.new
      @moving_things.each do |thing|
        if thing.class.superclass == Enemy
          things_to_delete.add thing
        end
      end
      things_to_delete.each do |thing|
        @moving_things.delete thing
      end
    end
    @moving_things.each do |thing|
      thing.set_mode @mode
    end
  end

  def spawn(enemies)
    enemies.each do |enemy|
      @moving_things.add enemy
    end
  end

end

class Menu

  def initialize(time_left_until_switch)
    @statice = "home"
    @font = Gosu::Font.new 20
    @data = {"wall nums" => 10,
             "grass nums" => 10,
             "forge nums" => 5,
             "gold_mine nums" => 5,
             "iron_mine nums" => 5,
             "attacker nums" => 5,
             "defender nums" => 5}
    @images = {"wall" => Gosu::Image.new("images/wall.png"),
               "grass" => Gosu::Image.new("images/grass.png"),
               "forge" => Gosu::Image.new("images/forge.png"),
               "gold_coin" => Gosu::Image.new("images/coin.png"),
               "gold_mine" => Gosu::Image.new("images/gold mine.png"),
               "iron_coin" => Gosu::Image.new("images/iron coin.png"),
               "iron_mine" => Gosu::Image.new("images/iron mine.png"),
               "person" => Gosu::Image.new("images/person.png")}
    @thing_in_hand = nil
    @mouse_is_down = false
    @right_click_down = false
    @mode = :build
    @time_left_until_switch = time_left_until_switch
  end

  def draw(mouse_x, mouse_y)
    draw_rect(0, 0, WIDTH, 60, 0xff_444444)
    if @statice == "home"
      @font.draw("#{@data['wall nums']}", 10, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["wall"].draw(10, 10, 0)
      @font.draw("wall", 10, 50, 0, 0.5, 0.5, 0xff_ffffff)
      @font.draw("#{@data['grass nums']}", 70, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["grass"].draw(70, 10, 0)
      @font.draw("grass", 70, 50, 0, 0.5, 0.5, 0xff_ffffff)
      @font.draw("#{@data['forge nums']}", 130, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["forge"].draw(130, 10, 0)
      @font.draw("forge", 130, 50, 0, 0.5, 0.5, 0xff_ffffff)
      @font.draw("#{@data['gold_mine nums']}", 190, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["gold_mine"].draw(190, 10, 0)
      @font.draw("gold mine", 190, 50, 0, 0.5, 0.5, 0xff_ffffff)
      @font.draw("#{@data['iron_mine nums']}", 250, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["iron_mine"].draw(250, 10, 0)
      @font.draw("iron mine", 250, 50, 0, 0.5, 0.5, 0xff_ffffff)
      @font.draw("#{@data['attacker nums']}", 310, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["person"].draw(310, 25, 0)
      @font.draw("attacker", 310, 50, 0, 0.5, 0.5, 0xff_ffffff)
      @font.draw("#{@data['defender nums']}", 370, 0, 0, 0.5, 0.5, 0xff_ffffff)
      @images["person"].draw(370, 25, 0)
      @font.draw("defender", 370, 50, 0, 0.5, 0.5, 0xff_ffffff)
    elsif (@statice =~ /^\d+ \d+ .+$/) == 0
      new_statice = @statice.split " "
      x = new_statice[0]
      y = new_statice[1]
      type = new_statice[2]
      if type == "grass"
        @statice = "home"
      elsif type == "person"
        @images["person"].draw(10, 10, 0)
        @font.draw("defender", 10, 50, 0, 0.5, 0.5, 0xff_ffffff)
        @images["person"].draw(70, 10, 0)
        @font.draw("attacker", 70, 50, 0, 0.5, 0.5, 0xff_ffffff)
      elsif type == "forge"
        @images["wall"].draw(10, 10, 0)
        @font.draw("wall", 10, 50, 0, 0.5, 0.5, 0xff_ffffff)
        @images["grass"].draw(70, 10, 0)
        @font.draw("grass", 70, 50, 0, 0.5, 0.5, 0xff_ffffff)
        @images["forge"].draw(130, 10, 0)
        @font.draw("forge", 130, 50, 0, 0.5, 0.5, 0xff_ffffff)
        @images["gold_mine"].draw(190, 10, 0)
        @font.draw("gold mine", 190, 50, 0, 0.5, 0.5, 0xff_ffffff)
        @images["iron_mine"].draw(250, 10, 0)
        @font.draw("iron mine", 250, 50, 0, 0.5, 0.5, 0xff_ffffff)
        @images["person"].draw(310, 25, 0)
        @font.draw("attacker", 310, 50, 0, 0.5, 0.5, 0xff_ffffff)
      end
    end
    @font.draw_rel("#{MedivalWar::GOLD}", WIDTH - 110, 6, 0, 1.0, 0.0, scale_x = 1, scale_y = 1, color = 0xff_ffffff)
    @images["gold_coin"].draw(WIDTH - 100, 3.5, 0, 1.25, 1.25)
    @font.draw_rel("#{MedivalWar::IRON}", WIDTH - 110, 34, 0, 1.0, 0.0, scale_x = 1, scale_y = 1, color = 0xff_ffffff)
    @images["iron_coin"].draw(WIDTH - 100, 31.5, 0, 1.25, 1.25)
    seconds_left = @time_left_until_switch % 60
    @font.draw_rel("#{@time_left_until_switch / 60}:#{seconds_left < 10 ? "0#{seconds_left}" : seconds_left}", WIDTH - 20, 30, 0, 1.0, 0.5)
    if @thing_in_hand != nil
      if @thing_in_hand == "attacker" || @thing_in_hand == "defender"
        @images["person"].draw mouse_x - 20, mouse_y - 20, 0
      else
        @images[@thing_in_hand].draw mouse_x - 20, mouse_y - 20, 0
      end
    end
  end

  def update

  end

  def go_home
    @statice = "home"
  end

  def mouse_down(mouse_x, mouse_y, scroll_x, scroll_y, board)
    if @mode == :build
      return_val = ""
      if @mouse_is_down == false
        if @thing_in_hand == nil
          if mouse_y <= 60
            if @statice == "home"
              if mouse_x > 10 && mouse_x < 50 && @data["wall nums"] > 0 # on wall
                @data["wall nums"] -= 1
                @thing_in_hand = "wall"
              elsif mouse_x > 70 && mouse_x < 110 && @data["grass nums"] > 0 # on grass
                @data["grass nums"] -= 1
                @thing_in_hand = "grass"
              elsif mouse_x > 130 && mouse_x < 170 && @data["forge nums"] > 0 # on forge
                @data["forge nums"] -= 1
                @thing_in_hand = "forge"
              elsif mouse_x > 190 && mouse_x < 230 && @data["forge nums"] > 0 # on gold mine
                @data["gold_mine nums"] -= 1
                @thing_in_hand = "gold_mine"
              elsif mouse_x > 250 && mouse_x < 290 && @data["forge nums"] > 0 # on iron mine
                @data["iron_mine nums"] -= 1
                @thing_in_hand = "iron_mine"
              elsif mouse_x > 310 && mouse_x < 350 && @data["attacker nums"] > 0 # on attacker
                @data["attacker nums"] -= 1
                @thing_in_hand = "attacker"
              elsif mouse_x > 370 && mouse_x < 410 && @data["defender nums"] > 0 # on defender
                @data["defender nums"] -= 1
                @thing_in_hand = "defender"
              end
            elsif (@statice =~ /^\d+ \d+ .+$/) == 0
              new_statice = @statice.split(" ")
              x = new_statice[0]
              y = new_statice[1]
              type = new_statice[2]
              if type == "person"
                if mouse_x > 10 && mouse_x < 50 # on defender
                  return_val = "set defender #{x} #{y}"
                elsif mouse_x > 70 && mouse_x < 110 # on attacker
                  return_val = "set attacker #{x} #{y}"
                end
              elsif type == "forge"
                if mouse_x > 10 && mouse_x < 50 # on wall
                  return_val = "forge-set wall #{x} #{y}"
                elsif mouse_x > 70 && mouse_x < 110 # on grass
                  return_val = "forge-set grass #{x} #{y}"
                elsif mouse_x > 130 && mouse_x < 170 # on forge
                  return_val = "forge-set forge #{x} #{y}"
                elsif mouse_x > 190 && mouse_x < 230 # on gold mine
                  return_val = "forge-set gold_mine #{x} #{y}"
                elsif mouse_x > 250 && mouse_x < 290 # on iron mine
                  return_val = "forge-set iron_mine #{x} #{y}"
                elsif mouse_x > 310 && mouse_x < 350 # on attacker
                  return_val = "forge-set attacker #{x} #{y}"
                elsif mouse_x > 370 && mouse_x < 410 # on defender
                  return_val = "forge-set defender #{x} #{y}" 
                end
              end
            end
          else
            block_clicked_x = ((mouse_x - (mouse_x % 40)) / 40) + ((scroll_x - (scroll_x % 40)) / 40)
            block_clicked_y = ((mouse_y - (mouse_y % 40)) / 40) + ((scroll_y - (scroll_y % 40)) / 40)
            @statice = "#{block_clicked_x.to_i} #{block_clicked_y.to_i} #{board.type_of_block(block_clicked_x, block_clicked_y)}"
          end
        else
          new_x = ((mouse_x - (mouse_x % 40)) / 40) + ((scroll_x - (scroll_x % 40)) / 40)
          new_y = ((mouse_y - (mouse_y % 40)) / 40) + ((scroll_y - (scroll_y % 40)) / 40)
          if @thing_in_hand == "wall"
            new_block = Wall.new  new_x, new_y
          elsif @thing_in_hand == "grass"
            new_block = Grass.new new_x, new_y
          elsif @thing_in_hand == "forge"
            new_block = Forge.new new_x, new_y
          elsif @thing_in_hand == "gold_mine"
            new_block = GoldMine.new new_x, new_y
          elsif @thing_in_hand == "iron_mine"
            new_block = IronMine.new new_x, new_y
          elsif @thing_in_hand == "attacker"
            new_block = Attacker.new new_x, new_y, 10, board.grid
          elsif @thing_in_hand == "defender"
            new_block = Defender.new new_x, new_y, 10, board.grid
          end
          block_placed = board.set_block new_x, new_y, @thing_in_hand
          if !block_placed
            @data["#{@thing_in_hand} nums"] += 1
          end
          @thing_in_hand = nil
        end
      end
      @mouse_is_down = true
      return return_val
    end
  end

  def right_click(mouse_x, mouse_y, scroll_x, scroll_y, board)
    if @right_click_down == false
      if mouse_y <= 60
        if @statice == "home"
          if mouse_x > 10 && mouse_x < 50 && @data["wall nums"] > 0 # on wall
            if MedivalWar::GOLD >= 10
              @data["wall nums"] += 1
              MedivalWar::GOLD -= 10
            end
          elsif mouse_x > 70 && mouse_x < 110 && @data["grass nums"] > 0 # on grass
            @data["grass nums"] += 1
          elsif mouse_x > 130 && mouse_x < 170 && @data["forge nums"] > 0 # on forge
            if MedivalWar::IRON >= 50
              @data["forge nums"] += 1
              MedivalWar::IRON -= 50
            end
          end
        end
      end
    end
    @right_click_down = true
    nil
  end

  def right_click_up
    @right_click_down = false
  end

  def mouse_up
    @mouse_is_down = false
  end

  def add_one_item(type)
    if type != "gold" && type != "iron"
      @data["#{type} nums"] += 1
    elsif type == "gold"
      MedivalWar::GOLD += 1
    elsif type == "iron"
      MedivalWar::IRON += 1
    end
  end

  def set_time_left_until_switch(time)
    @time_left_until_switch = time
  end

  def switch
    if @mode == :build
      @mode = :fight
    else
      @mode = :build
    end
  end

end

class Block

  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def draw
    @image.draw @x * BLOCKSIZE, @y * BLOCKSIZE, 0
  end

  def update(seconds)
    nil
  end

  def type
    nil
  end

  def set_return_type(type)
    
  end

end

class Grass < Block

  def initialize(x, y)
    super x, y
    @image = Gosu::Image.new "images/grass.png"
  end

  def type
    "grass"
  end

end

class Wall < Block
  
  def initialize(x, y)
    super x, y
    @image = Gosu::Image.new("images/wall.png")
  end

  def type
    "wall"
  end

end

class Forge < Block

  def initialize(x, y)
    super x, y
    @image = Gosu::Image.new "images/forge.png"
    @produce_type = "wall"
    @produce_time = 5
    @on_sec = false
  end

  def update(seconds)
    if seconds % @produce_time == 0 && @on_sec == false
      @on_sec = true
      return @produce_type
    else
      if !(seconds % @produce_time == 0)
        @on_sec = false
      end
      return nil
    end
  end

  def set_return_type(type)
    @produce_type = type
  end

  def type
    "forge"
  end

end

class GoldMine < Block

  def initialize(x, y)
    super x, y
    @image = Gosu::Image.new "images/gold mine.png"
    @produce_type = "gold"
    @produce_time = 5
    @on_sec = false
  end

  def update(seconds)
    if seconds % @produce_time == 0 && @on_sec == false
      @on_sec = true
      return @produce_type
    else
      if !(seconds % @produce_time == 0)
        @on_sec = false
      end
      return nil
    end
  end

  def type
    "gold_mine"
  end

end

class IronMine < Block

  def initialize(x, y)
    super x, y
    @image = Gosu::Image.new "images/iron mine.png"
    @produce_type = "iron"
    @produce_time = 5
    @on_sec = false
  end

  def update(seconds)
    if seconds % @produce_time == 0 && @on_sec == false
      @on_sec = true
      return @produce_type
    else
      if !(seconds % @produce_time == 0)
        @on_sec = false
      end
      return nil
    end
  end

  def type
    "iron_mine"
  end

end

class King < Block

  def initialize(x, y)
    super x, y
    @image = Gosu::Image.new("images/king.png")
  end

  def type
    "king"
  end

end

class Person

  attr_reader :x, :y
  attr_accessor :life
  
  def initialize(x, y, life)
    @x = x
    @y = y
    @image = Gosu::Image.new("images/person.png")
    @life = life
    @max_life = life
    @mode = :build
  end

  def draw
    @image.draw @x * BLOCKSIZE, @y * BLOCKSIZE, 0
    if @mode == :fight
      Gosu.draw_rect(@x * BLOCKSIZE, @y * BLOCKSIZE - 3, @max_life, 3, 0xff_000000)
      draw_line(@x * BLOCKSIZE, @y * BLOCKSIZE - 2, @x * BLOCKSIZE + @max_life, @y * BLOCKSIZE - 2, 0xff_ff0000)
      draw_line(@x * BLOCKSIZE, @y * BLOCKSIZE - 2, @x * BLOCKSIZE + @life    , @y * BLOCKSIZE - 2, 0xff_00ff00)
    end
  end

  def update(arg, arg2)
    nil
  end

  def set_mode(mode)
    @mode = mode
  end

  def type
    "person"
  end

  def set_return_type(type)
    
  end

end

class Defender < Person

  def initialize(x, y, life, grid)
    super x, y, life
    @range = 1 # block
    @attack_power = 2
  end

  def update(seconds, enemies)
    if @life <= 0
      return :die
    end
    enemies.each do |enemy|
      if Math.sqrt((@x - enemy.x).abs ** 2 + (@y - enemy.y).abs ** 2) <= @range
        enemy.life -= @attack_power
        return true
      end
    end
    false
  end

end

class Attacker < Defender

  def initialize(x, y, life, grid)
    super x, y, life, grid
    @attacking = nil
    @grid = grid
    @speed = 4
  end

  def update(seconds, enemies)
    if @attacking == nil
      @attacking = enemies.to_a.shuffle[0]
    end
    puts @attacking_index
    path = find_path @x, @y, @grid, @attacking if enemies != nil
    hit_enemy = super seconds, enemies
    if hit_enemy == :die
      return :die
    end
    if !hit_enemy
      if path != nil
        prev_node = path[path.length - 2]
        node = path.last
        old_x = @x
        old_y = @y
        if node.x > prev_node.x && node.y == prev_node.y # left
          @x -= @speed.to_f / 40.0
          puts "attacker left"
        elsif node.x < prev_node.x && node.y == prev_node.y # right
          @x += @speed.to_f / 40.0
          puts "attacker right"
        elsif node.x == prev_node.x && node.y > prev_node.y # up
          @y -= @speed.to_f / 40.0
          puts "attacker up"
        elsif node.x == prev_node.x && node.y < prev_node.y # down
          @y += @speed.to_f / 40.0
          puts "attacker down"
        end
      end
    end
    :not_dead
  end

end

class Enemy

  attr_reader :x, :y
  attr_accessor :life

  def initialize(x, y, life, grid)
    @x            = x
    @y            = y
    @life         = life
    @max_life     = life
    @path         = find_path @x, @y, grid
    @speed        = 2
    @image        = Gosu::Image.new "images/goblin.png"
    @range        = 2
    @attack_power = 1
  end

  def draw
    @image.draw @x * BLOCKSIZE, @y * BLOCKSIZE, 0
    Gosu.draw_rect(@x * BLOCKSIZE, (@y * BLOCKSIZE) - 3, @max_life, 3, 0xff_000000)
    draw_line(@x * BLOCKSIZE, @y * BLOCKSIZE - 2, @x * BLOCKSIZE + @max_life, @y * BLOCKSIZE - 2, 0xff_ff0000)
    draw_line(@x * BLOCKSIZE, @y * BLOCKSIZE - 2, @x * BLOCKSIZE + @life    , @y * BLOCKSIZE - 2, 0xff_00ff00)
  end

  private

  def defense_update(seconds, people)
    if @life <= 0
      return :die
    end
    people.each do |enemy|
      if Math.sqrt((@x - enemy.x).abs ** 2 + (@y - enemy.y).abs ** 2) <= @range
        enemy.life -= @attack_power
        return true
      end
    end
    false
  end

  public

  def update(seconds, people)
    prev_node = @path[@path.length - 2]
    node = @path.last
    old_x = @x
    old_y = @y
    hit_person = defense_update(seconds, people)
    if hit_person == :die
      return :die
    end
    if !hit_person
      if node.x > prev_node.x && node.y == prev_node.y # left
        @x -= @speed.to_f / 40.0
        puts "left"
      elsif node.x < prev_node.x && node.y == prev_node.y # right
        @x += @speed.to_f / 40.0
        puts "right"
      elsif node.x == prev_node.x && node.y > prev_node.y # up
        @y -= @speed.to_f / 40.0
        puts "up"
      elsif node.x == prev_node.x && node.y < prev_node.y # down
        @y += @speed.to_f / 40.0
        puts "down"
      end
      if old_x.to_i != @x.to_i || old_y.to_i != @y.to_i
        @path.pop
      end
    end
    :not_dead
  end

end

public

class Screen < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Medival War"
    @time_left_until_switch = 5
    @board = Board.new
    @menu = Menu.new @time_left_until_switch
    @font = Gosu::Font.new 20
    @start_time = Time.new
    @seconds = 0
    @prev_sec = Time.new - 1
  end

  def draw
    @board.draw
    @menu.draw(mouse_x, mouse_y)
  end

  def update
    if Time.new >= @prev_sec + 1
      @seconds += 1
      @prev_sec += 1
      @time_left_until_switch -= 1
      @menu.set_time_left_until_switch @time_left_until_switch
    end
    if @time_left_until_switch <= 0
      @menu.switch
      @board.switch
      @board.spawn [Enemy.new(0, 0, 10, @board.grid)]
      @time_left_until_switch = 120
    end
    if @seconds >= 60
      @seconds = 0
    end
    @board.update mouse_x, mouse_y, @seconds, @menu
    if Gosu::button_down? Gosu::KbEscape
      @menu.go_home
    end
    if Gosu::button_down?(Gosu::MsMiddle)
      @board.ms_middle_down mouse_x, mouse_y
    end
    if Gosu::button_down?(Gosu::MsRight)
      @menu.right_click mouse_x, mouse_y, @board.scroll_x, @board.scroll_y, @board
    end
    if Gosu::button_down? Gosu::MsLeft
      if Gosu::button_down?(Gosu::KbS)
        @board.ms_middle_down mouse_x, mouse_y
      elsif Gosu::button_down?(Gosu::KbB)
        @menu.right_click mouse_x, mouse_y, @board.scroll_x, @board.scroll_y, @board
      else
        return_val = @menu.mouse_down mouse_x, mouse_y, @board.scroll_x, @board.scroll_y, @board
        puts return_val.inspect
        if return_val.class == String
          return_arr = return_val.split " "
          x = return_arr[2].to_i
          y = return_arr[3].to_i
          if return_arr[0] == "set"
            @board.set_block x, y, return_arr[1]
          elsif return_arr[0] == "forge-set"
            @board.set_forge_type x, y, return_arr[1]
          end
        end
      end
    end
  end

  def button_up(id)
    if id == Gosu::MsMiddle || (id == Gosu::MsLeft && Gosu::button_down?(Gosu::KbS))
      @board.ms_middle_up
    end
    if id == Gosu::MsLeft
      if Gosu::button_down?(Gosu::KbS)
        @board.ms_middle_up
      elsif Gosu::button_down?(Gosu::KbB)
        @menu.right_click_up
      else
        @menu.mouse_up
      end
    end
    if id == Gosu::MsRight || (id == Gosu::MsLeft && Gosu::button_down?(Gosu::KbB))
      @menu.right_click_up
    end
  end

  def needs_cursor?
    true
  end

end

class LoadScreen < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Medival War"
    @font = Gosu::Font.new 50
    @num = 0
  end

  def draw
    @font.draw_rel("Loading...", WIDTH / 2, HEIGHT / 2 - 25, 0, 0.5, 0.5)
    @font.draw_rel("Please Wait", WIDTH / 2, HEIGHT / 2 + 25, 0, 0.5, 0.5)
  end

  def update
    if @num == 1
      Screen.new.show
      exit
    end
    @num += 1
  end

  def needs_cursor?
    true
  end

end

end

MedivalWar::LoadScreen.new.show if __FILE__ == $0