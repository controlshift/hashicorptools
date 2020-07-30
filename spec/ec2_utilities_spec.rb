require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Hashicorptools::Ec2Utilities, type: :helper do
  let(:including_class) { Class.new { include Hashicorptools::Ec2Utilities } }

  subject { including_class.new }

  describe '#ec2' do
    it 'should return a client' do
      client = subject.ec2
      expect(client).to be_a Aws::EC2::Client
    end
  end
end
