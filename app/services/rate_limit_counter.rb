# Rack::Ratelimit counter backed by the database so it works with any
# Rails.cache store (memory/null stores do not support #increment).
class RateLimitCounter
  def initialize(name)
    @name = name
  end

  def increment(classification, epoch)
    counter = find_or_create(classification, epoch)
    counter.increment!(:count).count
  end

  private

  def find_or_create(classification, epoch)
    RatelimitCounter.find_by(name: @name, classification: classification, epoch: epoch) ||
      create(classification, epoch)
  end

  def create(classification, epoch)
    RatelimitCounter.create!(name: @name, classification: classification, epoch: epoch, count: 0)
  rescue ActiveRecord::RecordNotUnique
    RatelimitCounter.find_by(name: @name, classification: classification, epoch: epoch)
  end
end
