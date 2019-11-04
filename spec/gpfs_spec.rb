require File.expand_path '../spec_helper.rb', __FILE__
require File.expand_path '../../gpfs.rb', __FILE__

RSpec.shared_examples "filesystem" do |f|
  let(:filesystem) { f }
  let(:gpfs) do
    GPFS.new(filesystem)
  end
  let(:quotas) do
    gpfs.user_quotas('root')
  end

  it 'should have filesets' do
    expect(gpfs.filesets.size).to be > 0
  end

  it 'should have Hash of filesets' do
    expect(gpfs.filesets.key?('root')).to eq(true)
    fileset = gpfs.filesets['root']
    expect(fileset).to have_attributes(name: 'root')
  end

  it 'should have fileset quota' do
    quota = gpfs.fileset_quota('root')
    expect(quota).to have_attributes(name: 'root')
  end

  it 'should have user quotas' do
    expect(quotas.class).to be Array
    expect(quotas.size).to be > 0
  end

  it 'should have user quotas with username' do
    #quota = quotas.select { |q| q.username == 'root' }
    #expect(quota).to have_attributes(name: 'root')
    expect(quotas[0].respond_to?(:username)).to eq(true)
  end
end

describe GPFS do
  describe 'project filesets' do
    include_examples "filesystem", "scratch"
  end

  describe 'scratch filesets' do
    include_examples "filesystem", "scratch"
  end
end

