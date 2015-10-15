#! /usr/local/bin/ruby

require "gosu"
require "yaml"
require "./gosu_library.rb"
require "set"

module MedivalWar
	
private

WIDTH = 800
HEIGHT = 600

IRON = 0
GOLD = 100

class Node

	attr_reader :x, :y, :parent

	def initialize(x, y, parent)
		@x = x
		@y = y
		@parent = parent
	end

	def ==(other)
		return false if other.class != Node
		@x == other.x && @y == other.y
	end

	def eql?(other)
		self == other
	end

	def hash
		[@x, @y].hash
	end

	def to_s
		return "Node <@x = #{@x}, @y = #{@y}, @parent = #{@parent}>"
	end
end

def find_path(grid)
	start_loc = nil
	end_loc = nil
	grid.each_with_index do |row, y|
		row.each_with_index do |item, x|
			if item.type == "start"
				start_loc = Node.new(x, y, nil)
			end
		end
	end
	grid.each_with_index do |row, y|
		row.each_with_index do |item, x|
			if item.type == "end"
				end_loc = Node.new(x, y, nil)
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
				if (extention.y >= 0 && extention.y < HEIGHT / BLOCKSIZE &&
				extention.x >= 0 && extention.x < WIDTH / BLOCKSIZE &&
				grid[extention.y][extention.x].type != "wall" &&
				!explored_locs.include?(extention))
					new_tip_nodes.push extention
					explored_locs.add extention
				end
			end
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
	nil
end

class Board

	attr_reader :scroll_x, :scroll_y

	def initialize
		#begin
		#	@grid = File.read("data/board.yaml")
		#	@grid = YAML::load @grid
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
			@grid[10][11] = Wall.new 11, 10
			@grid[10][12] = Wall.new 12, 10
			@grid[11][10] = Wall.new 10, 11
			@grid[11][12] = Wall.new 12, 11
			@grid[12][10] = Wall.new 10, 12
			@grid[12][11] = Wall.new 11, 12
			@grid[12][12] = Wall.new 12, 12
			#begin
			#	Dir.mkdir "data"
			#rescue
			#end
			#File.open("data/board.yaml", "w") { |f| f.write @grid.to_yaml }
		#end
		@ms_middle_down_click_x = nil
		@ms_middle_down_click_x = nil
		@scroll_x = 0
		@scroll_y = -60
		@mode = :build
	end

	def draw
		Gosu::translate(-@scroll_x, -@scroll_y) do
			@grid.each do |row|
				row.each do |item|
					item.draw
				end
			end
		end
	end

	def update(mouse_x, mouse_y, seconds, menu)
		if @ms_middle_down_click_x != nil && @ms_middle_down_click_y != nil
			@scroll_x -= mouse_x - @ms_middle_down_click_x
			@scroll_y -= mouse_y - @ms_middle_down_click_y
		end
		@grid.each do |row|
			row.each do |item|
				thing = item.update seconds
				if thing != nil
					menu.add_one_item thing
				end
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
			elsif type == "person"
				if @grid[y][x].class == Person
					return false
				end
				@grid[y][x] = Person.new x, y
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

	def type_of_block(x, y)
		@grid[y][x].type
	end

	def switch
		if @mode == :build
			@mode = :fight
		else
			@mode = :build
		end
	end
end

class Menu

	def initialize
		@statice = "home"
		@font = Gosu::Font.new 20
		@data = {"wall nums" => 10,
				 "grass nums" => 10,
				 "forge nums" => 5,
				 "gold_mine nums" => 5,
				 "iron_mine nums" => 5,
				 "person nums" => 5}
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
		@time_left_until_switch = 120
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
			@font.draw("#{@data['person nums']}", 310, 0, 0, 0.5, 0.5, 0xff_ffffff)
			@images["person"].draw(310, 25, 0)
			@font.draw("person", 310, 50, 0, 0.5, 0.5, 0xff_ffffff)
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
			end
		end
		@font.draw_rel("#{MedivalWar::GOLD}", WIDTH - 110, 6, 0, 1.0, 0.0, scale_x = 1, scale_y = 1, color = 0xff_ffffff)
		@images["gold_coin"].draw(WIDTH - 100, 3.5, 0, 1.25, 1.25)
		@font.draw_rel("#{MedivalWar::IRON}", WIDTH - 110, 34, 0, 1.0, 0.0, scale_x = 1, scale_y = 1, color = 0xff_ffffff)
		@images["iron_coin"].draw(WIDTH - 100, 31.5, 0, 1.25, 1.25)
		seconds_left = @time_left_until_switch % 60
		@font.draw_rel("#{@time_left_until_switch / 60}:#{seconds_left < 10 ? "0#{seconds_left}" : seconds_left}", WIDTH - 20, 30, 0, 1.0, 0.5)
		if @thing_in_hand != nil
			@images[@thing_in_hand].draw mouse_x - 20, mouse_y - 20, 0
		end
	end

	def update

	end

	def go_home
		@statice = "home"
	end

	def mouse_down(mouse_x, mouse_y, scroll_x, scroll_y, board)
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
						elsif mouse_x > 310 && mouse_x < 350 && @data["person nums"] > 0 # on person
							@data["person nums"] -= 1
							@thing_in_hand = "person"
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
				elsif @thing_in_hand == "person"
					new_block = Person.new new_x, new_y
				end
				block_placed = board.set_block new_x, new_y, @thing_in_hand
				if !block_placed
					@data["#{@thing_in_hand} nums"] += 1
				end
				@thing_in_hand = nil
			end
		end
		@mouse_is_down = true
		return_val
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
						if MedivalWar::GOLD >= 50
							@data["forge nums"] += 1
							MedivalWar::GOLD -= 50
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

	def initialize(x, y)
		@x = x
		@y = y
	end

	def draw
		@image.draw @x * 40, @y * 40, 0
	end

	def update(seconds)
		nil
	end

	def type
		nil
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

class Person < Block
	
	def initialize(x, y)
		super x, y
		@image = Gosu::Image.new("images/person.png")
	end

	def type
		"person"
	end

end

public

class Screen < Gosu::Window

	def initialize
		super WIDTH, HEIGHT
		self.caption = "Medival War"
		@board = Board.new
		@menu = Menu.new
		@font = Gosu::Font.new 20
		@start_time = Time.new
		@seconds = 0
		@prev_sec = Time.new - 1
		@time_left_until_switch = 2
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
			@time_left_until_switch = 120
		end
		if @seconds >= 60
			@seconds = 0
		end
		@board.update mouse_x, mouse_y, @seconds, @menu
		if Gosu::button_down? Gosu::KbEscape
			@menu.go_home
		end
		if Gosu::button_down? Gosu::MsMiddle
			@board.ms_middle_down mouse_x, mouse_y
		end
		if Gosu::button_down? Gosu::MsLeft
			return_val = @menu.mouse_down mouse_x, mouse_y, @board.scroll_x, @board.scroll_y, @board
			puts return_val.inspect
			if return_val[0..12] == "set attacker "
				arr = return_val.split(" ")
				x = arr[2].to_i
				y = arr[3].to_i
				@board.set_block x, y, "wall"
			end
		end
		if Gosu::button_down? Gosu::MsRight
			@menu.right_click mouse_x, mouse_y, @board.scroll_x, @board.scroll_y, @board
		end
	end

	def button_up(id)
		if id == Gosu::MsMiddle
			@board.ms_middle_up
		end
		if id == Gosu::MsLeft
			@menu.mouse_up
		end
		if id == Gosu::MsRight
			@menu.right_click_up
		end
	end

	def needs_cursor?
		true
	end

end

end

MedivalWar::Screen.new.show if __FILE__ == $0