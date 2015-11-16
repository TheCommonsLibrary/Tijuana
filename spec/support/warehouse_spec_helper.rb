module WarehouseSpecHelper
  def warehouse_data_should_include(expected_hash)
    warehouse_data = extract_warehouse_data
    expected_hash.keys.each do |k|
      expected = expected_hash[k]
      actual = warehouse_data[k]
      expected.should eql(actual), 
        "Warehouse data - expected key '#{k}' to have value '#{expected.inspect}' but was '#{actual.inspect}'"
    end
  end

private
  def extract_warehouse_data
    raise "Can only be used in controller tests" unless controller
    controller.instance_variable_get(:@warehouse_data)
  end
end

RSpec.configuration.include WarehouseSpecHelper