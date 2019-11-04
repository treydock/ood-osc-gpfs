require File.expand_path '../spec_helper.rb', __FILE__

describe 'Application' do
  it 'should allow access to home page' do
    get '/'
    expect(last_response).to be_ok
  end

  it 'should have project and scratch filesystems' do
    get '/'
    expect(last_response.body).to match(%r{href="http://example.org/project"})
    expect(last_response.body).to match(%r{href="http://example.org/scratch"})
  end

  it 'should allow access to project page' do
    get '/project'
    expect(last_response).to be_ok
  end

  it 'should have filesets on project page' do
    get '/project'
    expect(last_response.body).to match(%r{href="http://example.org/project/root"})
  end

  it 'should allow access to scratch page' do
    get '/scratch'
    expect(last_response).to be_ok
  end

  it 'should have filesets on scratch page' do
    get '/scratch'
    expect(last_response.body).to match(%r{href="http://example.org/scratch/root"})
  end
end
