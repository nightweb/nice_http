require 'nice_http'

RSpec.describe NiceHttp, '#send_request' do

    before do
        @http = NiceHttp.new('https://www.reqres.in')
    end

    it 'returns error in case no method supplied on request hash' do
        resp = @http.send_request({})
        expect(resp.class).to eq Hash
        expect(resp.fatal_error).to include "it needs to be supplied a Request Hash"
        expect(resp.code).to eq nil
        expect(resp.message).to eq nil
    end

    it 'returns error in case no path supplied on request hash' do
        resp = @http.send_request({method: :get})
        expect(resp.class).to eq Hash
        expect(resp.fatal_error).to include "it needs to be supplied a Request Hash"
        expect(resp.code).to eq nil
        expect(resp.message).to eq nil
    end

    it 'returns error in case wrong method supplied on request hash' do
        resp = @http.send_request({path:'/', method: :wrong})
        expect(resp.class).to eq Hash
        expect(resp.fatal_error).to include "it needs to be supplied a Request Hash"
        expect(resp.code).to eq nil
        expect(resp.message).to eq nil
    end
    
    it 'returns a good response in case of :get method' do
        resp = @http.send_request({method: :get, path: '/api/users?page=2'})
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 200
        expect(resp.message).to eq "OK"
    end

    it 'returns a good response in case of :post method' do
        resp = @http.send_request({
            method: :post, 
            path: '/api/users', 
            data: {
              name: "morpheus",
              job: "leader"
            }
        })
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 201
        expect(resp.message).to eq "Created"
    end

    it 'returns a good response in case of :put method' do
        resp = @http.send_request({
            method: :put, 
            path: '/api/users/2', 
            data: {
              name: "morpheus",
              job: "leader"
            }
        })
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 200
        expect(resp.message).to eq "OK"
    end

    it 'returns a good response in case of :patch method' do
        resp = @http.send_request({
            method: :patch, 
            path: '/api/users/2', 
            data: {
              name: "morpheus",
              job: "leader"
            }
        })
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 200
        expect(resp.message).to eq "OK"
    end

    it 'returns a good response in case of :delete method' do
        resp = @http.send_request({method: :delete, path: '/api/users?page=2'})
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 204
        expect(resp.message).to eq "No Content"
    end

    it 'returns a good response in case of :head method' do
        resp = @http.send_request({method: :head, path: '/api/users?page=2'})
        expect(resp.class).to eq Hash
        expect(resp.code).to eq 200
        expect(resp.message).to eq "OK"
    end
end