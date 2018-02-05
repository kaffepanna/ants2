require_relative 'genotype'
require_relative 'phenotype'
require_relative 'dot'
require 'fileutils'


XOR= [[1, -1, 1],
      [-1, 1, 1],
      [1, 1, -1],
      [-1, -1, -1]]

AND= [[1, -1, -1],
      [-1, 1, -1],
      [1, 1, 1],
      [-1, -1, -1]]

INPUTS = XOR

$archtypes = []

class Numeric
  def sign
    self < 0 ? :'+' : :'-'
  end
end

def to_dot(node, data, result, fitness)
  inputs = node.inputs
  outputs = node.outputs
  conns = node.connections.select { |c| c.enabled? }
  hidden = node.nodes.to_a[node.outputs.last..-1] || []
  <<-EOF
digraph G {
    rankdir=LR
    splines=line

    subgraph {
      rank = same;
      node [style=solid,color=blue4, shape=circle];
      #{inputs.to_a.join(';')};
      label = "Input Layer";
    }
    subgraph {
      node [style=solid,color=red2, shape=circle];
      rank = same;
      #{(hidden).join(';')+(hidden.empty? ? "" : ";")}
      label = "Hidden Layer";
    }
    subgraph {
      rank = same;
      node [style=solid,color=seagreen2, shape=circle];
      #{outputs.to_a.join(';')};
      label = "Output Layer";
    }
  #{ conns.map {|c| "#{c.from} -> #{c.to}[label=#{c.weight.round(2)}]" }.join("\n")}

    Legend [shape=none, margin=0, label=<
    <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
     <tr>
       <td>fitness</td><td >#{fitness}</td>
     </tr>
  #{ data.zip(result).map {|vv| "<tr><td>#{vv.first.inspect}</td><td>#{vv.last}</td></tr>" }.join("\n") }
    </TABLE>
   >];
  }
  EOF
end

def classify(genome)
  archtype = $archtypes.find {|atype| (atype <=> genome) < 0.5 }
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
    score - (i[2] - res).abs
  end
end

def selection(pop, k)
  top = pop.take(k)
  top.sample
end

def eval_genome(g)
  phenotype = Phenotype::Network.new genotype: g
  INPUTS.map do |i|
    phenotype.eval(i[0..1])[0]
  end
end

def write_dot(d, file)
  IO.popen("dot -Tpng > \"#{file}\"", "w") {|io|
    io.write(d)
  }
end

winners = []
popsize = 40
iterations = 150
inital = (1..popsize).map { Genotype.new inputs: 2, outputs: 1 }
populations = Hash.new { |hsh, key| hsh[key] = [] }

root = Time.now.to_s
FileUtils.mkdir(root)

inital.each do |g|
  c = classify(g)
  populations[c] << g
end

iterations.times do |i|
  new_pops = Hash.new { |hsh, key| hsh[key] = [] }
  winners[i] = []
  populations.each_pair do |arch, pop|
    scored_pop = pop.sort_by {|b| fitness(b) }.reverse

    winners[i] << scored_pop.first

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
  print "#{i} "
  populations = new_pops
end
print "\n"

latest = winners.last(10)
latest.each_index do |i|
  FileUtils.mkdir(File.join(root, i.to_s))
  latest[i].each do |winner|
    winner_score = fitness(winner)
    winner_result = eval_genome(winner)
    dot = to_dot(winner, INPUTS, winner_result, winner_score)
    write_dot(dot, File.join(root, i.to_s, "#{winner.inspect}.png"))
  end
end
