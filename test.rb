require_relative 'genotype'
require_relative 'phenotype'
require_relative 'dot'


XOR= [[1, 0, 1],
      [0, 1, 1],
      [1, 1, 0],
      [0, 0, 0]]

AND= [[1, 0, 0],
      [0, 1, 0],
      [1, 1, 1],
      [0, 0, 0]]

INPUTS = XOR

$archtypes = []

class Numeric
  def sign
    self < 0 ? :'+' : :'-'
  end
end

def classify(genome)
  archtype = $archtypes.find {|atype| (atype <=> genome) < 0.4 }
  unless archtype.nil?
    return archtype
  else
    $archtypes << genome
    return genome
  end
end

def sigmoid(v) 
  v > 0 ? 1.0 : -1.0
end

def fitness(genome)
  phenotype = Phenotype::Network.new genotype: genome
  INPUTS.inject(4) do |score, i|
    res = phenotype.eval(i[0..1])[0]
    score -= (i[2] - res) ** 2
  end
end

def selection(pop, k)
  top = pop.take(k)
  top.sample
end

popsize = 10
inital = (1..popsize).map { Genotype.new inputs: 2, outputs: 1 }
populations = Hash.new { |hsh, key| hsh[key] = [] }

inital.each do |g|
  c = classify(g)
  populations[classify(g)] << g
end

initial_best = inital.sort_by {|b| fitness(b)}.last
p = Phenotype::Network.new genotype: initial_best
puts "Fitness #{fitness(initial_best)}"
INPUTS.each do |i|
  puts "#{i.inspect} #{p.eval(i[0..1])[0]}"
end

400.times do
  new_pops = Hash.new { |hsh, key| hsh[key] = [] }
  populations.each_pair do |arch, pop|
    scored_pop = pop.sort_by {|b| fitness(b) }.reverse

    while (new_pops[arch].size < popsize)
      p1 = selection(scored_pop, 4)
      p2 = selection(scored_pop, 4)
      c = p1 | p2
      c_arch = classify(c)
      new_pops[arch] << p1 unless new_pops[arch].include? p1
      if c_arch == arch
        new_pops[c_arch] << c
      elsif new_pops[c_arch].empty?
        new_pops[c_arch] << c
      end
    end
  end
  populations = new_pops
end

populations.each_value do |pop|
  pop_sorted = pop.sort_by { |b| fitness(b) }
  phenotype = Phenotype::Network.new genotype: pop_sorted.last
  puts "Fitness #{fitness(pop.last)}"
  INPUTS.each do |i|
    puts "#{pop.last.inspect} #{i[0..1].inspect} #{i[2]}  = #{phenotype.eval(i[0..1])[0]}"
  end
  pop_sorted.last.show_graph
  gets
end




