require 'thread'
require_relative 'genotype'

module Phenotype
  class Node
    Edge = Struct.new :from, :weight
    DefaultArgs = {
      id: 1,
      value: 0,
      #transfer: proc {|v| v > 0 ? 1.0 : -1.0 }
      transfer: proc { |v| 1.0 / (1.0 + Math::E**(-v)) }
      #transfer: proc { |x| Math::tanh(x) }
    }

    attr_reader :edges
    attr_accessor :value

    def initialize attr = {}
      attr = DefaultArgs.merge(attr)
      @edges = []
      @transfer = attr[:transfer]
      @semaphore = Mutex.new
      @value = attr[:value]
      @evaluated = false
    end

    def >> args
      weight, to = args
      to.edges << Edge.new(self, weight)
      to
    end

    def << args
      weight, from = args
      self.edges << Edge.new(from, weight)
      self
    end

    def evaluated?; @evaluated; end
    def reset!
       @evaluated = false
       @value = 0.0
    end

    def call
      return value if evaluated? || @semaphore.owned?
      @semaphore.synchronize do
        return value if evaluated?
        value = @transfer.call(edges.inject(0) { |res, e|
          res + e.weight*e.from.call
        })
        @evaluated = true
        return value
      end
    end
  end

  class Network
    DefaultArgs = {
      genotype: Genotype.new(inputs: 2, outputs: 1)
    }

    attr_accessor :genotype
    attr_reader :nodes

    def initialize attr = {}
      attr = DefaultArgs.merge(attr)
      @bias = Node.new(id: "bias", value: 1)
      @genotype = attr[:genotype]
      @nodes = @genotype.nodes.map { |n| Node.new(id: n) }
      @genotype.connections.each {|c|
        @nodes[c.from] >> [c.weight, @nodes[c.to]]
      }

      # adds input edge to actual input
      @nodes[@genotype.inputs].each_with_index { |n,i|
        n << [1.0, proc { @inputs[i]}]
      }

      nodes[@genotype.inputs.last...@genotype.nodes.last].each {|n|
        n << [1.0, proc { 1.0 }]
      }
    end

    def eval(args)
      @nodes.each {|n| n.reset! }
      @inputs = args
      @nodes[@genotype.outputs].map {|n| n.call }
    end
  end
end
