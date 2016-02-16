class Genotype
  def to_dot
    conns = connections.select { |c| c.enabled? }
    hidden = nodes.to_a[outputs.last..-1] || []
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
    }
  EOF
  end

  def show_graph
    fork do
      dot_read, dot_write = IO.popen("dot -Tpng | feh -", "w") {|io|
        io.write(to_dot)
      }
    end
  end
end

