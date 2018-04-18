
require 'pqueue'

class Subset
    attr_accessor :parent, :identifier, :rank

    def initialize(parent, identifier, rank)
        @parent = parent
        @identifier = identifier
        @rank = rank
    end
end

class Edge
    attr_accessor :origin, :destiny, :weight

    def initialize(edge)
        @origin = edge['origin']
        @destiny = edge['destiny']
        @weight = edge['weight']
    end
end

class MST
    attr_accessor :graph, :num_vertex, :index_result,
                  :result, :subsets, :heap

    def initialize(json_graph)
        @graph = json_graph
        @num_vertex = @graph['vertex'].length
        @index_result = 0
        @result = []
        @subsets = []
        @heap = []
    end

    def get_mst
        build_heap
        build_subsets

        while index_result < num_vertex - 1
            edge = self.heap.pop
            origin = find(edge.origin)['parent']
            destiny = find(edge.destiny)['parent']

            if origin != destiny
                self.result.push(edge)
                union(origin, destiny)
                self.index_result += 1
            end
        end

        to_json_graph
    end

    def build_heap
        (graph['edges']).each do |edge|
            self.heap.push(Edge.new(edge))
        end

        self.heap = PQueue.new(heap) { |a, b| a.weight < b.weight }
    end

    def build_subsets
        (0...num_vertex).each do |i|
            parent = identifier = graph['vertex'][i]
            rank = 0
            subsets.push(Subset.new(parent, identifier, rank))
        end
    end

    def find(vertex_name)
        subset = 0

        while subset < subsets.length
            break if subsets[subset].identifier == vertex_name
            subset += 1
        end

        if subsets[subset].parent != vertex_name
            bundle = find(subsets[subset].parent)
            subsets[subset].parent = bundle['parent']
            subset = bundle['set']
        end

        return {'parent' => subsets[subset].parent, 'set' => subset}
    end

    def union(origin, destiny)
        bundle_origin = find(origin)
        bundle_destiny = find(destiny)
        set_origin = bundle_origin['set']
        set_destiny = bundle_destiny['set']

        if subsets[set_origin].rank < subsets[set_destiny].rank
            subsets[set_origin].parent = bundle_destiny['parent']

        elsif subsets[set_origin].rank > subsets[set_destiny].rank
            subsets[set_destiny].parent = bundle_origin['parent']

        else
            subsets[set_destiny].parent = bundle_origin['parent']
            subsets[set_origin].rank += 1
        end
    end

    def to_json_graph
        graph = []

        (result).each do |edge|
            json = Hash.new
            json['origin'] = edge.origin
            json['destiny'] = edge.destiny
            json['weight'] = edge.weight
            graph.push(json)
        end

        graph
    end

    private :build_heap, :build_subsets, :find, :union
end
