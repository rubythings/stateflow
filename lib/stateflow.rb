module Stateflow
  def self.included(base)
    base.send :include, InstanceMethods
    Stateflow::Persistence.set(base)
    base.extend ClassMethods
  end
  
  def self.persistence
    @@persistence ||= :active_record
  end
  
  def self.persistence=(persistence)
    @@persistence = persistence
  end
  
  module ClassMethods
    attr_reader :machine
    
    def stateflow(&block)
      @machine = Stateflow::Machine.new(&block)
      
      @machine.states.values.each do |state|
        state_name = state.name
        define_method "#{state_name}?" do
          state_name == current_state.name
        end
      end
      
      @machine.events.keys.each do |key|
        define_method "#{key}!" do
          fire_event(key)
        end
      end
    end
  end
  
  module InstanceMethods
    def current_state  
      @current_state ||= load_from_persistence.nil? ? machine.initial_state : machine.states[load_from_persistence.to_sym]
    end
    
    def current_state=(new_state)
      save_to_persistence(new_state.name.to_s)
      @current_state = new_state
    end
    
    def machine
      self.class.machine
    end
    
    private
    def fire_event(event)
      event = machine.events[event.to_sym]
      raise Exception.new("No event matches #{event}") if event.nil?
      event.fire(current_state, self)
    end
  end
  
  autoload :Machine, 'stateflow/machine'
  autoload :State, 'stateflow/state'
  autoload :Event, 'stateflow/event'
  autoload :Transition, 'stateflow/transition'
  autoload :Persistence, 'stateflow/persistence'
end
