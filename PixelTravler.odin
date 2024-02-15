package PixelTravler

import "core:fmt"
import "vendor:sdl2"
import "core:math/rand"
import "core:math/linalg"

/*
    Maxwell's Daemon, in Gnipahellir's depths, plays a cunning game,
    With points of memory as his pawns, in entropy's endless frame.
    Garm, the guardian fierce at Gnipahellir's gate, snarls at each move,
    Yet the Daemon defies, weaving past and present, in Gnipahellir's groove.

    Those who dare to fail miserably can achieve greatly
*/

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
CELL_SIZE :: 7

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
	x: i32,
    y: i32,
	past_x: i32,
	past_y: i32,
    is_alive: bool,
	color: Vec4,
	bias: f64,	
	parent1: ^Cell, // Pointer to first parent cell
	parent2: ^Cell, // Pointer to second parent cell
	dna: [8]byte,  //dna :8 used atm: [4 byte RGB, 1 byte movement bias, 1byte mutation bias, 1byte mutation rate, 1byte repoduction rate, 1byte life span]
}

cell_array := make([dynamic]^Cell)

get_time :: proc() -> f64 {
	return f64(sdl2.GetPerformanceCounter()) * 1000 / f64(sdl2.GetPerformanceFrequency())
}

main :: proc() {

	perf_frequency := f64(sdl2.GetPerformanceFrequency())
    start : f64
    end : f64
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

	// Must not do VSync because we run the tick loop on the same thread as rendering.
	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
	assert(renderer != nil, sdl2.GetErrorString())
	defer sdl2.DestroyRenderer(renderer)

	tickrate := 1000.0
	ticktime := 1000.0 / tickrate

	game := Game {
		renderer = renderer,
		time     = get_time(),
		dt       = ticktime,	
	}

	fmt.println("screen_width: ", WINDOW_WIDTH)
	fmt.println("screen_height: ", WINDOW_HEIGHT)
	fmt.println("cell_size: ", CELL_SIZE)
	fmt.println("tickrate: ", tickrate)
	fmt.println("ticktime: ", ticktime)
	fmt.println("e-----------------------------------------")

	event : sdl2.Event

	for i := 0; i < 10000; i += 1 {
		cell := new(Cell)
		cell.color = Vec4{255, 255, 0, 255}
		cell.is_alive = true
		cell.x = WINDOW_WIDTH / 2 - (CELL_SIZE / 2)
		cell.y = WINDOW_HEIGHT / 2 - (CELL_SIZE / 2)
		cell.dna = [8]byte{get_random_byte(), get_random_byte(), get_random_byte(), 255, 100, 0, 0, 0}

		// Generate random direction
		direction := get_random_byte()
		cell.dna[4] = direction
		cell.bias = get_random_float()

		append(&cell_array, cell)
	}


	//get the first cell in the array
	c := cell_array[0]

	if(len(cell_array) < 21) {
		fmt.println("Elements:", cell_array)
	}

	fmt.println("Length:  ", len(cell_array))
	fmt.println("Capacity:", cap(cell_array))

	game_counter := 0
	movement_counter := 0
	r := 0

	game_loop : for {
		start = get_time()
		game_counter += 1
		movement_counter += 1

		// Drawing gradient from black to grey
		draw_gradient(game.renderer)		
		
		if game_counter % 50 == 0 {
			for c, _ in cell_array {	
				
				if game_counter % 2009 == 0 {
					
					c.dna[0] = get_random_byte()
					c.dna[1] = get_random_byte()
					c.dna[2] = get_random_byte()
					
					c.dna[4] = get_random_byte()

					c.bias = get_random_float()					
				}	

				wrap_cell_position(c)
					
				map_byte_to_direction := map_byte_to_direction(c.dna[4])

				switch map_byte_to_direction {
				case "N":
					c.x += 1 * i32(c.bias * 20)
				case "NE":
					c.x += 1 * i32(c.bias * 20)
					c.y -= 1 * i32(c.bias * 20)
				case "E":
					c.y -= 1 * i32(c.bias * 20)
				case "SE":
					c.x -= 1 * i32(c.bias * 20)
					c.y -= 1 * i32(c.bias * 20)
				case "S":
					c.x -= 1 * i32(c.bias * 20)
				case "SW":
					c.x -= 1 * i32(c.bias * 20)
					c.y += 1 * i32(c.bias * 20)
				case "W":
					c.y += 1 * i32(c.bias * 20)
				case "NW":
					c.x += 1 * i32(c.bias * 20)
					c.y += 1 * i32(c.bias * 20)
				}

				rect := sdl2.Rect{
					x = c.x,
					y = c.y,    
					w = CELL_SIZE,
					h = CELL_SIZE,
				}
				sdl2.SetRenderDrawColor(game.renderer, c.dna[0], c.dna[1], c.dna[2], c.dna[3]) 
				sdl2.RenderFillRect(game.renderer, &rect)            
			}
	
			sdl2.RenderPresent(game.renderer)

			// Frame rate management
			end = get_time()
			for end - start < ticktime {
				fmt.println("end - start: ", end - start)
				end = get_time()
			}	

			if game_counter % 1000 == 0 {
				fmt.println("end - start: ", end - start)
				fmt.println("ticktime: ", ticktime)
				//fmt.println("perf_frequency: ", perf_frequency)
				fmt.println("game_counter: ", game_counter)
			}			
		}		
		
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
								break game_loop  }
					}
				}
			}
		}
	}
}



get_random_byte :: proc() -> u8 {
    return u8(rand.int_max(256))
}

get_random_float :: proc() -> f64 {
	return rand.float64()
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
	for x : i32 = 0; x < WINDOW_WIDTH; x += 1 {
		fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
		sdl2.SetRenderDrawColor(renderer, fade, fade, fade, 255)
		sdl2.RenderDrawLine(renderer, x, 0, x, WINDOW_HEIGHT)
	}
}

map_byte_to_direction :: proc(b: u8) -> string {

	switch b {
		case 240..<255, 0..<16: return "N"
		case 16..<48: return "NE"
		case 48..<80: return "E"
		case 80..<112: return "SE"
		case 112..<144: return "S"
		case 144..<176: return "SW"
		case 176..<208: return "W"
		case 208..<240: return "NW"  
	}

	return "N"
}	