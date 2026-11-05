require "test_helper"

class ApplicationFormTest < ActiveSupport::TestCase
  class GreetingForm < ApplicationForm
    attribute :name, :string
    validates :name, presence: true

    attr_reader :events

    after_save { events << :saved }
    after_commit { events << :committed }

    def initialize(...)
      super
      @events = []
    end

    private

    def submit!
      events << :submitted
      Business.create!(name:, description: "From a form.")
    end
  end

  test "the model name drops the Form suffix, so params and translations use the resource name" do
    assert_equal "ApplicationFormTest::Greeting", GreetingForm.model_name.name
    assert_equal "application_form_test_greeting", GreetingForm.model_name.param_key
  end

  test "an invalid form does not submit and returns false" do
    form = GreetingForm.new(name: "")

    assert_not form.save
    assert_empty form.events
    assert_equal 0, Business.count
  end

  test "a valid form submits, runs after_save, and runs after_commit once the transaction commits" do
    form = GreetingForm.new(name: "Padaria")

    assert form.save
    assert_equal %i[submitted saved committed], form.events
    assert_equal 1, Business.count
  end

  test "a valid form saves even when submitting returns nothing" do
    form = GreetingForm.new(name: "Padaria")
    form.define_singleton_method(:submit!) { nil }

    assert form.save
  end

  test "a failure while submitting rolls back everything the form wrote" do
    form = GreetingForm.new(name: "Padaria")
    form.define_singleton_method(:submit!) do
      Business.create!(name:, description: "From a form.")
      raise ActiveRecord::RecordInvalid, Business.new
    end

    assert_raises(ActiveRecord::RecordInvalid) { form.save }
    assert_equal 0, Business.count
    assert_not_includes form.events, :committed
  end
end
