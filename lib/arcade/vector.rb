class Arcade::Velocity < Vector
  HORIZ_REFLECT = Matrix[[-1,0], [0,1]]
  VERT_REFLECT  = Matrix[[1,0], [0,-1]]

  ZERO = Arcade::Velocity[0,0]

  def reflect_horizontally
    Arcade::Velocity[*(HORIZ_REFLECT * self).to_a]
  end

  def reflect_vertically
    Arcade::Velocity[*(VERT_REFLECT * self).to_a]
  end

  def zero?
    self.eql? ZERO
  end
end
