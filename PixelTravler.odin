package PixelTravler

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:sdl2"
import "core:os"

import "core:mem"

/*
    Maxwell's Daemon, in Gnipahellir's depths, plays a cunning game,
    With points of memory as his pawns, in entropy's endless frame.
    Garm, the guardian fierce at Gnipahellir's gate, snarls at each move,
    Yet the Daemon defies, weaving past and present, in Gnipahellir's groove.

    Those who dare to fail miserably can achieve greatly
*/

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
CELL_SIZE :: 15

Game :: struct {
	renderer: ^sdl2.Renderer,
	keyboard: []u8,
	time:     i32,
	dt:       i16,
}

//u8 :: byte
Vec4 :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Cell :: struct {
	x:                       f32,
	y:                       f32,
	age:                     u16,
	can_reproduce:           bool,
	time_since_reproduction: u16,
	is_growing:              bool,
	past_x:                  f32,
	past_y:                  f32,
	size:                    u8,
	is_alive:                bool,
	color:                   Vec4,
	bias:                    f64,
	parent1:                 ^Cell, // Pointer to first parent cell
	parent2:                 ^Cell, // Pointer to second parent cell
	dna:                     [8]byte, //dna :8 used atm: [4 byte RGB, 1 byte movement bias, 1byte speed bias, 1byte mutation rate, 1byte repoduction rate, 1byte life span]
}

cell_array := make([dynamic]^Cell)

main :: proc() {


	fmt.println("s-----------------------------------------")
	
	fmt.println("sizeof(Vec4): ", size_of(Vec4))
	fmt.println("sizeof(u8): ", size_of(u8))
	fmt.println("sizeof(f16): ", size_of(f16))
	fmt.println("sizeof(f32): ", size_of(f32))
	fmt.println("sizeof(u16): ", size_of(u16))
	fmt.println("sizeof([8]byte): ", size_of([8]byte))
	fmt.println("sizeof([dynamic]^Cell): ", size_of([dynamic]^Cell))
	fmt.println("sizeof(Cell): ", size_of(Cell))
	fmt.println("sizeof(Game): ", size_of(Game))
	fmt.println("sizeof(sdl2.Renderer): ", size_of(sdl2.Renderer))
	fmt.println("sizeof(sdl2.Window): ", size_of(sdl2.Window))
	fmt.println("sizeof(sdl2.Event): ", size_of(sdl2.Event))
	fmt.println("sizeof(sdl2.Rect): ", size_of(sdl2.Rect))
	fmt.println("sizeof(sdl2.FRect): ", size_of(sdl2.FRect))
	fmt.println("sizeof(sdl2.Texture): ", size_of(sdl2.Texture))
	fmt.println("sizeof(sdl2.RendererInfo): ", size_of(sdl2.RendererInfo))
	fmt.println("sizeof(sdl2.PixelFormat): ", size_of(sdl2.PixelFormat))
	fmt.println("sizeof(sdl2.Color): ", size_of(sdl2.Color))
	fmt.println("sizeof(sdl2.Palette): ", size_of(sdl2.Palette))
	fmt.println("sizeof(sdl2.RendererInfo): ", size_of(sdl2.RendererInfo))
	fmt.println("sizeof(sdl2.RendererInfo): ", size_of(sdl2.RendererInfo))
	
	
	exit()
	

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

	// Must not do VSync because we run the tick loop on the same thread as rendering.
	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
	assert(renderer != nil, sdl2.GetErrorString())
	defer sdl2.DestroyRenderer(renderer)


	fmt.println("screen_width: ", WINDOW_WIDTH)
	fmt.println("screen_height: ", WINDOW_HEIGHT)
	fmt.println("cell_size: ", CELL_SIZE)
	fmt.println("e-----------------------------------------")

	event: sdl2.Event

	for i := 0; i < 4; i += 1 {
		cell := new(Cell)
		cell.age = 0
		cell.size = CELL_SIZE
		cell.color = Vec4{255, 255, 0, 255}
		cell.is_alive = true
		cell.can_reproduce = false
		cell.is_growing = false
		cell.time_since_reproduction = 90
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

	fmt.println("Length:  ", len(cell_array))
	fmt.println("Capacity:", cap(cell_array))

	game_counter := 0
	movement_counter := 0
	r := 0

	// frame counter
	fps: u8 = 60
	frameDelay: i16 = i16(1000) / i16(fps)

	framStart: u32
	frameTime: i32

	// Create game instance
	game := Game {
		renderer = renderer,
		dt       = frameDelay,
	}

	game_loop: for {

		framStart = sdl2.GetTicks()

		if game_counter % 60 == 0 {
			fmt.println("Length:  ", len(cell_array))
		}

		//every 60 game ticks, we will remove the dead cells from the array
		if game_counter % 60 == 0 {

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

		for c, _ in cell_array {
			mutation_chance: u8 = get_random_Max100()
			if c.age > u16(50) && mutation_chance < u8(10) {
				c.dna[4] = get_random_byte() //direction
				c.bias = get_random_float() //speed	
			}

			c.age += 1
			c.time_since_reproduction += 1

			wrap_cell_position(c)

			if c.age > 120 {
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
					if spawn < u8(1) &&
					   len(cell_array) < 100 &&
					   distance < 200 &&
					   c.can_reproduce &&
					   c2.can_reproduce &&
					   c.time_since_reproduction > 100 &&
					   c.parent1 != c2 &&
					   c.parent2 != c2 {
						c2.time_since_reproduction = 0
						c2.can_reproduce = false
						c.can_reproduce = false
						c.time_since_reproduction = 0

						//reproduce a new cell
						child := new(Cell)
						child.age = 0
						child.is_alive = true
						child.is_growing = true
						child.x = c.x
						child.y = c.y
						child.time_since_reproduction = 0
						child.size = 1
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
				}
			}

			//if is growing debug log 
			if c.is_growing && len(cell_array) < 15 {
				fmt.println("Cell is growing")
				fmt.println("Cell size: ", c.size)
				fmt.println("Cell age: ", c.age)
				fmt.println("Cell time_since_reproduction: ", c.time_since_reproduction)
				fmt.println("Cell dna: ", c.dna)
				fmt.println("Cell bias: ", c.bias)
			}

			map_byte_to_direction := map_byte_to_direction(c.dna[4])
			bias_strength := c.bias * 2

			switch map_byte_to_direction {
			case "N":
				c.x += 1 * f32(bias_strength)
			case "NE":
				c.x += 1 * f32(bias_strength)
				c.y -= 1 * f32(bias_strength)
			case "E":
				c.y -= 1 * f32(bias_strength)
			case "SE":
				c.x -= 1 * f32(bias_strength)
				c.y -= 1 * f32(bias_strength)
			case "S":
				c.x -= 1 * f32(bias_strength)
			case "SW":
				c.x -= 1 * f32(bias_strength)
				c.y += 1 * f32(bias_strength)
			case "W":
				c.y += 1 * f32(bias_strength)
			case "NW":
				c.x += 1 * f32(bias_strength)
				c.y += 1 * f32(bias_strength)
			}

			rect := sdl2.FRect {
				x = c.x,
				y = c.y,
				w = f32(c.size),
				h = f32(c.size),
			}

			if c.is_alive {
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

			if c.age > 400 && v < 0.009 {
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

get_random_float :: proc() -> f64 {
	return rand.float64()
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
