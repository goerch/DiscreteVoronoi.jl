using LinearAlgebra
using Random
using Distributions

export rand_points, rand_sites, equal_grid_points, equal_grid_sites

function _findmin(f, xs)
    min_index = 0
    local min_fx
    for (index, x) in enumerate(xs)
        fx = f(x)
        if min_index == 0 || fx < min_fx
            min_index = index
            min_fx = fx
        end
    end
    min_fx, min_index
end

function _findmax(f, xs)
    max_index = 0
    local max_fx
    for (index, x) in enumerate(xs)
        fx = f(x)
        if max_index == 0 || fx > max_fx
            max_index = index
            max_fx = fx
        end
    end
    max_fx, max_index
end

function _minimum(f, xs)
    min_index = 0
    local min_fx
    for (index, x) in enumerate(xs)
        fx = f(x)
        if min_index == 0 || fx < min_fx
            min_index = index
            min_fx = fx
        end
    end
    min_fx
end

function _maximum(f, xs)
    max_index = 0
    local max_fx
    for (index, x) in enumerate(xs)
        fx = f(x)
        if max_index == 0 || fx > max_fx
            max_index = index
            max_fx = fx
        end
    end
    max_fx
end

function _any(f, xs)
    for x in xs
        f(x) && return true
    end
    return false
end

function _all(f, xs)
    for x in xs
        !f(x) && return false
    end
    return true
end

function _filter(f, xs)
    (x for x in xs if f(x))
end

function unstable_partition!(f, A)
    i, j = 1, length(A)
    @inbounds while true
        while i < j && f(A[i])
            i += 1
        end
        while i < j && !f(A[j])
            j -= 1
        end
        if i < j
            A[i], A[j] = A[j], A[i]
            i += 1
            j -= 1
        else
            break
        end
    end
    if i == j
        if f(A[i])
            @views return A[1:i], A[(i+1):length(A)]
        else
            @views return A[1:(i-1)], A[i:length(A)]
        end
    else
        @assert i == j + 1
        @views return A[1:j], A[i:length(A)]
    end
end

@inbounds function round_tuple(x)
    (round(Int, x[1]), round(Int, x[2]))
end

function in_rectangle(rect, point)
    (t, l), (b, r) = rect
    (x, y) = point
    t <= x <= b && l <= y <= r
end

function get_center(rect)
    (t, l), (b, r) = rect
    ((t + b) / 2, (l + r) / 2)
end

function get_corners(rect)
    (t, l), (b, r) = rect
    (t, l), (t, r), (b, r), (b, l)
end

function get_edges(rect)
    (t, l), (b, r) = rect
    (((t, j) for j in l:r)...,
     ((i, r) for i in t:b)...,
     ((b, j) for j in l:r)...,
     ((i, l) for i in t:b)...)
end

function get_quadrants(rect)
    (t, l), (b, r) = rect
    Nd = (b - t) ÷ 2
    Md = (r - l) ÷ 2
    return (((t, l), (t + Nd, l + Md)),
            ((t, l + Md + 1), (t + Nd, r)),
            ((t + Nd + 1, l), (b, l + Md)),
            ((t + Nd + 1, l + Md + 1), (b, r)))
end

function rand_points(::Type{Int}, N, M, K)
    shuffle!([Iterators.product(1:N, 1:M)...])[1:min(M * N, K)]
end

function rand_sites(::Type{Int}, N, M, K)
    [(color, point) for (color, point) in enumerate(rand_points(Int, N, M, K))]
end

function rand_points(::Type{T}, N, M, K) where {T<:AbstractFloat}
    [(rand(Uniform(0, N)), rand(Uniform(0, M))) for k in 1:min(M * N, K)]
end

function rand_sites(::Type{T}, N, M, K) where {T<:AbstractFloat}
    [(color, point) for (color, point) in enumerate(rand_points(T, N, M, K))]
end

function equal_grid_points(grid1, grid2, points, distance)
    size(grid1) == size(grid2) || return false
    result = true
    for y in axes(grid1, 2), x in axes(grid1, 1)
        color1 = grid1[x, y]
        color2 = grid2[x, y]
        color1 == color2 || distance((x, y), points[color1]) ≈ distance((x, y), points[color2]) || (result = false)
    end
    return result
end

function equal_grid_sites(grid1, grid2, sites, distance)
    size(grid1) == size(grid2) || return false
    result = true
    for y in axes(grid1, 2), x in axes(grid1, 1)
        color1 = grid1[x, y]
        color2 = grid2[x, y]
        site1 = sites[findfirst(sites) do (color, _)
            color == color1
        end][2]
        site2 = sites[findfirst(sites) do (color, _)
            color == color2
        end][2]
        color1 == color2 || distance((x, y), site1) ≈ distance((x, y), site2) || (result = false)
    end
    return result
end
