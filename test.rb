require_relative 'genotype'
require_relative 'phenotype'
require_relative 'dot'

INPUTS = [[ 1, -1,   1],
          [-1,  1,   1],
          [ 1,  1,  -1],
          [-1, -1,  -1]]

inital = (1..24).map { Genotype.new inputs: 2, outputs: 1 }

$archtypes = Hash.new([])

def classify(genome)
  archtype = $archtypes.keys.find {|atype| (atype <=> genome) < 0.5 }
  unless archtype.nil?
    $archtypes[archtype] << genome
    return archtype
  else
    $archtypes[genome] = [genome]
    return genome
  end
end

def fitness(genome)
  INPUTS.inject(0) do |score, i|
    phenotype = Phenotype::Network.new genome: genome
    phenotype.eval(i[0..1])[0] == i[2] ? score + 1 : score
  end
end

def selection(pop, k)
  best = nil
  k.times do
    ind = pop[rand(0...pop.size)]
    best = ind if best.nil? or fitness(best) < fitness(ind)
  end
  best
end

pop = inital

200.times do
  new_pop = []
  while (new_pop.size < pop.size)
    p1 = selection(pop, 2)
    p2 = selection(pop, 2)
    c = p1 | p2
    new_pop += [p1, c]
  end
  pop = new_pop
end
puts inital.inspect
puts pop.inspect

pop.each do |g|
  puts "#{g.inspect} #{fitness(g)}"
end

pop.first.show_graph


