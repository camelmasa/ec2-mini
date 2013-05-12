require 'ec2-mini/cli'

describe EC2Mini::CLI do
  describe '#initialize' do
    context 'not exist config file' do
      it "is failure" do
        expect{ EC2Mini::CLI.new(nil, '') }.to raise_error
      end
    end
    context 'exist config file' do
      it "is success" do
        # TODO ENV['PWD']
        expect(EC2Mini::CLI.new(nil, "#{ENV['PWD']}/spec/support/.ec2-mini").class).to eq EC2Mini::CLI
      end
    end
  end
end
