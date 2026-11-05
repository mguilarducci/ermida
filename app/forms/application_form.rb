# Base class for form objects: input for one screen that may write several models. A subclass declares its
# attributes and validations and implements `submit!`; `save` validates, then runs `submit!` in a transaction.
# `save` is true once that transaction commits, whatever `submit!` returns.
class ApplicationForm
  include ActiveModel::API
  include ActiveModel::Attributes

  define_callbacks :save, only: :after
  define_callbacks :commit, only: :after

  class << self
    def after_save(...) = set_callback(:save, :after, ...)

    def after_commit(...) = set_callback(:commit, :after, ...)

    # AccountForm submits `account[...]` params and reads the Account translations.
    def model_name
      @model_name ||= ActiveModel::Name.new(self, nil, name.delete_suffix("Form"))
    end
  end

  delegate :model_name, to: :class

  def save
    if valid?
      with_transaction do
        AfterCommitEverywhere.after_commit { run_callbacks(:commit) }
        run_callbacks(:save) { submit! }
      end
      true
    else
      false
    end
  end

  private

  def with_transaction(&) = ApplicationRecord.transaction(&)

  def submit! = raise NotImplementedError
end
