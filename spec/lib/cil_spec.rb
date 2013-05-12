require 'ec2-mini/cli'

describe EC2Mini::CLI do
  describe '#initialize' do
    it "don't input option is failure" do
      expect{ EC2Mini::CLI.new({}) }.to raise_error
      expect{ EC2Mini::CLI.new({ 'access_key_id' => 'access_key_id' }) }.to raise_error
    end
    it "inputs option is failure" do
      expect(
        EC2Mini::CLI.new({
          "access_key_id" => "ACCESS_KEY_ID",
          "secret_access_key" => "SECRET_ACCESS_KEY",
          "region" => "REGION"
        }).class
      ).to eq EC2Mini::CLI
    end
    it "don't exist config file is failure" do
        expect{ EC2Mini::CLI.new(nil, '') }.to raise_error
    end
    it "exists config file is success" do
      # TODO ENV['PWD']
      expect(EC2Mini::CLI.new(nil, "#{ENV['PWD']}/spec/support/.ec2-mini").class).to eq EC2Mini::CLI
    end
  end
end
