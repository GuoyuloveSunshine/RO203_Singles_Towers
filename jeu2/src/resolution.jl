# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(t::Array{Int, 2}, vL::Array{Int, 1}, vR::Array{Int, 1}, vU::Array{Int, 1}, vD::Array{Int, 1})
    
    n = size(t, 1)
    # Create the model
    m = Model(CPLEX.Optimizer)
    # Start a chronometer
    start = time()

    # xk[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, xk[1:n, 1:n, 1:n], Bin)

    # Visibility
    # vl[i, j] = 1 if cell(i, j) is visible from left side
    @variable(m, vl[1:n, 1:n], Bin)
    # vr[i, j] = 1 if cell(i, j) is visible from right side
    @variable(m, vr[1:n, 1:n], Bin)
    # vu[i, j] = 1 if cell(i, j) is visible from up side
    @variable(m, vu[1:n, 1:n], Bin)
    # vd[i, j] = 1 if cell(i, j) is visible from down side
    @variable(m, vd[1:n, 1:n], Bin)

    # Set the fixed value in the grid
    for l in 1:n
        for c in 1:n
            if t[l, c] != 0
                @constraint(m, xk[l,c, t[l, c]] == 1)
            end
        end
    end

    # Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(xk[i, j, k] for k in 1:n) == 1)

    # Each line l has one cell with value k
    @constraint(m, [k in 1:n, l in 1:n], sum(xk[l, j, k] for j in 1:n) == 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, c in 1:n], sum(xk[i, c, k] for i in 1:n) == 1)


    # Left visible constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], vl[i,j]<=1-sum(xk[i,c,kp] for c in 1:j-1 for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], vl[i,j]>=1-sum(xk[i,c,kp] for c in 1:j-1 for kp in k:n)-n*(1-xk[i,j,k]))
	for lineV in 1:n
        if vL[lineV] != 0
            @constraint(m, sum(vl[lineV, j] for j in 1:n) == vL[lineV])
        end
    end

    # Right visible constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], vr[i,j]<=1-sum(xk[i,c,kp] for c in j+1:n for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], vr[i,j]>=1-sum(xk[i,c,kp] for c in j+1:n for kp in k:n)-n*(1-xk[i,j,k]))
    for lineV in 1:n
        if vR[lineV] != 0
            @constraint(m, sum(vr[lineV, j] for j in 1:n) == vR[lineV])
        end
    end

    # Up visibility constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], vu[i,j]<=1-sum(xk[l,j,kp] for l in 1:i-1 for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], vu[i,j]>=1-sum(xk[l,j,kp] for l in 1:i-1 for kp in k:n)-n*(1-xk[i,j,k]))
    for lineV in 1:n
        if vU[lineV] != 0
            @constraint(m, sum(vu[j, lineV] for j in 1:n) == vU[lineV])
        end
    end

    # Down visibility constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], vd[i,j]<=1-sum(xk[l,j,kp] for l in i+1:n for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], vd[i,j]>=1-sum(xk[l,j,kp] for l in i+1:n for kp in k:n)-n*(1-xk[i,j,k]))
    
    for lineV in 1:n
        if vD[lineV] != 0
            @constraint(m, sum(vd[j, lineV] for j in 1:n) == vD[lineV])
        end
    end

    # Maximize the top-left cell (reduce the problem symmetry)
    @objective(m, Max, sum(xk[1, 1, k] for k in 1:n))
    # Solve the model
    optimize!(m)

    # Return:
    # 1 - the value of xk
    # 2 - true if an optimum is found
    # 3 - the resolution time
    return xk, JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
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
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

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
    for file in filter(xk->occursin(".txt", xk), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        t, vL, vR, vU, vD = readInputFile(dataFolder * file)
        displayGrid(t,vL,vR,vU,vD)
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            # println(methodId)
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    # println("111")
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), cplex")
                    
                    # Solve it and get the results
                    xk, isOptimal, resolutionTime = cplexSolve(t, vL, vR, vU, vD)
                    solveTime = resolutionTime
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout, xk)
                        displaySolution(xk, vL, vR, vU, vD)
                    end

                # If the method is one of the heuristics
                else
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            # include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
