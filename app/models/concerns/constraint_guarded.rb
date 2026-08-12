module ConstraintGuarded
  extend ActiveSupport::Concern

  class_methods do
    def guard_constraint_error(field, message)
      define_method(:save) do |*args, **options|
        super(*args, **options)
      rescue ActiveRecord::StatementInvalid => error
        raise unless constraint_violation?(error)

        errors.add(field, message)
        false
      end

      define_method(:save!) do |*args, **options|
        super(*args, **options)
      rescue ActiveRecord::StatementInvalid => error
        raise unless constraint_violation?(error)

        errors.add(field, message)
        raise ActiveRecord::RecordInvalid, self
      end
    end
  end

  private

  def constraint_violation?(error)
    error.cause&.class&.name.in?(%w[PG::ExclusionViolation PG::UniqueViolation])
  end
end
