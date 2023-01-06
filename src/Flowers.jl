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
  @geom Red Color(0.9,0.1,0.1)
  @geom Purple Color(0.7,0.1,0.7)
  @nt A Forwards(1)
  @nt B Forwards(1)
  @init (Purple;A;-;Red;B;-;Purple;A;-;Red;B)
  A => (Purple;A;-;Red;B;+;Purple;A;-;Red;B;-;A)
  B => (Red;B;-;Purple;A;+;Red;B;-;Purple;A;-;B)
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
  @geom (+) Turn(pi/3)
  @geom (-) Turn(-pi/3)
  @geom d Turn(pi/18)
  @geom nd Turn(-pi/18)
  @nt F Forwards(1)
  @init F
  F => (F;[+;F];d;F;[-;F];nd;F)
end

end
