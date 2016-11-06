class ApplicationViewModel
  attr_reader :model, :options

  def self.wrap(input, options = {})
    if input.is_a?(Enumerable)
      input.map { |i| new(i, options) }
    else
      new(input, options)
    end
  end

  def initialize(model = nil, options = {})
    @model   = model
    @options = options.with_indifferent_access
  end

  def method_missing(method, *args, &block)
    if model && model.respond_to?(method)
      # Define a method so the next call is faster
      self.class.send(:define_method, method) do |*args, &blok|
        model.send(method, *args, &blok)
      end

      send(method, *args, &block)
    else
      super
    end

  rescue NoMethodError => no_method_error
    super if no_method_error.name == method
    raise no_method_error
  end

  def respond_to?(*args)
    super || (model && model.respond_to?(*args))
  end

  def to_param
    model.to_param
  end

  def to_model
    model
  end

  def present?
    model.present?
  end

  def blank?
    model.blank?
  end

  def nil?
    model.nil?
  end

  def ==(other)
    (other.class == self.class && other.id == id) || other == model
  end
end
