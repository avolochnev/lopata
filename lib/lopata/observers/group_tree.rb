module Lopata
  GroupTree = Struct.new(:group, :items, :title) do
    def status
      # return @status if @status
      statuses = items.map(&:status).uniq
      @status = 
        if statuses.length == 1
          statuses.first
        elsif statuses.include?(:failed)
          :failed
        elsif 
          statuses.first
        end
      @status
    end

    # Returns steps hierarhy: Group with nestet setps or groups
    def self.steps_hierarhy(steps)
      top = GroupTree.new(nil, [], '')
      hierarhy = [top]
      current_groups = []
      steps.each do |step|
        if step.groups == current_groups
          hierarhy.last.items << step
        else
          # ensure hierarhy to is in current step tree - remove from hierary all groups not in new tree.
          while hierarhy.last.group && !step.groups.include?(hierarhy.last.group)
            hierarhy.pop
          end
          if hierarhy.last.group == step.groups.last
            hierarhy.last.items << step
          else
            group_rest = step.groups.dup
            while hierarhy.last.group && group_rest.first != hierarhy.last.group
              group_rest.shift
            end
            group_rest.shift if group_rest.first == hierarhy.last.group
            group_rest.each do
              title = (hierarhy.map(&:group).compact + [_1]).map(&:title).join(': ')
              group = GroupTree.new(_1, [], title)
              hierarhy.last.items << group
              hierarhy << group
            end
            hierarhy.last.items << step
          end
          current_groups = step.groups
        end
      end
      return top
    end

    def walk_through(&block)
      items.each do |step|
        if step.is_a?(Lopata::StepExecution)
          yield step
        else # GroupTree
          group = step
          go_dipper = yield group
          group.walk_through(&block) if go_dipper
        end
      end
    end
  end
end
