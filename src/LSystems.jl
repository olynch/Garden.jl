module LSystems

export TurtleOpF, Geom, Seq, Branch,
  TurtleOp, NT, Op,
  ConcreteTurtleOp, Concrete,
  DetLSystem, @lsystem,
  concretize,
  Instruction, Forwards, Turn, Ignore,
  interpret, runturtle

using MLStyle
using Cairo

const Expr0 = Union{Expr,Symbol,QuoteNode}

@data TurtleOpF{T,G} begin
  Geom(G)
  Seq(Vector{T})
  Branch(T)
end

function Base.map(f, op::TurtleOpF{T,G}) where {T,G}
  @match op begin
    Geom(g) => Geom{T,G}(g)
    Seq(ts) => Seq{T,G}(f.(ts))
    Branch(t) => Branch{T,G}(f(t))
  end
end

function bimap(f1, f2, T2, G2, op::TurtleOpF{T,G}) where {T,G}
  @match op begin
    Geom(g) => Geom{T2,G2}(f1(g))
    Seq(ts) => Seq{T2,G2}(f2.(ts))
    Branch(t) => Branch{T2,G2}(f2(t))
  end
end

function Base.show(io::IO, op::TurtleOpF)
  @match op begin
    Geom(g) => print(io, string(g))
    Seq(ts) => join(io,ts,";")
    Branch(t) => begin
      print(io,"[")
      show(io,t)
      print(io,"]")
    end
  end
end

@data ConcreteTurtleOp{G} begin
  Concrete(TurtleOpF{ConcreteTurtleOp{G},G})
end

@data TurtleOp begin
  NT(Symbol)
  Op(TurtleOpF{TurtleOp,Symbol})
end

function Base.show(io::IO, op::TurtleOp)
  @match op begin
    NT(t) => print(io,string(t))
    Op(op′) => show(io, op′)
  end
end
  
abstract type AbstractLSystem end

struct DetLSystem{G} <: AbstractLSystem
  prod::Dict{Symbol,TurtleOp}
  # For interpreting geometry at the end
  init::TurtleOp
  geoms::Dict{Symbol,G}
  nts::Dict{Symbol,G}
end

function (ls::DetLSystem)(op::TurtleOp)
  @match op begin
    NT(t) => ls.prod[t]
    Op(op) => Op(map(ls, op))
  end
end

function (ls::DetLSystem)(ope::Expr)
  ls(parse_op(keys(ls.prod), keys(ls.geoms), ope))
end


function strip_lines(expr::Expr; recurse::Bool=false)::Expr
  args = [ x for x in expr.args if !isa(x, LineNumberNode) ]
  if recurse
    args = [ isa(x, Expr) ? strip_lines(x; recurse=true) : x for x in args ]
  end
  Expr(expr.head, args...)
end

function strip_lines(s::Symbol; recurse::Bool=false)::Symbol
  s
end

function parse_op(nts::AbstractSet{Symbol}, geoms::AbstractSet{Symbol}, ope::Expr0) where {G}
  @match strip_lines(ope; recurse=true) begin
    (x::Symbol) =>
      if x ∈ nts
        NT(x)
      elseif x ∈ geoms
        Op(Geom{TurtleOp,Symbol}(x))
      else
        error("$x not a nonterminal or geom")
      end
    Expr(:block, lines...) => Op(Seq{TurtleOp,Symbol}(
      collect(map(ope′ -> parse_op(nts, geoms, ope′), lines))))
    Expr(:vect, arg) => Op(Branch{TurtleOp,Symbol}(
      parse_op(nts,geoms,arg)))
    Expr(:vcat, args...) => Op(Branch{TurtleOp,Symbol}(Op(Seq{TurtleOp,Symbol}(
        collect(map(ope′ -> parse_op(nts, geoms, ope′), args))))))
  end
end

function make_lsystem(geoms::Dict{Symbol,G}, nts::Dict{Symbol,G}, init::Expr0, rules::Dict{Symbol,Expr0}) where {G}
  DetLSystem{G}(
    Dict(k => parse_op(keys(rules), keys(geoms), r) for (k,r) in rules),
    parse_op(keys(rules), keys(geoms), init),
    geoms,
    nts,
  )
end

q(x) = Expr(:quote, x)

macro lsystem(head, block)
  block = strip_lines(block)
  geoms = Dict{Symbol,Expr0}()
  nts = Dict{Symbol,Expr0}()
  rules = Dict{Symbol,Expr0}()
  init = nothing
  for line in block.args
    @match line begin
      Expr(:macrocall, mname, _, name, val) => if mname == Symbol("@geom")
        geoms[name] = val
      elseif mname == Symbol("@nt")
        nts[name] = val
      else
        error("unsupported line in @lsystem: $line")
      end
      Expr(:macrocall, mname, _, val) => if mname == Symbol("@init")
        init = val
      else
        error("unsupported line in @lsystem: $line")
      end
      Expr(:call, :(=>), l, r) => begin
        rules[l] = r
      end
      _ => error("unsupported line in @lsystem: $line")
    end
  end
  esc(quote
        $(GlobalRef(LSystems, :make_lsystem))(
          Dict{Symbol,$head}($([:($(q(k)) => $(v)) for (k,v) in geoms]...)),
          Dict{Symbol,$head}($([:($(q(k)) => $(v)) for (k,v) in nts]...)),
          $(q(init)),
          Dict{Symbol,$(GlobalRef(LSystems, :Expr0))}(
            $([:($(q(k)) => $(q(v))) for (k,v) in rules]...)))
      end)
end

function concretize(ls::DetLSystem{G}, t::TurtleOp)::ConcreteTurtleOp{G} where {G}
  @match t begin
    NT(x) => Concrete{G}(Geom{ConcreteTurtleOp{G},G}(ls.nts[x]))
    Op(op) => Concrete{G}(bimap(g -> ls.geoms[g], t′ -> concretize(ls, t′),
                                ConcreteTurtleOp{G}, G, op))
  end
end

@data Instruction begin
  Forwards(Float64)
  Turn(Float64)
  Ignore
end

mutable struct TurtleState
  p::Vector{Float64}
  r::Vector{Float64}
end

Base.copy(t::TurtleState) = TurtleState(copy(t.p), copy(t.r))

function Base.copy!(t1::TurtleState, t2::TurtleState)
  t2.p = copy(t1.p)
  t2.r = copy(t1.r)
end

function TurtleState()
  TurtleState([0,0], [1,0])
end

rot(θ) = [cos(θ) sin(θ) ; -sin(θ) cos(θ)]

function interpret(op::ConcreteTurtleOp{Instruction}, ctx, s::TurtleState)
  @match op._1 begin
    Geom(g) => @match g begin
      Forwards(t) => begin
        p′ = s.p .+ t .* s.r
        move_to(ctx, s.p...)
        line_to(ctx, p′...)
        stroke(ctx)
        s.p = p′
      end
      Turn(r) => begin
        s.r = rot(r) * s.r
      end
      Ignore => nothing
    end
    Seq(ops) => map(op′ -> interpret(op′, ctx, s), ops)
    Branch(subop) => begin
      old_s = copy(s)
      interpret(subop, ctx, s)
      copy!(old_s, s)
    end
  end
end

function runturtle(op::ConcreteTurtleOp{Instruction}; w=500, h=500, fp="garden.png", scale=20)
  c = CairoRGBSurface(w,h);
  ctx = CairoContext(c);

  set_source_rgb(ctx,1,1,1)
  rectangle(ctx,0,0,w,h)
  fill(ctx)
  set_source_rgb(ctx,0,0,0)
  interpret(op, ctx, TurtleState([w/4,h/4], [scale,0]))

  write_to_png(c, "garden.png")
end

function iteratefn(f,v,n::Int)
  w = v
  for _ in 1:n
    w = f(w)
  end
  w
end

function runturtle(ls::DetLSystem{Instruction}; n=1, argv...)
  runturtle(concretize(ls, iteratefn(ls, ls.init, n)); argv...)
end

end
