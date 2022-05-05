include("generation.jl")
include("io.jl")


"""
Argument
- grille : la matrice du problem
"""
function list_of_sameNumber(grille)
	n = size(grille,1)
	aList = []
	for i in 1:n
		for val in 1:n
			sameList = []
			sameIndex = findSameNumber(grille[i,:], val)
			if size(sameIndex,1) > 1
				for index in sameIndex
					append!(sameList,[(i,index)])
				end
			end
			if size(sameList,1) > 1
				append!(aList, [sameList])
			end
		end
	end
	for j in 1:n
		for val in 1:n
			sameList = []
			sameIndex = findSameNumber(grille[:,j], val)
			if size(sameIndex,1) > 1
				for index in sameIndex
					append!(sameList,[(index,j)])
				end
			end
			if size(sameList,1) > 1
				append!(aList, [sameList])
			end
		end
	end
	
	return aList
end


"""
Argument
- l : une liste qui contient des coordonnee des doublons
"""
function random_choose_in_list(l)
	n=size(l,1)
	i=ceil.(Int, n * rand())
	return l[i], i
end

"""
Argument
- l : une liste qui contient des coordonnee des doublons
- i : nombre de ligne
- j : nombre de colonne
"""
function delete_rep_i_j(liste,i,j)
	s = size(liste,1)
	for k=1:s
		if liste[k]==(i,j)
			deleteat!(liste,k)
			break
		end
	end
	return liste
end

"""
Argument
- y : la matrice de la solution
- list : une liste qui contient des coordonnee des doublons
"""
function liste_cases_admissibles(y,list)
	n = size(y,1)
	
	cases_admissibles=[]
	
	for (i,j) in list
		if !isAjacent(y, i, j)
			append!(cases_admissibles,[(i,j)])
		end
	end
	return cases_admissibles
end

"""
Argument
- y : la matrice de la solution
- x : une liste qui contient des coordonnee des doublons
"""
function supprimer_doublons_de_x(y,x)
	n=size(y,1)
	cont=0
	while ((size(x,1)>1)&&(cont<=3*n*n))
		cont=cont+1
		cases_admissibles=liste_cases_admissibles(y,x)
		if cases_admissibles!=[]
			(i,j), _ = random_choose_in_list(cases_admissibles)
			y[i,j] = 0
			if isConnected(y, n) 
				x = delete_rep_i_j(x, i, j)
				cases_admissibles = liste_cases_admissibles(y,x)
			else
				y[i,j] = 1	
			end
		end
	end
	if size(x,1)==1
		return true
	else
		return false
	end
end
