module Flowers

export quadratic_koch_island, quadratic_snowflake_curve,
  dragon_curve

using ..LSystems

quadratic_koch_island = @lsystem Instruction begin
  @geom (+) Turn(pi/2)
  @geom (-) Turn(-pi/2)
  @nt A Forwards(1)
  @init (A;-;A;-;A;-;A)
  A => (A;+;A;A;-;A;A;-;A;-;A;+;A;+;A;
        A;-;A;-;A;+;A;+;A;A;+;A;A;-;A)
end

quadratic_snowflake_curve = @lsystem Instruction begin
  @geom (+) Turn(pi/2)
  @geom (-) Turn(-pi/2)
  @nt A Forwards(1)
  @init (-;A)
  A => (A;+;A;-;A;-;A;+;A)
end

dragon_curve = @lsystem Instruction begin
  @geom (+) Turn(pi/2)
  @geom (-) Turn(-pi/2)
  @nt A Forwards(1)
  @init (A;-;A;-;A;-;A)
  A => (A;-;A;+;A;-;A;-;A)
end

fass_curve = @lsystem Instruction begin
  @geom (+) Turn(pi/2)
  @geom (-) Turn(-pi/2)
  @geom F Forwards(1)
  @nt L Ignore
  @nt R Ignore
  @init (-;L)
  L => (L;F;+;R;F;R;+;F;L;-;F;-;L;F;L;F;L;-;F;R;F;R;+)
  R => (-;L;F;L;F;+;R;F;R;F;R;+;F;+;R;F;-;L;F;L;-;F;R)
end

basic_frond = @lsystem Instruction begin
  @geom (+) Turn(pi/9)
  @geom (-) Turn(-pi/9)
  @nt F Forwards(1)
  @init F
  F => (F;[+;F];F;[-;F];[F])
end

end
