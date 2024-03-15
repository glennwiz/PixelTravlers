package PixelTravler

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:sdl2"
import "core:os"
import "core:unicode/utf8"
import "base:builtin"

import "core:mem"

/*
    Maxwell's Daemon, in Gnipahellir's depths, plays a cunning game,
    With points of memory as his pawns, in entropy's endless frame.
    Garm, the guardian fierce at Gnipahellir's gate, snarls at each move,
    Yet the Daemon defies, weaving past and present, in Gnipahellir's groove.

    Those who dare to fail miserably can achieve greatly
*/

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480 //window size 1900, 1100
CELL_SIZE :: 15		    	//size of the cell	
BIAS_MULTI :: 2         	//how much the bias will affect the speed of the cell
REPRODUCE_AGE :: 500    	//what age will they start to reproduce
DEATH_DELAY :: 60			//the cleanup rate of removing dead cells 60 is ever sec
CELL_COUNT :: 1000			//how many max cells alive at a time
DEATH_AGE :: 3000      		//what age will they star to die
NEEDY_OFFSPRING :: 100  	//byte 255 totaly needy


STARTING_CELLS :: 20		//how many cells will start
SPAWN_RATE :: 100       	//how often the cells will spawn
REPRODUCE_DISTANCE :: 10	//how close the cells need to be to reproduce
PARENT_MEET :: true     	//if true, the parents will meet and the offspring will get a size boost


abs :: builtin.abs
min :: builtin.min
max :: builtin.max
clamp :: builtin.clamp // https://pkg.odin-lang.org/base/builtin/#clamp


Color :: struct {
	a: Vec4, // alpha
	b: Vec4, // beta
	g: Vec4, // gamma
	d: Vec4, // delta
}

ColorSet := new(Color) 


Game :: struct {
	renderer: ^sdl2.Renderer,
	keyboard: []u8,
	time:     f64,
	dt:       f64,
}

//u8 :: byte
Vec4 :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Cell :: struct {	
	is_alive:                bool,
	can_reproduce:           bool,
	is_growing:              bool,	
	size:                    u8,	
	x:                       f16,
	y:                       f16,		
	past_x:                  f16,
	past_y:                  f16,
	age:                     u16,
	time_since_reproduction: u16,
	bias:                    f32,
	color:                   Vec4,	
	parent1:                 ^Cell, // Pointer to first parent cell
	parent2:                 ^Cell, // Pointer to second parent cell
	dna:                     [8]byte, //dna :8 used atm: [4 byte RGB, 1 byte movement bias, 1byte speed bias, 1byte mutation rate, 1byte repoduction rate, 1byte life span]
	trail:                   [][2]f16, //trail :[x,y] used to store the trail of the cell
}

cell_array := make([dynamic]^Cell)

frac_counter : u8 = 0

main :: proc() {
	dt := 0.0
	
	ColorSet.a = Vec4{0, 0, 0, 255}
	ColorSet.b = Vec4{0, 255, 0, 255}
	ColorSet.g = Vec4{0, 0, 255, 255}
	ColorSet.d = Vec4{255, 255, 255, 255}

	perf_frequency := f64(sdl2.GetPerformanceFrequency())
	start: f64
	end: f64
	fmt.println("s-----------------------------------------")

	assert(sdl2.Init(sdl2.INIT_VIDEO) == 0, sdl2.GetErrorString())
	defer sdl2.Quit()

	window := sdl2.CreateWindow(
		"Norse Grids",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		sdl2.WINDOW_SHOWN,
	)
	assert(window != nil, sdl2.GetErrorString())
	defer sdl2.DestroyWindow(window)

	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
	assert(renderer != nil, sdl2.GetErrorString())
	defer sdl2.DestroyRenderer(renderer)

	event: sdl2.Event

	for i := 0; i < STARTING_CELLS; i += 1 {
		cell := new(Cell)
		cell.age = 0
		cell.size = CELL_SIZE
		cell.color = Vec4{255, 255, 0, 255}
		cell.is_alive = true
		cell.can_reproduce = false
		cell.is_growing = false
		cell.time_since_reproduction = 0
		cell.x = WINDOW_WIDTH / 2 - (CELL_SIZE / 2)
		cell.y = WINDOW_HEIGHT / 2 - (CELL_SIZE / 2)
		cell.dna = [8]byte {
			get_random_byte(),
			get_random_byte(),
			get_random_byte(),
			255,
			100,
			0,
			0,
			0,
		}

		// Generate random direction
		direction := get_random_byte()
		cell.dna[4] = direction
		cell.bias = get_random_float()

		append(&cell_array, cell)
	}

	game_counter := 0
	movement_counter := 0
	r := 0

	// frame counter
	fps: u8 = 60
	frameDelay: i16 = i16(1000) / i16(fps)

	framStart: u32
	frameTime: i32

	tickrate := 240.0
	ticktime := 1000.0 / tickrate

	// Create game instance
	game := Game {
		renderer = renderer,
		time     = get_time(),
		dt       = ticktime,
	}

	get_time :: proc() -> f64 {
		return f64(sdl2.GetPerformanceCounter()) * 1000 / f64(sdl2.GetPerformanceFrequency())
	}
	
	game_loop: for {	

		// Start of game loop, we log the start so we can calculate the time it took to render the frame
		framStart = sdl2.GetTicks()
		time := get_time()
		dt += time - game.time
		game.time = time
		game.dt = dt
		
		// we only want to print the length about 1 time per second so me mod 60
		if game_counter % 60 == 0 {
			fmt.println("Length:  ", len(cell_array))
		}

		//every N game ticks, we will remove the dead cells from the array
		if game_counter % DEATH_DELAY == 0 {

			//create a temp array to hold the state of the current array
			dyn_copy := make([dynamic]^Cell, len(cell_array), cap(cell_array))
			defer delete(dyn_copy)

			//copy the array to a temp array
			copy(dyn_copy[:], cell_array[:])

			//clear the current array
			cell_array = make([dynamic]^Cell)

			//moving the alive cells to the new temp array
			for i := 0; i < len(dyn_copy); i += 1 {
				if dyn_copy[i].is_alive {
					append(&cell_array, dyn_copy[i])
				}
			}
		}

		game_counter += 1
		movement_counter += 1

		// Drawing gradient from black to grey
		draw_gradient(game.renderer)

		//2` = x^2 + c
		//fractal 
		//sdl2.SetRenderDrawColor(game.renderer, 100, 100, 100, 10)	
		
		//this is the fractal counter, it will go from 0 to 255 and back to 0
		//this will be used to draw the dragon curve with different colors
		draw_dragon_D(game, ColorSet)
		
			
	

		// some color changing stuff
		t := 0.5 * 0.01 * f32(game.dt)
		//fmt.println("t: ", t)
		//fmt.println("game.dt: ", game.dt)

		//clamp returns a value v clamped between minimum and maximum. This is calculated as the following: minimum if v < minimum else maximum if v > maximum else v.
		if  up_tick {
			ColorSet.a.r = clamp(0, 200, u8(t))
			ColorSet.a.g = clamp(0, 180, u8(t))
			ColorSet.a.b = clamp(0, 88, u8(t))
		}
	

		for c, _ in cell_array {
			mutation_chance: u8 = get_random_Max100()
			if c.age > u16(500) && mutation_chance < u8(1) {
				c.dna[4] = get_random_byte()  	//direction
				c.bias   = get_random_float() 	//speed	
				c.dna[5] = get_random_byte()  	//mutation rate
				c.dna[6] = get_random_byte()  	//reproduction rate
				//fmt.println("Mutation!")
			}

			c.age += 1
			c.time_since_reproduction += 1

			//wrap the cell position left to right and top to bottom
			wrap_cell_position(c)

		x := get_random_byte()
		if c.age > REPRODUCE_AGE && c.time_since_reproduction > 500 && x < 1{
				c.can_reproduce = true
			}

			// if two cells are close to each other, they can reproduce
			for c2, _ in cell_array {
				if c != c2 {
					//Euclidean distance √(c.x − c2.x)^2 + (c.y − c2.y)^2
					distance := math.sqrt(
						(f64((c.x - c2.x) * (c.x - c2.x) + (c.y - c2.y) * (c.y - c2.y))),
					)

					spawn: u8 = get_random_Max100()
					if spawn < u8(SPAWN_RATE) &&
					   len(cell_array) < CELL_COUNT &&
					   distance < REPRODUCE_DISTANCE &&
					   c.can_reproduce &&
					   c2.can_reproduce &&
					   c.time_since_reproduction > 1000 &&
					   c.parent1 != c2 && c.parent2 != c2     //prevent inbreeding, maybe do somthing other when meeting a parent, like opose movement, or maybe +1 to the szie of the cell
					{
						c2.time_since_reproduction = 0
						c2.can_reproduce = false
						c.can_reproduce = false
						c.time_since_reproduction = 0

						fmt.println("--------------------------------->Reproduction!")
						fmt.println("Cell 1 dna: ", c.dna)
						fmt.println("Cell 2 dna: ", c2.dna)
						fmt.println("Cell 1 bias: ", c.bias)
						fmt.println("Cell 2 bias: ", c2.bias)

						//reproduce a new cell
						child := new(Cell)
						child.age = 0
						child.is_alive = true
						child.is_growing = true
						child.x = c.x
						child.y = c.y
						child.time_since_reproduction = 0
						child.size = 1
						child.parent1 = c
						child.parent2 = c2
						//todo: maybe inherit the color from the parents more
						child.dna = [8]byte {
							get_random_byte(),
							c.dna[1] - 18,
							c.dna[2] - 18,
							get_random_byte(),
							get_random_byte(),
							0,
							0,
							0,
						}
						child.bias = get_random_float()
						append(&cell_array, child)
						c.time_since_reproduction = 0
					}

				if spawn < u8(10) && PARENT_MEET == true && !c.can_reproduce == true && distance < 100 && (c.parent1 == c2 || c.parent2 == c2)  {
						
						v := get_random_byte()
						if v < NEEDY_OFFSPRING
						{
							c.size += 1
							//c2.size += 1
							c.bias *= -1
							c2.bias *= -1
	
							//fmt.println(PARENT_MEET)

							if game_counter < 100 {
								fmt.println("Parent meeting!----------------------------------->|§§§§§||||§§§§§§")
							}							
						}
					}
				}
			}

			//if is growing debug log 
			if c.is_growing && len(cell_array) < 15 && game_counter % 60 == 0 {
				fmt.println("Cell is growing")
				fmt.println("Cell size: ", c.size)
				fmt.println("Cell age: ", c.age)
				fmt.println("Cell time_since_reproduction: ", c.time_since_reproduction)
				fmt.println("Cell dna: ", c.dna)
				fmt.println("Cell bias: ", c.bias)
			}

			map_byte_to_direction := map_byte_to_direction(c.dna[4])
			bias_strength := c.bias * BIAS_MULTI

			switch map_byte_to_direction {
			case "N":
				c.x += 1 * f16(bias_strength)
			case "NE":
				c.x += 1 * f16(bias_strength)
				c.y -= 1 * f16(bias_strength)
			case "E":
				c.y -= 1 * f16(bias_strength)
			case "SE":
				c.x -= 1 * f16(bias_strength)
				c.y -= 1 * f16(bias_strength)
			case "S":
				c.x -= 1 * f16(bias_strength)
			case "SW":
				c.x -= 1 * f16(bias_strength)
				c.y += 1 * f16(bias_strength)
			case "W":
				c.y += 1 * f16(bias_strength)
			case "NW":
				c.x += 1 * f16(bias_strength)
				c.y += 1 * f16(bias_strength)
			}

			rect := sdl2.FRect {
				x = f32(c.x),
				y = f32(c.y),
				w = f32(c.size),
				h = f32(c.size),
			}

			rect2 := sdl2.Rect {
				x = i32(c.x),
				y = i32(c.y),
				w = i32(c.size),
				h = i32(c.size),
			}			

			//TODO: add a trail to the cell

			if c.is_alive && c.can_reproduce{
				
				sdl2.SetRenderDrawColor(game.renderer, c.dna[0], c.dna[1], c.dna[2], c.dna[3])
				sdl2.RenderFillRect(renderer, &rect2)
			}
			
			if (c.is_alive && !c.can_reproduce)
			{				
				sdl2.SetRenderDrawColor(game.renderer, c.dna[0], c.dna[1], c.dna[2], c.dna[3])
				sdl2.RenderDrawRectF(game.renderer, &rect)
			}

			if game_counter % 10 == 0 && c.size < CELL_SIZE {
				c.size += 1
			}

			if c.size == CELL_SIZE {
				c.is_growing = false
			}

			v := get_random_float()

			if c.age > DEATH_AGE && v < 0.009 {
				fmt.println("Cell died of old age!----------------------------------->|§§§!!!!!§§||||§§!!!!§§§")
				fmt.println("Cell age: ", c.age)
				fmt.println("Cell time_since_reproduction: ", c.time_since_reproduction)
				fmt.println("Cell dna: ", c.dna)
				fmt.println("Cell bias: ", c.bias)
				fmt.println("Cell size: ", c.size)
				c.is_alive = false
			}
		}

		sdl2.RenderPresent(game.renderer)

		if sdl2.PollEvent(&event) {
			if event.type == sdl2.EventType.QUIT {
				break game_loop
			}

			// Handle Keyboard Input
			if event.type == sdl2.EventType.KEYDOWN {
				#partial switch event.key.keysym.scancode {
				case .ESCAPE:
					break game_loop
				}

				if sdl2.PollEvent(&event) {
					if event.type == sdl2.EventType.QUIT {
						break game_loop
					}

					// Handle Keyboard Input
					if event.type == sdl2.EventType.KEYDOWN {
						#partial switch event.key.keysym.scancode {
						case .ESCAPE:
							break game_loop}
					}
				}
			}
		}

		//End of game loop
	
		//in milliseconds this is the time it took to render the frame
		frameTime = i32(sdl2.GetTicks() - framStart)
		if (i32(frameDelay) > frameTime) {
			sdl2.Delay(u32(i32(frameDelay) - frameTime))
		}
	}
}

get_random_byte_10max :: proc() -> u8 {
	return u8(rand.int_max(10))
}

get_random_byte :: proc() -> u8 {
	return u8(rand.int_max(256))
}

get_random_float :: proc() -> f32 {
	return rand.float32()
}

get_random_Max100 :: proc() -> u8 {
	return u8(rand.int_max(100))
}

wrap_cell_position :: proc(cell: ^Cell) {
	if cell.y > WINDOW_HEIGHT {
		cell.y = 0 - CELL_SIZE
	}
	if cell.y < 0 - CELL_SIZE {
		cell.y = WINDOW_HEIGHT
	}

	if cell.x > WINDOW_WIDTH {
		cell.x = 0 - CELL_SIZE
	}

	if cell.x < 0 - CELL_SIZE {
		cell.x = WINDOW_WIDTH
	}
}

draw_gradient :: proc(renderer: ^sdl2.Renderer) {
	for x: i32 = 0; x < WINDOW_WIDTH; x += 1 {
		fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
		sdl2.SetRenderDrawColor(renderer, fade, fade, fade, 255)
		sdl2.RenderDrawLine(renderer, x, 0, x, WINDOW_HEIGHT)
	}
}

map_byte_to_direction :: proc(b: u8) -> string {

	switch b {
	case 240 ..< 255, 0 ..< 16:
		return "N"
	case 16 ..< 48:
		return "NE"
	case 48 ..< 80:
		return "E"
	case 80 ..< 112:
		return "SE"
	case 112 ..< 144:
		return "S"
	case 144 ..< 176:
		return "SW"
	case 176 ..< 208:
		return "W"
	case 208 ..< 240:
		return "NW"
	}

	return "N"
}

exit :: proc() {
	fmt.println("Exiting...")
	os.exit(0)
}

up_tick: bool = true
draw_dragon_D:: proc(game: Game, co: ^Color )
{
	
	if frac_counter == 255 {
		up_tick = true 
	}

	if frac_counter == 0{
		up_tick = false

	}

	if up_tick{
		frac_counter = frac_counter -1 
		
	}else{	
		frac_counter = frac_counter + 1			
	}	

	//curve 1
	draw_dragon_curve(game, i32(frac_counter), 500, 700, 500, 12, co)
	//curve 2
	draw_dragon_curve(game, i32(frac_counter) + 100, 900, 1700, 1500, 8, co)
}

draw_dragon_curve :: proc(game: Game, x0, y0, x1, y1: i32, level: int, co: ^Color, speed: f32 = 1.0)
{

	renderer := game.renderer

	if level <= 0 {

		sdl2.SetRenderDrawColor(renderer, co.a.r, co.a.g, co.a.b, 1)
		
        sdl2.RenderDrawLine(renderer, x0, y0, x1, y1)
        return
    }

    xm := (x0 + x1) / 2 + (y1 - y0) / 3
    ym := (y0 + y1) / 2 + (x0 - x1) / 2

    draw_dragon_curve(game, x0, y0, xm, ym, level-1, co)
    draw_dragon_curve(game, x1, y1, xm, ym, level-1, co)
}
