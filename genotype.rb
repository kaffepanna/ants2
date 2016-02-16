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

  attr_reader :connections, :inputs, :outputs, :nodes, :id
  DefaultArgs = { inputs: 4, outputs: 2 }
  C1 = 1.0
  C2 = 1.0
  C3 = 0.1

  def initialize args={}, &block
    args = DefaultArgs.merge(args)
    @@ids ||= 0
    @id = (@@ids+=1)
    @hidden = {}
    @inputs = (0...args[:inputs])
    @outputs = (@inputs.last...(@inputs.last+args[:outputs]))
    @nodes = (@inputs.first...(@outputs.last))
    @connections = []
    @inputs.each do |input|
      @outputs.each do |output|
        @connections << ConnectionGene.new(input, output, rand(-1.0..1.0))
      end
    end
    instance_eval &block if block_given?
  end

  def mutate!
    @connections.select { |c| c.enabled? }.each do |c|
      1.in(800) { add_node(c) }
      2.in(150) { mutate_weight(c) }
    end

    @nodes.each {|n| 1.in(800) { mutate_add_connection(n) } }
  end

  def |(gen2)
    gen1 = self
    offspring = Genotype.new inputs: self.inputs.size, outputs: self.outputs.size
    offspring.connections = (gen1.connections | gen2.connections).map {|c| c.dup }
    offspring.nodes = [gen1.nodes, gen2.nodes].max_by {|r| r.size }
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
  def nodes=(n)
    @nodes = n
  end

  def connections=(conns)
    @connections = conns
  end


  private
  def mutate_add_connection(node)
    n2 = rand(@nodes)
    p = @connections.find {|c| c.from == node && c.to == n2 }
    if p
      p.enable!
    else
      @connections << ConnectionGene.new(node, n2, rand(-1.0..1.0))
    end
  end

  def mutate_weight(connection)
    connection.weight += rand(-0.2..0.2)
    connection.weight = -1.0 if connection.weight > 1.0
    connection.weight = 1.0 if connection.weight < -1.0
  end

  def add_node connection
    connection.disable!
    @nodes = (@nodes.first...(@nodes.last+1))
    @connections << ConnectionGene.new(connection.from, @nodes.max, 1.0)
    @connections << ConnectionGene.new(@nodes.max, connection.to, connection.weight)
  end

  def next_node_id
    @nodes.map { |n| n.id }.max + 1
  end

end
