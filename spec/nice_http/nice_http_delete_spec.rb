require 'nice_http'

RSpec.describe NiceHttp, '#delete' do

    before do
        @http = NiceHttp.new('https://www.reqres.in')
    end

    it 'accepts path as string parameter' do
        resp = @http.delete '/api/users/2'
        expect(resp.code).to eq 204
    end

    it 'accepts Hash with key path' do
        resp = @http.delete({path: '/api/users/2'})
        expect(resp.code).to eq 204
    end

    it 'returns error in case no path in hash' do
        resp = @http.delete({})
        expect(resp.class).to eq Hash
        expect(resp.fatal_error).to match /no[\w\s]+path/i
        expect(resp.code).to eq nil
        expect(resp.message).to eq nil
        expect(resp.data).to eq nil
    end

    it 'returns the mock response if specified' do
        @http.use_mocks = true
        request = {
            path: '/api/users/2',
            mock_response: {
                code: 100,
                message: "mock",
                data: { example: "mock" }
            }
        }
        resp = @http.delete(request)
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 100
        expect(resp.message).to eq 'mock'    
        expect(resp.data.json).to eq ({ example: "mock" }) 
    end

    it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
        server = "http://examplesinatra--tcblues.repl.co/"
        http = NiceHttp.new(server)
        http.auto_redirect = false
        req = {
            path: '/exampleRedirect',
            data: {example: 'example'},
        }
        resp = http.delete(req)
        expect(resp.code).to eq 303
    end

end
