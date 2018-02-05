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

    Legend [shape=none, margin=0, label=<
    <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
     <TR>
      <TD COLSPAN="2"><B>Legend</B></TD>
     </TR>
     <TR>
      <TD>Foo</TD>
      <TD><FONT COLOR="red">Foo</FONT></TD>
     </TR>
    </TABLE>
   >];
  }
  EOF
  end

  def show_graph
    fork do
      #IO.popen("dot -Tpng -O", "w") { |io|
      #  io.write(to_dot)
      #}
      dot_read, dot_write = IO.popen("dot -Tpng | feh -", "w") {|io|
        io.write(to_dot)
      }
    end
  end
end

