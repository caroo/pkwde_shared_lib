# encoding: UTF-8
require 'test_helper'
require 'billing_client'

class InformationTest < Test::Unit::TestCase
  include BillingClient
  def test_should_debitor_validation
    info = Information.new
    assert_equal false, info.valid?
    assert_equal true, info.errors[:debitor].any?
    
    info = Information.for(nil, nil, nil, nil, nil)
    assert_equal false, info.valid?
    assert_equal true, info.errors[:debitor].any?
    
    info = Information.for(*%w[identifier name street zip city])
    assert_equal false, info.valid?
    assert_equal false, info.errors[:debitor].any?
    
    assert_equal "identifier", info.debitor.identifier
    assert_equal "name", info.debitor.name
    assert_equal "street", info.debitor.street
    assert_equal "zip", info.debitor.zip
    assert_equal "city", info.debitor.city
  end
  
  def test_regulator_validation
    info = Information.for(*%w[identifier name street zip city])
    assert_equal false, info.valid?
    assert_equal true, info.errors[:regulator].any?
    info.self_regulated
    assert_equal false, info.valid?
    assert_equal false, info.errors[:regulator].any?
    
    info = Information.for(*%w[identifier name street zip city])
    info.regulated_by(nil, nil, nil, nil, nil)
    assert_equal false, info.valid?
    assert_equal true, info.errors[:regulator].any?
    info.regulated_by(*%w[reg_identifier reg_name reg_street reg_zip reg_city])
    assert_equal false, info.valid?
    assert_equal false, info.errors[:regulator].any?
    assert_equal "reg_identifier", info.regulator.identifier
    assert_equal "reg_name", info.regulator.name
    assert_equal "reg_street", info.regulator.street
    assert_equal "reg_zip", info.regulator.zip
    assert_equal "reg_city", info.regulator.city
  end
  
  def test_bank_account_validation
    info = Information.for(*%w[identifier name street zip city])
    assert_equal false, info.valid?
    assert_equal false, info.errors[:bank_account].any?
    
    info.pay_by_debit
    assert_equal false, info.valid?
    assert_equal true, info.errors[:bank_account].any?
    
    info.assign_account(nil, nil, nil, nil)
    assert_equal false, info.valid?
    assert_equal true, info.errors[:bank_account].any?
    
    info.assign_account(*%w[number owner bank_code bank_name])
    assert_equal false, info.valid?
    assert_equal false, info.errors[:bank_account].any?
    assert_equal "number", info.bank_account.number
    assert_equal "owner", info.bank_account.owner
    assert_equal "bank_code", info.bank_account.bank_code
    assert_equal "bank_name", info.bank_account.bank_name
  end
  
  def test_debit_validation
    info = Information.new
    info.debit = "hallo"
    assert_equal false, info.valid?
    assert_equal true, info.errors[:debit].any?
    
    info.pay_by_money_transfer
    assert_equal false, info.valid?
    assert_equal false, info.errors[:bank_account].any?
    assert_equal false, info.errors[:debit].any?
    
    info.pay_by_debit
    assert_equal false, info.valid?
    assert_equal false, info.errors[:debit].any?
    assert_equal true, info.errors[:bank_account].any?
  end
  
  def test_delivery_method_validation
    info = Information.new
    info.delivery_method = "hallo"
    assert_equal false, info.valid?
    assert_equal true, info.errors[:delivery_method].any?
    
    info.invoice_by_letter
    assert_equal false, info.valid?
    assert_equal false, info.errors[:delivery_method].any?
    
    info.invoice_to_email(nil)
    assert_equal false, info.valid?
    assert_equal true, info.errors[:delivery_email].any?
    
    info.invoice_to_email("aa@bb.cc")
    assert_equal false, info.valid?
    assert_equal false, info.errors[:delivery_email].any?
  end
  
  def test_contract_identifier_validation
    info = Information.new
    assert_equal false, info.valid?
    assert_equal true, info.errors[:contract_identifier].any?
    
    info.with_contract_identifier("1234567890")
    assert_equal false, info.valid?
    assert_equal false, info.errors[:contract_identifier].any?
  end
  
  def test_valid
    info = Information.for("deb_number", "deb_name", "deb_street", "deb_zip", "deb_city").
      self_regulated.
      with_contract_identifier("abcdefg").
      pay_by_money_transfer.
      invoice_by_letter
    assert_equal true, info.valid?
  end
  
  def test_should_have_version_method_and_track_file_changes
    assert version = BillingClient::Information.version
    assert_kind_of String, version
  end
  
  def test_as_json
    info = Information.for("deb_number", "deb_name", "deb_street", "deb_zip", "deb_city").
      regulated_by("reg_number", "reg_name", "reg_street", "reg_zip", "reg_city").
      with_contract_identifier("abcdefg").
      pay_by_debit.
      assign_account("account_number", "account_owner", "bank_code", "bank_name").
      invoice_to_email("aa@bb.cc")
    assert_equal true, info.valid?
    json_hash = info.as_json
    assert_equal "deb_number",        json_hash[:debitor_identifier]
    assert_equal "deb_name",          json_hash[:debitor_name]
    assert_equal "deb_street",        json_hash[:debitor_street]
    assert_equal "deb_zip",           json_hash[:debitor_zip]
    assert_equal "deb_city",          json_hash[:debitor_city]
    assert_equal "reg_number",        json_hash[:regulator_identifier]
    assert_equal "reg_name",          json_hash[:regulator_name]
    assert_equal "reg_street",        json_hash[:regulator_street]
    assert_equal "reg_zip",           json_hash[:regulator_zip]
    assert_equal "reg_city",          json_hash[:regulator_city]
    assert_equal true,                json_hash[:debit]
    assert_equal "abcdefg",           json_hash[:contract_identifier]
    assert_equal "account_number",    json_hash[:debit_account_number]
    assert_equal "account_owner",     json_hash[:debit_account_owner]
    assert_equal "bank_code",         json_hash[:debit_bank_code]
    assert_equal "bank_name",         json_hash[:debit_bank_name]
    assert_equal "email",             json_hash[:delivery_method]
    assert_equal "aa@bb.cc",          json_hash[:delivery_email]
    version = BillingClient::Information.version
    assert_equal version,             json_hash[:version]
    assert_equal 19,                  json_hash.size
    assert info.to_json
  end
end