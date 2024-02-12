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

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 320
GRID_SIZE :: 64
GRID_STATE :: [GRID_SIZE][GRID_SIZE]^Cell
CELL_SIZE :: 10

Game :: struct {
	renderer: ^sdl2.Renderer,
	keyboard: []u8,
	time:     f64,
	dt:       f64,
}

Vec4 :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Cell :: struct {
	x: i32,
    y: i32,
    is_alive: bool,
	color: Vec4,
	bias: f64,
	dna: [30]byte,
	parent1: ^Cell, // Pointer to first parent cell
	parent2: ^Cell, // Pointer to second parent cell
}

zoom_level :i32 = 20

get_time :: proc() -> f64 {
	return f64(sdl2.GetPerformanceCounter()) * 1000 / f64(sdl2.GetPerformanceFrequency())
}

main :: proc() {

    fmt.println("-----------------------------------------")

    // Create a 64x64 grid of boolean values
    grid := GRID_STATE{}

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

	tickrate := 10.0
	ticktime := 1000.0 / tickrate

	game := Game {
		renderer = renderer,
		time     = get_time(),
		dt       = ticktime,	
	}

	fmt.println("screen_width: ", WINDOW_WIDTH)
	fmt.println("screen_height: ", WINDOW_HEIGHT)
	fmt.println("cell_size: ", CELL_SIZE)
	fmt.println("-----------------------------------------")
	event : sdl2.Event

	// lets paint a yellow cell
	cell := new(Cell)
	cell.color = Vec4{255, 255, 0, 255}
	cell.is_alive = true
	cell.x = WINDOW_WIDTH / 2 - (CELL_SIZE / 2)
	cell.y = WINDOW_HEIGHT / 2 - (CELL_SIZE / 2)
	
	// add the cell to the grid
	grid[cell.x / CELL_SIZE][cell.y / CELL_SIZE] = cell
	
	game_counter := 0

	game_loop : for {
		game_counter += 1
	
		if(cell.y > WINDOW_HEIGHT) {
			cell.y = 0 - CELL_SIZE
		}
		if cell.y < 0 - CELL_SIZE{
			cell.y = WINDOW_HEIGHT			
		}

		if(cell.x > WINDOW_WIDTH) {
			cell.x = 0 - CELL_SIZE
		}

		if cell.x < 0 - CELL_SIZE{
			cell.x = WINDOW_WIDTH
		}
		
        // Drawing gradient from black to grey
        for x :i32= 0; x < WINDOW_WIDTH; x += 1 {
            fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
            sdl2.SetRenderDrawColor(game.renderer, fade, fade, fade, 255)
            sdl2.RenderDrawLine(game.renderer, x, 0, x, WINDOW_HEIGHT)
        } 		

		if game_counter % 10 == 0 {		

			r := rand.int_max(4)
			if r == 0 {
				cell.x += 1
			} 
			
			if r == 1 {
				cell.y -= 1
			}   
			
			if r == 2 {
				cell.x -= 1
			}

			if r == 3 {
				cell.y += 1
			}
		}

		rect := sdl2.Rect{
			x = cell.x,
			y = cell.y,	
			w = CELL_SIZE,
			h = CELL_SIZE,
		}	

		sdl2.SetRenderDrawColor(game.renderer, cell.color.r, cell.color.g, cell.color.b, cell.color.a) 
		sdl2.RenderFillRect(game.renderer, &rect)
		 
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
								break game_loop  }
					}
				}
			}
		}
	}
}
