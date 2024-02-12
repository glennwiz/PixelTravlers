package PixelTravler

import "core:fmt"
import "core:math/linalg"
import "vendor:sdl2"

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 320
GRID_STATE :: [dynamic][dynamic]Cell
CELL_SIZE :: 5
NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE

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
	fmt.println("num_cells_x: ", NUM_CELLS_X)
	fmt.println("num_cells_y: ", NUM_CELLS_Y)

	// Calculate middle cell coordinates
	middle_x := NUM_CELLS_X / 2
	middle_y := NUM_CELLS_Y / 2


	
	game_loop : for {

        fmt.println("tick")
		// we need to draw the pixels by 1 * CELL_SIZE

		//the game loop updates a freaking lot so lets some % modulo to update the cells every 60th frame or so, oh and lets add pluss and minus for update speed
		//also lets add a pause button 'space' and a clear button 'c'


		sdl2.RenderPresent(renderer)
	}
}