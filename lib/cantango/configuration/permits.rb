module CanTango
  class Configuration
    class Permits < PermitRegistry
      include Singleton
      include CanTango::Helpers::Debug

      attr_reader :accounts
      attr_writer :enabled_types

      def enabled_types
        @enabled_types || available_types
      end
      alias_method :enabled, :enabled_types

      def available_permits
        @available_permits ||= default_permits
      end

      def available_types
        available_permits.keys
      end

      def available_classes
        available_permits.values.compact
      end

      def default_permits
        {}
      end

      def disable_types *types
        @enabled_types = available_types - types.flatten
      end
      alias_method :disable, :disable_types

      def enable_all_types!
        @enabled_types = available_types
      end

      def disable_for type, *names
        @disabled ||= {}
        @disabled[type.to_sym] = names.flatten.select_labels.map{|n| n.to_s.underscore}
      end

      def enable_all_for type
        @disabled ||= {}
        @disabled[type.to_sym] = nil
      end

      def disabled
        @disabled ||= {}
      end

      def disabled_for type
        disabled[type]
      end

      def enable_all!
        @disabled = {}
        enable_all_types!
      end

      def accounts
        @accounts ||= Hash.new
      end

      def account_hash name
        accounts[name]
      end

      def method_missing method_name, *args
        accounts[method_name] ||= PermitRegistry.new
      end

      def register permit_clazz, base_clazz, options = {}
        permit_name = options[:permit_name] || base_clazz.permit_name(permit_clazz)
        permit_type = options[:permit_type] || base_clazz.type
        account_name = options[:account_name] || base_clazz.account_name(permit_clazz)

        registry = account_name ? self.send(account_name.to_sym) : self
        debug "Registering #{permit_type} permit: #{permit_name} of class #{permit_clazz}"

        registry.get(permit_type)[permit_name] = permit_clazz
        # debug registry.get(permit_type).inspect
      end

      def allowed candidate, actions, subjects, *extra_args
        executed_for(candidate).inject([]) do |result, permit|
          result << permit.class if permit.can? actions, subjects, *extra_args
          result
        end
      end

      def denied candidate, actions, subjects, *extra_args
        executed_for(candidate).inject([]) do |result, permit|
          result << permit.class if permit.cannot? actions, subjects, *extra_args
          result
        end
      end

      def was_executed permit, ability
        executed_for(ability) << permit
      end

      def executed_for ability
        executed[hash_key_for(ability)] ||= []
      end

      def executed
        @executed ||= {}
      end

      def clear_executed!
        @executed = nil
      end

      protected

      def hash_key_for ability
        key_for(ability).value
      end

      def key_for ability
        ability.respond_to?(:subject) ? key_maker.create_for(ability) : key_maker.new(ability)
      end

      def key_maker
        CanTango::Ability::CacheKey
      end
    end
  end
end