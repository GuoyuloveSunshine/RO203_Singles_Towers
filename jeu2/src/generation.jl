# This file contains methods to generate a data set of instances (i.e., towers grids).
include("io.jl")

"""
Verify the number v at the position (i, j) emerge the first time in line i and colonne j.

Arguments
    - grid: the grid that to be valued
    - i: the line
    - j: the colonne
    - v: the number
"""
function isNumberValuable(grid::Array{Int64, 2}, i::Int64, j::Int64, v::Int64)
    n = size(grid,1)

    ## Check the line no same number as v.
    for l in 1:n
        if grid[l, j] == v
            return false
        end
    end

    ## Check the colonne no same number as v.
    for c in 1:n
        if grid[i, c] == v
            return false
        end
    end
    return true
end

"""
Verify the two number in the position of opposite visibility vector is valuable, the criterion is that the
sum of these two values can not be greater than n+1 (from one side all towers can be seen and from the 
opposite only the tallest can be seen) and can not be smaller than 3 (for one side only the tallest can be 
seen and from the opposite only the tallest and the second tallest can be seen).

Arguments:
    - n: size of the grid
    - int1: number in the visibility vector
    - int2: number opposite int1 
"""
function isNumberFonction(n:: Int64, int1::Int64, int2::Int64)
    if int1 + int2 > n+1
        return false
    end
    if int1 + int2 < 3
        return false
    end
    return true
end

"""
Generate Grid array with size n.

Argument:
    - n: size of the grid
"""
function generateGrid(n::Int64)
    ## Generate a grid.
    grid = Array{Int64, 2}(zeros(n, n))
    filledGrid = 0

    ## If not all grid are filled.
	while(filledGrid < n*n)
		i = Int64(floor(filledGrid/n)+1)
		j = rem(filledGrid,n)+1
		numTried = Array{Int64}(zeros(0))
		
        ## Find a valuable number in [|1, n|].
		v = rand(1:n)
		push!(numTried,v)

		while !isNumberValuable(grid,i,j,v) && size(numTried, 1) < n
			v = rand(1:n)
			if !(v in numTried)
				push!(numTried,v)
			end
		end
        ## If the number is found, fill in the corresponding grid.
		grid[i,j] = v
		filledGrid += 1
		## If we cannot find a number to fill the grid, we clean the grid and do once again.
		if size(numTried, 1) >= n
			grid = Array{Int64, 2}(zeros(n, n))
			filledGrid = 0
		end
	end
    return grid
end

"""
Calculate 4 visibility vectors with generated grid.

Argument:
    - grid: the grid of size n
"""
function generateVisibility(grid::Array{Int64, 2})
    n = size(grid, 1)
    vL = Vector{Int64}(zeros(n))
    vR = Vector{Int64}(zeros(n))
    vU = Vector{Int64}(zeros(n))
    vD = Vector{Int64}(zeros(n))

    ## Calculate the visibility vector from left side.
    for l in 1:n
        max = 0
        num = 0
        for c in 1:n
            if grid[l, c] > max
                max = grid[l, c]
                num +=1
            end
        end
        vL[l] = num
    end

    ## Calculate the visibility vector from right side.
    for l in 1:n
        max = 0
        num = 0
        for c in 0:n-1
            if grid[l, n-c] > max
                max = grid[l, n-c]
                num +=1
            end
        end
        vR[l] = num
    end

    ## Calculate the visibility vector from top(up) side.
    for c in 1:n
        max = 0
        num = 0
        for l in 1:n
            if grid[l, c] > max
                max = grid[l, c]
                num +=1
            end
        end
        vU[c] = num
    end

    ## Calculate the visibility vector from bottom(down) side.
    for c in 1:n
        max = 0
        num = 0
        for l in 0:n-1
            if grid[n-l, c] > max
                max = grid[n-l, c]
                num +=1
            end
        end
        vD[c] = num
    end
    return vL, vR, vU, vD
end
"""
Generate a game which is hardly resolved.

Argument:
    - n: the size of the game
"""
function generateInstanceNoResolved(n::Int64)

    ## Generate the game.
    aData = Array{Int64, 2}(zeros(n+2,n+2))

    ## Fill the visibility vectors.
    for i in 1:n
        int1 = rand(1:n)
        int2 = rand(1:n)
        int3 = rand(1:n)
        int4 = rand(1:n)

        while !isNumberFonction(n, int1, int2)
            int1 = rand(1:n)
            int2 = rand(1:n)
        end
        while !isNumberFonction(n, int3, int4)
            int3 = rand(1:n)
            int4 = rand(1:n)
        end
    
        aData[1  , i+1] = int1 ## Fill up visibility vector.
        aData[n+2, i+1] = int2 ## Fill down visibility vector.
        aData[i+1,   1] = int3 ## Fill left visibility vector.
        aData[i+1, n+2] = int4 ## Fill right visibility vector.
    end
    return aData
end

"""
Generate a game which is definitely resolved and whose level is normal. e.g.
    5  3  2  1  4
   ----------------
4 | -  -  -  -  -  | 1
4 | -  -  -  -  -  | 2
1 | -  -  -  -  -  | 5
1 | -  -  -  -  -  | 2
3 | -  -  -  -  -  | 1
   ----------------
    1  1  4  3  1

Argument:
    - n: the size of the game
"""
function generateInstanceNormal(n::Int64)

    ## Generate a grid of size n.
    grid = generateGrid(n)

    ## Generate the visibility vectors from the grid.
    vL, vR, vU, vD = generateVisibility(grid)

    ## Generate the game.
    aData = Array{Int64, 2}(zeros(n+2,n+2))

    ## Fille the visibility vector in the game.
    for i in 1:n
        aData[1  , i+1] = vU[i]
        aData[n+2, i+1] = vD[i]
        aData[i+1,   1] = vL[i]
        aData[i+1, n+2] = vR[i]
    end
    
    return aData
end

"""
Generate a game which is definitely resolved and whose level is hard. e.g.
    -  -  1  -  -
   ----------------
- | -  -  -  -  1  | 3
- | -  -  -  -  -  | -
- | -  -  -  -  -  | -
- | -  -  -  -  -  | -
1 | 5  -  -  -  -  | 2
   ----------------
    1  -  3  2  -

Argument:
    - n: the size of the game
"""
function generateInstanceHard(n::Int64)

    ## Generate a grid of size n.
    grid = generateGrid(n)

    ## Generate the visibility vectors from the grid.
    vL, vR, vU, vD = generateVisibility(grid)

    ## Generate the game.
    aData = Array{Int64, 2}(zeros(n+2,n+2))

    ## Fill the numbers in the game.
    for temp in 1:floor(n/2)
        line = rand(1:n)
        col = rand(1:n)
        aData[line+1, col+1] = grid[line,col]
    end

    ## Fille the visibility vector in the game. Each position have 40% to contain a number.
    for i in 1:n
        aRand = rand()
        if aRand < 0.4
            aData[1  , i+1] = vU[i]
        end
        aRand = rand()
        if aRand < 0.4
            aData[n+2, i+1] = vD[i]
        end
        aRand = rand()
        if aRand < 0.4
            aData[i+1,   1] = vL[i]
        end
        aRand = rand()
        if aRand < 0.4
            aData[i+1, n+2] = vR[i]
        end
    end
    
    # println(aData)
    return aData
end 


"""
Generate all the instances included resolved and non resolved.

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
    type = ["normal", "hard"]
    # For each grid size considered
    for size in 5:11
        # Generate 10 instances
        for instance in 1:10
            # For each niveau considered
            for level in type

                fileName = "../data/instance_t" * string(size) * "_" * level * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    if level == "normal"
                        aRand = rand()
                        if aRand < 0.8
                            saveInstance(generateInstanceNormal(size), fileName)
                        else
                            saveInstance(generateInstanceNoResolved(size), fileName)
                        end
                    else
                        saveInstance(generateInstanceHard(size), fileName)
                    end

                end
            end 
        end
    end
end



