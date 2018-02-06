require_relative 'probability'

class Genotype

  NodeGene = Struct.new :id
  Inovations = {}

  class ConnectionGene
    attr_reader :from, :to
    attr_accessor :weight
    def initialize from, to, weight
      @enabled = true
      @from = from
      @to = to
      @weight = weight
    end

    def enabled?; @enabled; end
    def disable!; @enabled = false; end
    def enable!; @enabled = true; end

    def hash
      (from.to_s + to.to_s).hash
    end

    def inovation
      Genotype.get_inovation self
    end

    def eql? (g)
      self.inovation == g.inovation
    end
  end

  def Genotype.get_inovation conn
    Inovations[conn.hash] ||
      Inovations[conn.hash] = (Inovations.values.max || 0) + 1
  end

  attr_reader :connections, :hidden, :inputs, :outputs, :nodes, :id, :bias
  DefaultArgs = { inputs: 2,
                  outputs: 1,
                  weight_span: (-4.0..4.0),
                  mutation: {
                    weights_modify_rate: 0.05,
                    weights_swap_rate: 0.01,
                    connections_rate: 0.01,
                    nodes_rate: 0.01
                  }
                }
  C1 = 1.0
  C2 = 1.0
  C3 = 0.08

  def initialize args={}
    @settings = DefaultArgs.merge(args)
    @id = @@ids ||= 0
    @@ids+=1
    @inputs = (0...@settings[:inputs])
    @outputs = (@settings[:inputs]...(@settings[:inputs]+@settings[:outputs]))
    @bias = @settings[:inputs] + @settings[:outputs]
    @hidden = ((@bias+1)...(@bias+1))
    
    @connections = []
    @inputs.each do |input|
      @outputs.each do |output|
        @connections << ConnectionGene.new(input, output, rand(@settings[:weight_span]))
      end
    end

    @outputs.each do |output|
      @connections << ConnectionGene.new(bias, output, rand(@settings[:weight_span]))
    end
  end
  
  def nodes
    (@inputs.first...@hidden.last)
  end

  def mutate!
    @settings[:mutation][:nodes_rate].chance {
      add_node(@connections.select {|c| c.enabled?}.sample)
    }

    @settings[:mutation][:weights_modify_rate].chance {
      mutate_weight @connections.select {|c| c.enabled? }.sample
    }

    @settings[:mutation][:connections_rate].chance {
      mutate_add_connection(nodes.to_a.sample)
    }
    self
  end

  def |(gen2)
    gen1 = self
    offspring = Genotype.new inputs: self.inputs.size, outputs: self.outputs.size
    offspring.connections = (gen1.connections | gen2.connections).map {|c| c.dup }
    offspring.hidden = [gen1.hidden, gen2.hidden].max_by {|r| r.size }
    offspring.mutate!
    return offspring
  end

  def <=> (g2)
    min_len = [@connections.size, g2.connections.size].min
    max_len = [@connections.size, g2.connections.size].max
    d = (@connections.take(min_len) - g2.connections.take(min_len)).size/max_len.to_f
    e = (@connections.size - g2.connections.size).abs/max_len.to_f
    w =@connections.zip(g2.connections).take(min_len).inject(0) {|res, conns|
      a,b = conns
      res + (a.weight-b.weight).abs
    }/min_len.to_f

    C1*e + C2*d + C3*w
  end

  def inspect
    ">>#{@id}<<"
  end

  protected

  def hidden=(h)
    @hidden = h
  end

  def connections=(conns)
    @connections = conns
  end


  private
  def mutate_add_connection(node)
    n2 = rand(nodes)
    return if n2 == bias
    return if n2 == node
    return if @outputs.include?(node)
    return if @inputs.include?(n2) && @inputs.include?(node)
    return if @hidden.include?(n2) && @hidden.include?(node) # only ff
    p = @connections.find {|c| c.from == node && c.to == n2 }
    if p
      p.enable!
    else
      @connections << ConnectionGene.new(node, n2, rand(@settings[:weight_span]))
    end
  end

  def mutate_weight(connection)
    # TODO: Clamp to weight_span
    connection.weight += rand(-0.2..0.2)
    @settings[:mutation][:weights_swap_rate].chance {
      connection.weight = rand(@settings[:weight_span])
    }
  end

  def add_node connection
    return if connection.from == bias
    return if @hidden.include?(connection.from)
    return if @hidden.include?(connection.to)
    connection.disable!
    @hidden = (@hidden.first...(@hidden.last+1))
    @connections << ConnectionGene.new(@bias, nodes.max, rand(@settings[:weight_span]))
    @connections << ConnectionGene.new(connection.from, nodes.max, rand(@settings[:weight_span]))
    @connections << ConnectionGene.new(nodes.max, connection.to, connection.weight)
  end

end
