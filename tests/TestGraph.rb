require 'test/unit'
require 'rgl/adjacency'
require 'test_helper'

include RGL

class TestGraph < Test::Unit::TestCase

  def setup
    @dg = DirectedAdjacencyGraph.new
    @edges = [[1,2],[2,3],[2,4],[4,5],[1,6],[6,4]]
    @edges.each do |(src,target)| 
      @dg.add_edge(src, target)
    end

    @ug = AdjacencyGraph.new(Array)
    @ug.add_edges(*@edges)
  end

  def test_equality
    assert @dg == @dg
    assert @dg == @dg.dup
    assert @ug == @ug.dup
    assert @ug != @dg
    assert @dg != @ug
    assert @dg != 42
    dup = DirectedAdjacencyGraph[*@edges.flatten]
    assert @dg == dup
    @dg.add_vertex 42
    assert @dg != dup
  end

  def test_merge
    merge = DirectedAdjacencyGraph.new(Array, @dg, @ug)
    assert merge.num_edges == 12
    merge = DirectedAdjacencyGraph.new(Set, @dg, @dg)
    assert merge.num_edges == 6
  end

end