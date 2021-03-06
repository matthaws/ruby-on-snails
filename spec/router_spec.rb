require 'rack'
require 'xanthus'

describe Route do
  let(:req) { Rack::Request.new({'rack.input' => {}}) }
  let(:res) { Rack::MockResponse.new('200', {}, []) }

  before(:each) do
    allow(req).to receive(:request_method).and_return('GET')
  end

  describe '#matches?' do
    it 'matches simple regular expression' do
      index_route = Route.new(Regexp.new('^/users$'), :get, 'x', :x)
      allow(req).to receive(:path) { '/users' }
      allow(req).to receive(:request_method) { 'GET' }
      expect(index_route.matches?(req)).to be_truthy
    end

    it 'matches regular expression with capture' do
      index_route = Route.new(Regexp.new('^/users/(?<id>\\d+)$'), :get, 'x', :x)
      allow(req).to receive(:path) { '/users/1' }
      allow(req).to receive(:request_method) { 'GET' }
      expect(index_route.matches?(req)).to be_truthy
    end

    it 'correctly doesn\'t match regular expression with capture' do
      index_route = Route.new(Regexp.new('^/users/(?<id>\\d+)$'), :get, 'UsersController', :index)
      allow(req).to receive(:path) { '/statuses/1' }
      allow(req).to receive(:request_method) { 'GET' }
      expect(index_route.matches?(req)).to be_falsey
    end
  end
end

describe Router do
  let(:req) { Rack::Request.new({'rack-input' => {}}) }
  let(:res) { Rack::MockResponse.new('200', {}, []) }

  describe '#add_route' do
    it 'adds a route' do
      subject.add_route(1, 2, 3, 4)
      expect(subject.routes.count).to eq(1)
      subject.add_route(1, 2, 3, 4)
      subject.add_route(1, 2, 3, 4)
      expect(subject.routes.count).to eq(3)
    end
  end

  describe '#match' do
    it 'matches a correct route' do
      subject.add_route(Regexp.new('^/users$'), :get, :x, :x)
      allow(req).to receive(:path) { '/users' }
      allow(req).to receive(:request_method) { 'GET' }
      matched = subject.match(req)
      expect(matched).not_to be_nil
    end

    it 'doesn\'t match an incorrect route' do
      subject.add_route(Regexp.new('^/users$'), :get, :x, :x)
      allow(req).to receive(:path) { '/incorrect_path' }
      allow(req).to receive(:request_method) { 'GET' }
      matched = subject.match(req)
      expect(matched).to be_nil
    end
  end

  describe '#run' do
    it 'sets status to 404 if no route is found' do
      subject.add_route(Regexp.new('^/users$'), :get, :x, :x)
      allow(req).to receive(:path).and_return('/incorrect_path')
      allow(req).to receive(:request_method).and_return('GET')
      subject.run(req, res)
      expect(res.status).to eq(404)
    end
  end

  describe 'http method (get, put, post, delete)' do
    it 'adds methods get, put, post and delete' do
      router = Router.new
      expect((router.methods - Class.new.methods)).to include(:get)
      expect((router.methods - Class.new.methods)).to include(:put)
      expect((router.methods - Class.new.methods)).to include(:post)
      expect((router.methods - Class.new.methods)).to include(:delete)
    end

    it 'adds a route when an http method method is called' do
      router = Router.new
      router.get Regexp.new('^/users$'), ControllerBase, :index
      expect(router.routes.count).to eq(1)
    end
  end

  describe '#draw' do
    it 'calls http method methods with the route information to add the route' do
      index_route = double('route')
      post_route = double('route')

      routes = Proc.new do
        get index_route
        post post_route
      end

      router = Router.new

      expect(router).to receive(:get).with(index_route)
      expect(router).to receive(:post).with(post_route)

      router.draw(&routes)
    end
  end
end
