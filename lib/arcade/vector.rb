class Arcade::Velocity < Vector
  HORIZ_REFLECT = Matrix[[1,0], [0,-1]]
  VERT_REFLECT  = Matrix[[-1,0], [0,0]]

  ZERO = Arcade::Velocity[0,0]

  def reflect_horizontally
    HORIZ_REFLECT * self
  end

  def reflect_vertically
    VERT_REFLECT * self
  end

  def zero?
    self.eql? ZERO
  end
end
