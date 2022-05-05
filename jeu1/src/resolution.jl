# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP
include("generation.jl")
include("io.jl")
include("heuristique.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(p::Matrix{Int64}, n::Int64)

    itermax = 10000
    # Create the model
    m = Model(CPLEX.Optimizer)
    # x = 0 or x = 1
    @variable(m, x[1:size(p,1), 1:size(p,2)], Bin)

    @objective(m, Min, x[1,1])
    # for i in 1:size(p,1)
    #     @constraint(m, [j in 1:size(p,2)], x[i,j] <= 1)
    # end

    # No black square is horizontally adjacent to any other black square.
    for j in 1:size(p,2)
        @constraint(m, [i in 1:size(p,1)-1], x[i,j]+x[i+1,j] >= 1)
    end

    # No black square is vertically adjacent to any other black square.
    for j in 1:size(p,2)-1
        @constraint(m, [i in 1:size(p,1)], x[i,j]+x[i,j+1] >= 1)
    end

    # No number occurs more than once in any row or column.
    for number in 1:n
        @constraint(m, [i in 1:size(p,1)], sum(x[i,k] for k in findSameNumber(p[i,:],number)) <= 1)
        @constraint(m, [j in 1:size(p,2)], sum(x[k,j] for k in findSameNumber(p[:,j],number)) <= 1)
    end
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    x_m = JuMP.value.(x)
    iter = 0
    while !isConnected(x_m, n) && iter <= itermax
        @constraint(m, sum(x[i,j] for i in 1:n for j in 1:n if x_m[i,j]==0)>=1)
        optimize!(m)
        x_m = JuMP.value.(x)
        iter = iter+1
    end
    println("Nombre iteration : ", iter)
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start, JuMP.value.(x)
    
end


"""
Heuristically solve an instance
"""

function heuristicSolve(p::Matrix{Int64})
    n = size(p,1)
	y = ones(Int,n,n)
	iter = 0
	cases_noires = false
	doublons = list_of_sameNumber(p)
	while (doublons!=[]) && (iter<=3*n*n)
		iter += 1
		x, kx = random_choose_in_list(doublons)
		cases_noires = supprimer_doublons_de_x(p,y,x)
		if cases_noires
			deleteat!(doublons,kx)
		end
	end
	if doublons == []
		isOptimal = true
		return isOptimal, y
	else 
		isOptimal = false
		return isOptimal, ones(Int,n,n)
	end
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    # resolutionMethod = ["cplex"]
    resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        n, p = readInputFile(dataFolder * file)

        println("Loading the puzzle...")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # arguments : p::Matrix of the problem
                    #             n::Size of matrix
                    # return values : isOptimal
                    #                 resolutionTime::Duration to solve the problem
                    #                 result::Binary matrix of result
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime, result = cplexSolve(p, n)
                    result = round_matrix(result)
                    # If a solution is found, write it
                    if isOptimal
                        println(fout, "result = ",result)
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 15
                        
                        
                        # Solve it and get the results
                        isOptimal, result = heuristicSolve(p)

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        println(fout, "result = ",result)
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                println(fout, "solution = ", p.*result)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end


