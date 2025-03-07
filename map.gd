extends Node2D

var final_maze
var final_offset
var on_exit

func _init_matrix(m: int, n: int, val: int) -> Array:
	var mat := []
	for r in range(m):
		var row := []
		for c in range(n):
			row.append(val)
		mat.append(row)
	return mat

func _pretty_print_mat(mat: Array) -> void:
	var d := {
		0: "-",
		1: "■",
		2: "▤",
		3: "⎯"
	}
	for r in range(len(mat)):
		var s := ""
		for c in range(len(mat[r])):
			s += d[mat[r][c]] + " "
		print(s)

func _find_centermost_index(arr: Array, target: Variant) -> int:
	var min_dist := len(arr)
	var res := -1
	for i in range(len(arr)):
		if arr[i] == target:
			@warning_ignore("integer_division")
			var dist := abs(len(arr)/2 - i) as int
			if dist < min_dist:
				min_dist = dist
				res = i
	return res

# Pads the maze matrix's left, right, and bottom sides with walls. Extends the exit hallway as well.
func _extend_outer_walls(mat: Array, n_layers: int) -> Array:
	# pad top and bottom sides
	var v_padding := []
	v_padding.resize(len(mat[0]))
	v_padding.fill(1)
	for i in range(n_layers):
		mat.append(v_padding.duplicate())
		mat.insert(0, mat[0].duplicate())
	
	# pad left and right sides
	for r in range(len(mat)):
		for i in range(n_layers):
			mat[r].append(1)
			mat[r].insert(0, 1)
	
	return mat

func _cap_exit(mat: Array) -> Array:
	var padding := []
	padding.resize(len(mat[0]))
	padding.fill(1)
	mat.insert(0, padding)
	return mat

# Returns the local coordinates of one of the maze's starting tiles.
func get_start_position(mat: Array, offset: Vector2i) -> Vector2i:
	for r in range(len(mat)-1, -1, -1):
		var c := (mat[r] as Array).find(0)
		if c != -1:
			return $Floor.map_to_local(Vector2i(c, r) + offset) + ($Floor.tile_set.tile_size as Vector2)*Vector2(0.75, -0.75)
	return Vector2i()

func _add_end_tiles(mat: Array) -> Array:
	for r in range(len(mat)):
		var found := false
		for c in range(len(mat[r])):
			if mat[r][c] == 0:
				mat[r][c] = 3
				found = true
		if found:
			break
	return mat
	
func generate_maze(m: int, n: int) -> Array:
	# initialize maze
	var mat := _init_matrix(m, n, 1)
	
	# generate maze
	generate_maze_helper(mat, randi() % m, randi() % n)
	
	# add outer walls
	for row in mat:
		row.insert(0, 1)
		row.append(1)
	var top := []
	var bottom := []
	top.resize(n+2)
	top.fill(1)
	bottom.resize(n+2)
	bottom.fill(1)
	
	mat.insert(0, top)
	mat.append(bottom)
	
	# poke holes for start and end (bottom and top, respectively)
	mat[0][_find_centermost_index(mat[1], 0)] = 0
	mat[-1][_find_centermost_index(mat[-2], 0)] = 0
	_pretty_print_mat(mat)
	print()
	return mat

var straights := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

# Iterative DFS function that carves out the open spots in the input maze matrix from the starting cell
func generate_maze_helper(mat: Array, r: int, c: int) -> void:
	var st := []
	st.append(Vector2i(r, c))
	
	while len(st) > 0:
		var curr := st.pop_back() as Vector2i
		mat[curr.x][curr.y] = 0

		straights.shuffle()
		for v in straights:
			var p := Vector2i(curr.x, curr.y) + (v as Vector2i)
			if _check_in_bounds(mat, p.x, p.y) and mat[p.x][p.y] == 1 and _is_cell_visitable(mat, p.x, p.y):
				st.append(curr)
				st.append(p)
				break

# Returns a new matrix with each row duplicated `factor` times
func _vertical_stretch(mat: Array, factor: int) -> Array:
	var res := []
	for row in mat:
		for i in range(factor):
			res.append((row as Array).duplicate())
	return res

# Returns a new matrix with each column duplicated `factor` times
func _horizontal_stretch(mat: Array, factor: int) -> Array:
	var res := []
	for r in range(len(mat)):
		res.append([])

	for c in range(len(mat[0])):
		for i in range(factor):
			for r in range(len(mat)):
				res[r].append(mat[r][c])
	return res

# Changes the wall type of any front-facing cell
func _adjust_wall_types(mat: Array) -> Array:
	var r := len(mat) - 1
	mat.append([])
	mat[-1].resize(len(mat[0]))
	mat[-1].fill(0)
	while r > -1:
		for c in range(len(mat[r])):
			if mat[r][c] == 1 and mat[r+1][c] == 0: # front-facing wall
				mat[r][c] = 2
		r -= 1
	mat.pop_back()
	return mat

func _check_in_bounds(mat: Array, r: int, c: int) -> bool:
	return r > -1 and c > -1 and r < len(mat) and c < len(mat[r])

func _is_cell_visitable(mat: Array, r: int, c: int) -> bool:
	var n_open := 0
	for v in straights:
		var p := Vector2i(r, c) + (v as Vector2i)
		if _check_in_bounds(mat, p.x, p.y) and mat[p.x][p.y] == 0:
			n_open += 1
	if n_open != 1:
		return false
	
	var topleft := Vector2i(r, c) + Vector2i.LEFT + Vector2i.UP
	var topright := Vector2i(r, c) + Vector2i.RIGHT + Vector2i.UP
	var bottomleft := Vector2i(r, c) + Vector2i.LEFT + Vector2i.DOWN
	var bottomright := Vector2i(r, c) + Vector2i.RIGHT + Vector2i.DOWN
	
	if (_check_in_bounds(mat, topleft.x, topleft.y) 
		and mat[(topleft+Vector2i.DOWN).x][(topleft+Vector2i.DOWN).y] == 1
		and mat[(topleft+Vector2i.RIGHT).x][(topleft+Vector2i.RIGHT).y] == 1
		and mat[topleft.x][topleft.y] == 0
	):
		return false
	
	if (_check_in_bounds(mat, topright.x, topright.y) 
		and mat[(topright+Vector2i.DOWN).x][(topright+Vector2i.DOWN).y] == 1
		and mat[(topright+Vector2i.LEFT).x][(topright+Vector2i.LEFT).y] == 1
		and mat[topright.x][topright.y] == 0
	):
		return false
	
	if (_check_in_bounds(mat, bottomleft.x, bottomleft.y) 
		and mat[(bottomleft+Vector2i.UP).x][(bottomleft+Vector2i.UP).y] == 1
		and mat[(bottomleft+Vector2i.RIGHT).x][(bottomleft+Vector2i.RIGHT).y] == 1
		and mat[bottomleft.x][bottomleft.y] == 0
	):
		return false
	
	if (_check_in_bounds(mat, bottomright.x, bottomright.y) 
		and mat[(bottomright+Vector2i.UP).x][(bottomright+Vector2i.UP).y] == 1
		and mat[(bottomright+Vector2i.LEFT).x][(bottomright+Vector2i.LEFT).y] == 1
		and mat[bottomright.x][bottomright.y] == 0
	):
		return false
	return true

# `maze` should be a fully transformed maze (after post-processing)
func get_spawn_area(maze: Array, n_candidate_rows: int, bottom_padding: int) -> Array:
	var candidates := []
	for r in range(len(maze) - 1 - bottom_padding, len(maze) - 2 - bottom_padding - n_candidate_rows, -1):
		for c in range(len(maze[r])):
			if maze[r][c] == 0:
				candidates.append(Vector2i(r, c))
	return candidates
	
# Places the maze tiles on the map based on a provided matrix of integers 0, 1, and 2.
# 0 = open tile, 1 = wall tile (top texture), 2 = wall tile (side texture), 3 = finish line
func build_maze(mat: Array, offset: Vector2i) -> void:
	for r in range(len(mat)):
		for c in range(len(mat[r])):
			$Floor.set_cell(Vector2i(c, r) + offset, 1, Vector2i(0, 0))
			if mat[r][c] == 1:
				$Walls.set_cell(Vector2i(c, r) + offset, 2, Vector2i(0, 0))
			elif mat[r][c] == 2:
				$Walls.set_cell(Vector2i(c, r) + offset, 2, Vector2i(0, 1))
			elif mat[r][c] == 3:
				$Exit.set_cell(Vector2i(c, r) + offset, 0, Vector2i(0, 0))

func erase_maze(mat: Array, offset: Vector2i):
	for r in range(len(mat)):
		for c in range(len(mat[r])):
			$Floor.erase_cell(Vector2i(c, r) + offset)
			$Walls.erase_cell(Vector2i(c, r) + offset)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var padding := 4
	var maze := _horizontal_stretch(_vertical_stretch(generate_maze(5, 5), 2), 2)
	maze = _cap_exit(_add_end_tiles(_adjust_wall_types(_extend_outer_walls(maze, padding))))
	_pretty_print_mat(maze)
	var offset := Vector2i(-len(maze[0])/2, -len(maze)-1)
	build_maze(maze, offset)
	final_maze = maze
	final_offset = offset

func get_maze():
	return final_maze

func get_offset():
	return final_offset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
