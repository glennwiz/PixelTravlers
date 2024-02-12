package PixelTravler

import "core:fmt"
import "core:math/linalg"
import "vendor:sdl2"

/*
    Maxwell's Daemon, in Gnipahellir's depths, plays a cunning game,
    With points of memory as his pawns, in entropy's endless frame.
    Garm, the guardian fierce at Gnipahellir's gate, snarls at each move,
    Yet the Daemon defies, weaving past and present, in Gnipahellir's groove.

    Those who dare to fail miserably can achieve greatly
*/

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 320
GRID_SIZE :: 64
GRID_STATE :: [GRID_SIZE][GRID_SIZE]Cell
CELL_SIZE :: 5

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
	x: int,
    y: int,
    is_alive: bool,
	color: Vec4,
	life: bool,	
	bias: f64,
	dna: []byte,
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
    for i := 0; i < GRID_SIZE; i = i + 1 {
        for j := 0; j < GRID_SIZE; j = j + 1 {
            grid[i][j] = Cell{i, j, false, Vec4{0, 0, 0, 0}, false, 0.0, []byte{}, nil, nil}
        }
    }

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
	
    cell_grid:= make([dynamic][dynamic]Cell, 100, 100)
		
    dyn := make([dynamic]int, 5, 5)

	fmt.println("screen_width: ", WINDOW_WIDTH)
	fmt.println("screen_height: ", WINDOW_HEIGHT)
	fmt.println("cell_size: ", CELL_SIZE)


	
	game_loop : for {

        fmt.println("tick")
		// lets paint a fluresent green cell
		grid[32][32].color = Vec4{255, 255, 0, 255}
		grid[32][32].is_alive = true

        // Drawing gradient from black to grey
        for x :i32= 0; x < WINDOW_WIDTH; x += 1 {
            fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
            sdl2.SetRenderDrawColor(game.renderer, fade, fade, fade, 255)
            sdl2.RenderDrawLine(game.renderer, x, 0, x, WINDOW_HEIGHT)
        } 

		rect := sdl2.Rect{
			x = WINDOW_WIDTH / 2 - (CELL_SIZE / 2),
			y = WINDOW_HEIGHT / 2 - (CELL_SIZE / 2),
	
			w = CELL_SIZE,
			h = CELL_SIZE,
		}

		cell := grid[32][32]

		sdl2.SetRenderDrawColor(renderer, cell.color.r, cell.color.g, cell.color.b, cell.color.a) 
		sdl2.RenderFillRect(renderer, &rect)
		 
		sdl2.RenderPresent(renderer)
	}
}