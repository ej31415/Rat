extends Node2D

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
		2: "▤"
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

# recursive DFS function that carves out the open spots in the input maze matrix
func generate_maze_helper(mat: Array, r: int, c: int) -> void:
	mat[r][c] = 0
	straights.shuffle()
	for v in straights:
		var p := Vector2i(r, c) + (v as Vector2i)
		if _check_in_bounds(mat, p.x, p.y) and mat[p.x][p.y] == 1 and _is_cell_visitable(mat, p.x, p.y):
			generate_maze_helper(mat, p.x, p.y)

func expand_horizontals(mat: Array) -> Array:
	var r := len(mat) - 1 # index starting from bottom row
	mat.append([])
	mat[-1].resize(len(mat[0]))
	mat[-1].fill(0)
	while r > -1:
		var marked := []
		for c in range(len(mat[r])):
			if mat[r][c] == 1 and mat[r+1][c] == 0: # front-facing wall
				marked.append(c)
		mat.insert(r, (mat[r] as Array).duplicate())
		for m in marked:
			mat[r+1][m] = 2
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

func build_maze(mat: Array, offset: Vector2i) -> void:
	for r in range(len(mat)):
		for c in range(len(mat[r])):
			$Floor.set_cell(Vector2i(c, r) + offset, 0, Vector2i(0, 0))
			if mat[r][c] == 1:
				$Walls.set_cell(Vector2i(c, r) + offset, 2, Vector2i(0, 0))
			elif mat[r][c] == 2:
				$Walls.set_cell(Vector2i(c, r) + offset, 2, Vector2i(0, 1))
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var maze := expand_horizontals(generate_maze(15, 15))
	_pretty_print_mat(maze)
	build_maze(maze, Vector2i(-len(maze[0])/2, -len(maze)-1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
