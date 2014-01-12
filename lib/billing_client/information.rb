require 'pkwde/field_initialisation'
require 'active_model'
require 'active_model/validations'
require 'digest/md5'
require 'tins/xt/full'
require 'json'

# use it like this:
# info = BillingClient::Information.for("12345", "Caroo GmbH", "Wesselinger Str. 28", "50999", "Köln").self_regulated.
#   pay_by_debit.assign_account("123456789", "Caroo GmbH", "987654321", "Sparkasse Köln/Bonn").invoice_to_email("email@pkw.de")

module BillingClient
  class Information
    include ActiveModel::Validations
    attr_accessor :debitor, :regulator, :debit, :delivery_method, :bank_account, :debitor_is_regulator, :delivery_email, :contract_identifier

    validates_presence_of :debitor, :contract_identifier, :delivery_email, :delivery_method
    validates_presence_of :regulator, :unless => :debitor_is_regulator
    validates_presence_of :bank_account, :if => :debit
    validates_inclusion_of :delivery_method, :in => %w( letter email )
    validates_inclusion_of :debit, :in => [true, false]
    validates_each :debitor, :regulator, :bank_account do |record, attribute, value|
      unless (attribute == :regulator && record.debitor_is_regulator) || (attribute == :bank_account && record.debit == false)
        record.errors.add(attribute, :invalid) if value && !value.valid?
      end
    end

    def initialize
      @debitor_is_regulator = false
    end

    def self.for(identifier, name, street, zip, city)
      instance = new
      instance.debitor = BillingUser.new(identifier, name, street, zip, city)
      instance
    end

    def regulated_by(identifier, name, street, zip, city)
      self.regulator = BillingUser.new(identifier, name, street, zip, city)
      self
    end

    def with_contract_identifier(contract_identifier)
      self.contract_identifier = contract_identifier
      self
    end

    def self_regulated
      self.debitor_is_regulator = true
      self
    end

    def pay_by_debit
      self.debit = true
      self
    end

    def pay_by_money_transfer
      self.debit = false
      self
    end

    def invoice_by_letter
      self.delivery_method = "letter"
      self
    end

    def invoice_by_email
      self.delivery_method = "email"
      self
    end

    def invoice_to_email(email)
      self.delivery_email = email
      self
    end

    def assign_account(number, owner, bank_code, bank_name)
      ActiveSupport::Deprecation.warn("After February 2014, the sepa debit is used! Use assign_sepa_account instead")
      self.bank_account = BankAccount.new(number, owner, bank_code, bank_name)
      self
    end

    ##
    # Used to assign an bank account used by the sepa system
    def assign_sepa_account(iban, bic, owner, bank_name = nil, number = nil, bank_code = nil )
      self.bank_account = BankAccount.sepa(iban, bic, owner, bank_name, number, bank_code)
      self
    end

    def self.version
      @@version ||= Digest::MD5.hexdigest(File.read(__FILE__))
    end

    def self.valid_version?(v)
      version == v
    end

    def as_json(*)
      {
        :debitor_identifier   => debitor.full?(:identifier),
        :debitor_name         => debitor.full?(:name),
        :debitor_street       => debitor.full?(:street),
        :debitor_zip          => debitor.full?(:zip),
        :debitor_city         => debitor.full?(:city),
        :contract_identifier  => contract_identifier,
        :regulator_identifier => regulator.full?(:identifier),
        :regulator_name       => regulator.full?(:name),
        :regulator_street     => regulator.full?(:street),
        :regulator_zip        => regulator.full?(:zip),
        :regulator_city       => regulator.full?(:city),
        :debit                => debit,
        :debit_account_number => bank_account.full?(:number),
        :debit_account_owner  => bank_account.full?(:owner),
        :debit_bank_code      => bank_account.full?(:bank_code),
        :debit_bank_name      => bank_account.full?(:bank_name),
        :debit_iban           => bank_account.full?(:iban),
        :debit_bic            => bank_account.full?(:bic),
        :delivery_method      => delivery_method,
        :delivery_email       => delivery_email,
        :version              => self.class.version
      }
    end

    def to_json(*)
      as_json.to_json
    end
  end

  class BillingUser
    include ActiveModel::Validations
    attr_accessor :identifier, :name, :street, :zip, :city
    validates_presence_of :identifier, :name, :street, :zip, :city
    def initialize(identifier, name, street, zip, city)
      @identifier, @name, @street, @zip, @city = identifier, name, street, zip, city
    end
  end

  class BankAccount
    include ActiveModel::Validations
    attr_accessor :number, :owner, :bank_code, :bank_name, :iban, :bic, :sepa

    validates_presence_of :number, :owner, :bank_code, :bank_name, unless: :sepa
    validates_presence_of :iban, :bic, :owner, if: :sepa

    def initialize(number, owner, bank_code, bank_name, iban = nil, bic = nil)
      @sepa = false
      @number, @owner, @bank_code, @bank_name, @iban, @bic = number, owner, bank_code, bank_name, iban, bic
    end

    def self.sepa(iban, bic, owner, bank_name = nil, number = nil, bank_code = nil)
      account = new(number, owner, bank_code, bank_name, iban, bic)
      account.sepa = true
      account
    end
  end
end