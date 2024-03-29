# ### Coordination from basis
@everywhere function Coordination(Basis)
    Vs  = Basis[1]
    Es  = Basis[2][1]
    
    count = zeros(Int64, length(Vs))
    for edge in Es
        
        for vertex in edge
            count[vertex[1]] += 1
        end
    end
    
    @assert all(count .== count[1]) # check that coordination is same for all all sites otherwise ill-defined
    
    return count[1]
end

# ### Different Unit Cells

@everywhere function CubicBasis(dim)
    n = [binomial(dim, 1) for d in 1:2] # ONLY UP TO EDGES FOR NOW!!!!
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    Verts[1].x = zeros(dim)

    Links = [] # all >0-dim cells
    
    # edges
    Edges = []
    for d in 1:dim
        dir = zeros(dim)
        dir[d] = 1
        
        push!(Edges, [(1, zeros(dim), -1), (1, dir, 1)])
    end
    push!(Links, Edges)
    
    Scale = ones(dim) # scale of the unit cell dimensions
    
    return Verts, Links, n, Scale
end



@everywhere function SquareBasis()
    n = [1, 2, 1]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    Verts[1].x = zeros(2)

    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (1, [1, 0], 1)],
                  [(1, [0, 0], -1), (1, [0, 1], 1)]])
    
    # faces
    push!(Links, [[(1, [0, 0], 1), (2, [1, 0], 1), (1, [0, 1], -1), (2, [0, 0], -1)]])
    
    
    Scale = ones(2) # scale of the unit cell dimensions
    
    return Verts, Links, n, Scale
end



function HexBasis()
    # number of vertices, edges, faces, ...
    n = [4, 6, 2]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [0  , 0  ]
    Verts[2].x = [1/6, 1/2]
    Verts[3].x = [1/2, 1/2]
    Verts[4].x = [2/3, 0  ]
    
    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(2, [0, 0], +1), (3, [0, 0], -1)],
                  [(3, [0, 0], -1), (4, [0, 0], +1)],
                  [(4, [0, 0], +1), (1, [1, 0], -1)],
                  [(3, [0, 0], -1), (4, [0, 1], +1)],
                  [(2, [0, 0], +1), (1, [0, 1], -1)]])
    
    # faces
    push!(Links, [[(6, [0, 0], +1), (2, [0, 0], -1), (5, [0, 0], +1), (3, [0, 1], -1), (2, [0, 1], +1), (1, [0, 1], -1)],
                  [(3, [0, 0], +1), (4, [0, 0], -1), (1, [1, 0], +1), (6, [1, 0], -1), (4, [0, 1], +1), (5, [0, 0], -1)]])
    
    Scale = [3, sqrt(3)] # scale of the unit cell dimensions (such that bond length = 1)
    
    return Verts, Links, n, Scale
end



@everywhere function DiamondBasis()
    # number of vertices, edges, faces, ...
    n = [8, 16]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [0,   0,   0  ]
    Verts[2].x = [1/4, 1/4, 1/4]
    Verts[3].x = [1/2, 1/2, 0  ]
    Verts[4].x = [1/2, 0  , 1/2]
    Verts[5].x = [0,   1/2, 1/2]
    Verts[6].x = [3/4, 3/4, 1/4]
    Verts[7].x = [3/4, 1/4, 3/4]
    Verts[8].x = [1/4, 3/4, 3/4]
    
    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0, 0], -1), (2, [0, 0, 0], +1)],
                  [(2, [0, 0, 0], +1), (3, [0, 0, 0], -1)],
                  [(2, [0, 0, 0], +1), (4, [0, 0, 0], -1)],
                  [(2, [0, 0, 0], +1), (5, [0, 0, 0], -1)],
                  [(3, [0, 0, 0], -1), (6, [0, 0, 0], +1)],
                  [(4, [0, 0, 0], -1), (7, [0, 0, 0], +1)],
                  [(5, [0, 0, 0], -1), (8, [0, 0, 0], +1)],
                  
                  [(6, [0, 0, 0], +1), (1, [1, 1, 0], -1)],
                  [(6, [0, 0, 0], +1), (5, [1, 0, 0], -1)],
                  [(6, [0, 0, 0], +1), (4, [0, 1, 0], -1)],
            
                  [(7, [0, 0, 0], +1), (5, [1, 0, 0], -1)],
                  [(7, [0, 0, 0], +1), (1, [1, 0, 1], -1)],
                  [(7, [0, 0, 0], +1), (3, [0, 0, 1], -1)],
            
                  [(8, [0, 0, 0], +1), (4, [0, 1, 0], -1)],
                  [(8, [0, 0, 0], +1), (3, [0, 0, 1], -1)],
                  [(8, [0, 0, 0], +1), (1, [0, 1, 1], -1)]])
    
    
    Scale = ones(3) .* 4/sqrt(3) # scale of the unit cell dimensions (such that bond lengths=1)
    
    return Verts, Links, n, Scale
end



@everywhere function ShaktiBasis()
    n = [12, 20]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x  = [0  , 0  ]
    Verts[2].x  = [1/4, 0  ]
    Verts[3].x  = [1/2, 0  ]
    Verts[4].x  = [3/4, 0  ]
    Verts[5].x  = [0  , 1/4]
    Verts[6].x  = [1/2, 1/4]
    Verts[7].x  = [0  , 1/2]
    Verts[8].x  = [1/4, 1/2]
    Verts[9].x  = [1/2, 1/2]
    Verts[10].x = [3/4, 1/2]
    Verts[11].x = [0  , 3/4]
    Verts[12].x = [1/2, 3/4]

    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(2, [0, 0], -1), (3, [0, 0], +1)],
                  [(3, [0, 0], -1), (4, [0, 0], +1)],
                  [(4, [0, 0], -1), (1, [1, 0], +1)],
                  [(1, [0, 0], -1), (5, [0, 0], +1)],
                  [(5, [0, 0], -1), (7, [0, 0], +1)],
                  [(2, [0, 0], -1), (8, [0, 0], +1)],
                  [(3, [0, 0], -1), (6, [0, 0], +1)],
                  [(6, [0, 0], -1), (9, [0, 0], +1)],
                  [(6, [0, 0], -1), (5, [1, 0], +1)],
                  [(7, [0, 0], -1), (8, [0, 0], +1)],
                  [(8, [0, 0], -1), (9, [0, 0], +1)],
                  [(9, [0, 0], -1), (10, [0, 0], +1)],
                  [(10, [0, 0], -1), (1, [1, 0], +1)],
                  [(7, [0, 0], -1), (11, [0, 0], +1)],
                  [(11, [0, 0], -1), (1, [0, 1], +1)],
                  [(11, [0, 0], -1), (12, [0, 0], +1)],
                  [(9, [0, 0], -1), (12, [0, 0], +1)],
                  [(12, [0, 0], -1), (3, [0, 1], +1)],
                  [(10, [0, 0], -1), (4, [0, 1], +1)],
            ])
    
    Scale = ones(2) # scale of the unit cell dimensions
    
    return Verts, Links, n, Scale
end



function SemiTriangBasis()
    # number of vertices, edges, faces, ...
    n = [2, 5]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [0  , 0]
    Verts[2].x = [1/2, 0]
    
    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(1, [0, 0], -1), (1, [0, 1], +1)],
                  [(1, [0, 0], -1), (2, [0, 1], +1)],
                  [(2, [0, 0], -1), (2, [0, 1], +1)],
                  [(2, [0, 0], -1), (1, [1, 0], +1)]])

    Scale = [3, sqrt(3)] # scale of the unit cell dimensions (such that bond length = 1)
    
    return Verts, Links, n, Scale
end


function KagomeBasis()
    # number of vertices, edges, faces, ...
    n = [6, 12]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [0, 0]
    Verts[2].x = [0.5, 0]
    Verts[3].x = [0.25, 0.25]
    Verts[4].x = [0, 0.5]
    Verts[5].x = [0.5, 0.5]
    Verts[6].x = [0.75, 0.75]
    
    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(2, [0, 0], -1), (1, [1, 0], +1)],
                  [(1, [0, 0], -1), (3, [0, 0], +1)],
                  [(2, [0, 0], -1), (3, [0, 0], +1)],
                  [(3, [0, 0], -1), (4, [0, 0], +1)],
                  [(3, [0, 0], -1), (5, [0, 0], +1)],
                  [(4, [0, 0], -1), (5, [0, 0], +1)],
                  [(5, [0, 0], -1), (4, [1, 0], +1)],
                  [(5, [0, 0], -1), (6, [0, 0], +1)],
                  [(6, [0, 0], -1), (2, [0, 1], +1)],
                  [(6, [0, 0], -1), (1, [1, 1], +1)],
                  [(6, [0, 0], -1), (4, [1, 0], +1)]])
    
    Scale = [2, 2*sqrt(3)] # scale of the unit cell dimensions (such that bond lengths=1)
    
    return Verts, Links, n, Scale
end


function HexTriBasis()
    # number of vertices, edges, faces, ...
    n = [4, 6]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [0  , 0  ]
    Verts[2].x = [1/6, 1/2]
    Verts[3].x = [1/2, 1/2]
    Verts[4].x = [2/3, 0  ]
    
    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(2, [0, 0], -1), (3, [0, 0], +1)],
                  [(3, [0, 0], -1), (4, [0, 0], +1)],
                  [(4, [0, 0], -1), (1, [1, 0], +1)],
                  [(3, [0, 0], -1), (4, [0, 1], +1)],
                  [(2, [0, 0], -1), (1, [0, 1], +1)]])

    Scale = [3, sqrt(3)] # scale of the unit cell dimensions (such that bond length = 1)
    
    return Verts, Links, n, Scale
end



function GraphiteBasis()
    # number of vertices, edges, faces, ...
    n = [4, 10]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [0  , 0  , 0]
    Verts[2].x = [1/6, 1/2, 0]
    Verts[3].x = [1/2, 1/2, 0]
    Verts[4].x = [2/3, 0  , 0]
    
    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0, 0], -1), (2, [0, 0, 0], +1)],
                  [(2, [0, 0, 0], -1), (3, [0, 0, 0], +1)],
                  [(3, [0, 0, 0], -1), (4, [0, 0, 0], +1)],
                  [(4, [0, 0, 0], -1), (1, [1, 0, 0], +1)],
                  [(3, [0, 0, 0], -1), (4, [0, 1, 0], +1)],
                  [(2, [0, 0, 0], -1), (1, [0, 1, 0], +1)],
            
                  [(1, [0, 0, 0], -1), (1, [0, 0, 1], +1)],
                  [(2, [0, 0, 0], -1), (2, [0, 0, 1], +1)],
                  [(3, [0, 0, 0], -1), (3, [0, 0, 1], +1)],
                  [(4, [0, 0, 0], -1), (4, [0, 0, 1], +1)]])
    
    Scale = [3, sqrt(3), 1] # scale of the unit cell dimensions (such that bond length = 1)
    
    return Verts, Links, n, Scale
end





@everywhere function BathroomTileBasis()
    n = [4, 6]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    Verts[1].x = [1/2, 1/4]
    Verts[2].x = [1/4, 1/2]
    Verts[3].x = [1/2, 3/4]
    Verts[4].x = [3/4, 1/2]

    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(2, [0, 0], -1), (3, [0, 0], +1)],
                  [(3, [0, 0], -1), (4, [0, 0], +1)],
                  [(4, [0, 0], -1), (1, [0, 0], +1)],
                  [(4, [0, 0], -1), (2, [1, 0], +1)],
                  [(3, [0, 0], -1), (1, [0, 1], +1)]])
    
    Scale = ones(2) # scale of the unit cell dimensions
    
    return Verts, Links, n, Scale
end





@everywhere function SnubSquareBasis()
    n = [8, 20]
    
    Verts = [Cell([], [], [], [], []) for j in 1:n[1]]
    
    a = (sqrt(3)-1)/4
    b = a*sqrt(3)
    
    Verts[1].x = [0    , 0    ]
    Verts[2].x = [b    , a    ]
    Verts[3].x = [b+2*a, a    ]
    Verts[4].x = [0    , 2*a  ]
    Verts[5].x = [1/2  , 1/2  ]
    Verts[6].x = [a    , 2*a+b]
    Verts[7].x = [a+2*b, 2*a+b]
    Verts[8].x = [1/2  , 1-a  ]

    Links = [] # all >0-dim cells
    
    # edges
    push!(Links, [[(1, [0, 0], -1), (2, [0, 0], +1)],
                  [(1, [0, 0], -1), (4, [0, 0], +1)],
                  [(2, [0, 0], -1), (3, [0, 0], +1)],
                  [(2, [0, 0], -1), (4, [0, 0], +1)],
                  [(2, [0, 0], -1), (5, [0, 0], +1)],
                  [(3, [0, 0], -1), (5, [0, 0], +1)],
                  [(4, [0, 0], -1), (6, [0, 0], +1)],
                  [(5, [0, 0], -1), (6, [0, 0], +1)],
                  [(5, [0, 0], -1), (7, [0, 0], +1)],
                  [(5, [0, 0], -1), (8, [0, 0], +1)],
                  [(6, [0, 0], -1), (8, [0, 0], +1)],
                  [(7, [0, 0], -1), (8, [0, 0], +1)],
            
                  [(3, [0, 0], -1), (1, [1, 0], +1)],
                  [(3, [0, 0], -1), (4, [1, 0], +1)],
                  [(7, [0, 0], -1), (4, [1, 0], +1)],
                  [(7, [0, 0], -1), (6, [1, 0], +1)],
                  [(7, [0, 0], -1), (1, [1, 1], +1)],
                  [(8, [0, 0], -1), (2, [0, 1], +1)],
                  [(8, [0, 0], -1), (3, [0, 1], +1)],
                  [(6, [0, 0], -1), (1, [0, 1], +1)]])
    
    Scale = ones(2) # scale of the unit cell dimensions
    
    return Verts, Links, n, Scale
end