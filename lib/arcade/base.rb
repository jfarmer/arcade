module Arcade
  module Errors
    class NameError < StandardError;end
  end
end

module Arcade
  module Keyboard
    Gosu::Button.constants.each do |cons|
      if cons =~ /^Kb/
        self.const_set "Key" + cons.to_s.scan(/Kb(.*)/).flatten.first.to_s,
                       Gosu::Button.const_get(cons)
      end
    end
  end
end

class Arcade::Color < Gosu::Color
end

class Arcade::GameWindow < Gosu::Window
  def initialize width, height
    @current_time = Gosu::milliseconds
    @objects      = {}

    @keypress_listeners  = Hash.new { |h,k| h[k] = [] }

    super width, height, false
  end

  def add_object game_object
    game_object.keypress_listeners.each do |key, proc|
      self.add_listener key, game_object
    end

    @objects.merge! game_object.name => game_object
  end

  def register game_object
    game_object.window = self
    self.add_object(game_object)
  end

  def get_object object_name
    @objects[object_name]
  end

  def add_listener key, object
    @keypress_listeners[key] << object
  end

  def listened_keys
    @keypress_listeners.keys
  end

  def listeners_for_key key
    @keypress_listeners[key]
  end

  def draw
    each_object do |game_object|
      game_object.draw
    end
  end

  def update
    dt = (Gosu::milliseconds - @current_time) / 1000.0
    @current_time = Gosu::milliseconds

    self.listened_keys.each do |key|
      self.listeners_for_key(key).each do |listener|
        listener.key_pressed(key) if button_down?(key)
      end
    end

    each_object do |object|
      (@objects.values - [object]).each do |other|
        if object.collides_with?(other)
          object.collided_with(other)
        end
      end

      edge = if object.top < 0
               :top
             elsif object.bottom > self.height
               :bottom
             elsif object.left < 0
               :left
             elsif object.right > self.width
               :right
             end

      object.hit_edge(edge) if edge
    end

    each_object do |object|
      object._update(dt)
    end
  end

  def button_down id
  end

  def draw_square upper_left, width, height, color = Arcade::Color::WHITE
    x, y = upper_left

    draw_quad x,       y,        color,
              x+width, y,        color,
              x+width, y+height, color,
              x,       y+height,  color
  end

  private
  def each_object
    @objects.each do |name, object|
      yield object
    end
  end
end

class Arcade::GameObject
  PROPERTIES = [:x, :y, :height, :width, :color, :name, :velocity, :score]
  DEFAULTS   = {:color => Arcade::Color::WHITE,
                :velocity => Arcade::Velocity::ZERO}

  ALIASES = {:x_position => :x,
             :y_position => :y,
             :set_x_position => :x=,
             :set_y_position => :y=}

  attr_reader :window
  attr_reader :keypress_listeners

  def method_missing method, *args
    method = ALIASES.fetch(method) { method }

    mname = method.id2name

    if prop = mname.scan(/^set_(.+)/).flatten.first
      @state.send(:"#{prop}=", *args)
    else
      @state.send(method, *args).tap do |val|
        warn "WARNING: Called #{self.class}##{method}, but it returned nil. You should set a default value." if val.nil?
      end
    end
  end

  class << self
    def set_defaults &block
      @default_block = block
    end

    def has_defaults?
      !@default_block.nil?
    end

    def defaults
      @default_block
    end
  end

  def setup_defaults
    DEFAULTS.each do |prop, val|
      self.send(:"#{prop}=", val)
    end

    if self.class.has_defaults?
      instance_exec &self.class.defaults
    end
  end

  def initialize &block
    @state = OpenStruct.new
    @keypress_listeners  = {}
    @collision_listeners = {}
    @edge_callback       = nil

    setup_defaults
    instance_exec &block

    # Every GameObject must have a name
    raise Arcade::Errors::NameError, "#{self.class}#name is nil" if self.name.nil?
  end

  def get_object object_name
    window.get_object object_name
  end

  def draw
    window.draw_square [self.x, self.y], self.width, self.height, self.color
  end

  def window= game_window
    @window = game_window
  end

  def _update dt
    unless self.velocity.zero?
      self.x += self.velocity.element(0)
      self.y += self.velocity.element(1)
    end

    if self.respond_to? :update
      self.update(dt)
    end
  end

  def top
    self.y
  end

  def bottom
    self.y + height
  end

  def left
    self.x
  end

  def right
    self.x + width
  end

  def move_up pixels
    self.y -= pixels
  end

  def move_down pixels
    self.y += pixels
  end

  def move_left pixels
    self.x -= pixels
  end

  def move_right pixels
    self.x += pixels
  end

  def on_keypress key, &block
    @keypress_listeners[key] = block
  end

  def key_pressed key
    instance_eval &@keypress_listeners[key]
  end

  def can_collide_with? klass
    @collision_listeners.has_key? klass
  end

  def on_collides_with klass, &block
    @collision_listeners[klass] = block
  end

  def collided_with other
    klass = other.class
    if self.can_collide_with?(klass)
      instance_exec other, &@collision_listeners[klass]
    end
  end

  def collides_with? other
    if !other.kind_of?(Arcade::GameObject) || other == self
      false
    else
      !(bottom < other.top ||
        top > other.bottom ||
        right < other.left ||
        left > other.right)
    end
  end

  def on_hit_edge &block
    @edge_callback = block
  end

  # One of :top, :bottom, :left, or :right
  def hit_edge edge
    if @edge_callback
      instance_exec edge, &@edge_callback
    end
  end
end
