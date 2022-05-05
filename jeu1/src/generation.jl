# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    numbers = Vector{Int64}(1:n)
    x = ones(n, n)
    p = round_matrix(zeros(n,n))
    n_zeros = floor(n*n*density/2)

    # place zeros in x
    max_iter = 500
    iter = 1
    iter2 = 1
    num = 1
    while num <= n_zeros
        iter = 1
        i = rand(numbers)
        j = rand(numbers)
        while (x[i,j]==0 || isAjacent(x, i, j)) && iter <= max_iter
            i = rand(numbers)
            j = rand(numbers)
            iter = iter + 1
        end
        # println(num,":(",i,j,")",iter)
        if iter >= max_iter
            break
        end
        x[i, j] = 0
        if !isConnected(x, n) && iter2<=n_zeros*max_iter
            x[i, j] = 1
            num = num-1
            iter2 = iter2+1
        end
        if iter2>=n_zeros*max_iter
            break
        end
        num = num+1
    end

    # creat puzzle
    all_ones = findall(isequal(1), x)
    all_zeros = findall(isequal(0), x)
    index = 1
    iter3 = 1
    while index <= size(all_ones,1) && iter3 <= max_iter
        coord = all_ones[index]
        flag = choose4one(p, numbers, coord[1], coord[2])
        if !flag
            index = 0
            p[all_ones] .= 0
            iter3 = iter3 + 1
        end
        index = index+1
    end
    for coord in all_zeros
        choose4zero(p, x, coord[1], coord[2])
    end


    return x, p, iter>=max_iter || iter2>=n_zeros*max_iter, iter3>=max_iter
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
    dataFolder = "../data/"
    file_pre = "puzzle_size"
    for n in 5:12
        for num in 1:10
            outputFile = dataFolder * file_pre * string(n) * "_" * string(num) * ".txt"
            if !isfile(outputFile)
                println("Creating data n.", num, " for puzzle of size ", n, "...")
                fout = open(outputFile, "w")  
                x,p,b1,b2 = generateInstance(n, 0.8)
                while (b2)
                    x,p,b1,b2 = generateInstance(n, 0.8)
                end
                for i in 1:size(p,1)
                    for j in 1:size(p,2)-1
                        print(fout, p[i, j], ",")
                    end
                    println(fout, p[i, size(p,2)])
                end
                close(fout)
            else
                println("Data n.", num, " for puzzle of size ", n, " exist.")
            end
        end
    end
    
end



