require 'test_helper'

class EthereumVmControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ethereum_vm_index_url
    assert_response :success
  end

end
