require 'rgl/dijkstra_visitor'
require 'rgl/edge_weights_map'
require 'rgl/path_builder'

require 'delegate'
require 'algorithms'

module RGL

  class DijkstraAlgorithm

    # Initializes Dijkstra algorithm for a _graph_ with provided edges weights map.
    #
    def initialize(graph, edge_weights_map, visitor)
      @graph            = graph
      @edge_weights_map = NonNegativeEdgeWeightsMap.new(edge_weights_map, @graph.directed?)
      @visitor          = visitor
    end

    # Finds the shortest path from the _source_ to the _target_ in the graph.
    #
    # Returns the shortest path, if it exists, as an Array of vertices. Otherwise, returns nil.
    #
    def shortest_path(source, target)
      init(source)
      relax_edges(target, true)
      PathBuilder.new(source, @visitor.parents_map).path(target)
    end

    # Finds the shortest path form the _source_ to every other vertex of the graph.
    #
    # Returns the shortest paths map that contains the shortest path (if it exists) from the source to any vertex of the
    # graph.
    #
    def shortest_paths(source)
      init(source)
      relax_edges
      PathBuilder.new(source, @visitor.parents_map).paths(@graph.vertices)
    end

    private

    def init(source)
      @visitor.set_source(source)

      @queue = Queue.new
      @queue.push(source, @visitor.distance_map[source])
    end

    def relax_edges(target = nil, break_on_target = false)
      until @queue.empty?
        u = @queue.pop

        break if break_on_target && u == target

        @visitor.handle_examine_vertex(u)

        @graph.each_adjacent(u) do |v|
          relax_edge(u, v) unless @visitor.finished_vertex?(v)
        end

        @visitor.color_map[u] = :BLACK
        @visitor.handle_finish_vertex(u)
      end
    end

    def relax_edge(u, v)
      @visitor.handle_examine_edge(u, v)

      new_v_distance = @visitor.distance_map[u] + @edge_weights_map.edge_weight(u, v)

      if new_v_distance < @visitor.distance_map[v]
        old_v_distance = @visitor.distance_map[v]

        @visitor.distance_map[v] = new_v_distance
        @visitor.parents_map[v]  = u

        if @visitor.color_map[v] == :WHITE
          @visitor.color_map[v] = :GRAY
          @queue.push(v, new_v_distance)
        elsif @visitor.color_map[v] == :GRAY
          @queue.decrease_key(v, old_v_distance, new_v_distance)
        end

        @visitor.handle_edge_relaxed(u, v)
      else
        @visitor.handle_edge_not_relaxed(u, v)
      end
    end

    class Queue < SimpleDelegator # :nodoc:

      def initialize
        @heap = Containers::Heap.new { |a, b| a.distance < b.distance }
        super(@heap)
      end

      def push(vertex, distance)
        @heap.push(vertex_key(vertex, distance), vertex)
      end

      def decrease_key(vertex, old_distance, new_distance)
        @heap.change_key(vertex_key(vertex, old_distance), vertex_key(vertex, new_distance))
      end

      def vertex_key(vertex, distance)
        VertexKey.new(vertex, distance)
      end

      VertexKey = Struct.new(:vertex, :distance)

    end

  end # class DijkstraAlgorithm

  module Graph

    # Finds the shortest path from the _source_ to the _target_ in the graph.
    #
    # If the path exists, returns it as an Array of vertices. Otherwise, returns nil.
    #
    # Raises ArgumentError if edge weight is negative or undefined.
    #
    def dijkstra_shortest_path(edge_weights_map, source, target, visitor = DijkstraVisitor.new(self))
      DijkstraAlgorithm.new(self, edge_weights_map, visitor).shortest_path(source, target)
    end

    # Finds the shortest paths from the _source_ to each vertex of the graph.
    #
    # Returns a Hash that maps each vertex of the graph to an Array of vertices that represents the shortest path
    # from the _source_ to the vertex. If the path doesn't exist, the corresponding hash value is nil. For the _source_
    # vertex returned hash contains a trivial one-vertex path - [source].
    #
    # Raises ArgumentError if edge weight is negative or undefined.
    #
    def dijkstra_shortest_paths(edge_weights_map, source, visitor = DijkstraVisitor.new(self))
      DijkstraAlgorithm.new(self, edge_weights_map, visitor).shortest_paths(source)
    end

  end # module Graph

end # module RGL
