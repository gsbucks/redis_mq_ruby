require 'spec_helper'

describe RedisMQ::RPC do
  describe '::package_error' do
    let(:id) { 'anything' }
    subject { described_class.package_error(id, Exception.new('some message')) }
    it { is_expected.to match([
           /{"jsonrpc":"2\.0"/,
           /"id":"#{id}"/,
           /"error":{"code":1,"message":"some message","data":/
         ].join(',') )
    }
  end

  describe '::package_request' do
    subject { described_class.package_request(method, params) }

    context 'proper method and params objects' do
      let(:method) { 'goats' }
      let(:params) { [1,2] }
      it { expect(subject[0]).to match(/[[:alnum:]]{32}/) }
      it { expect(subject[1]).to match([
          /{"jsonrpc":"2\.0"/,
          /"method":"#{method}"/,
          /"params":#{Regexp.quote(params.to_json)}/,
          /"id":"[[:alnum:]]{32}"}/
        ].join(','))
      }
    end
  end

  describe '::unpackage_request' do
    let(:result) { 'Stuff!' }
    subject { described_class.unpackage_request(response) }

    context 'no params' do
      let(:response) {{
        jsonrpc: '2.0',
        method: 'meth',
        id: 'blahblah1234'
      }.to_json }

      it { expect(subject.method).to eq('meth') }
      it { expect(subject.id).to eq('blahblah1234') }
      it { expect(subject.params).to be_nil }
    end

    context 'request with params' do
      let(:response) {{
        jsonrpc: '2.0',
        method: 'meth',
        params: [1],
        id: 'blahblah1234'
      }.to_json }

      it { expect(subject.params).to eq([1]) }
    end
  end

  describe '::package_result' do
    let(:id)     { '123' }
    let(:result) { 'Stuff!' }
    let(:response) {{
      jsonrpc: '2.0',
      result: result,
      id: id
    }}
    subject { described_class.package_result(id, result) }

    context 'missing ID' do
      let(:id) { '' }
      it { expect{ subject }.to raise_error ArgumentError }
    end

    context 'valid args' do
      it { is_expected.to eq(response.to_json) }
    end
  end

  describe '::unpackage_result' do
    let(:result) { 'Stuff!' }
    subject { described_class.unpackage_result(response) }

    context 'valid response' do
      let(:response) {{
        jsonrpc: '2.0',
        result: result,
        id: 'blahblah1234'
      }.to_json }

      it { is_expected.to eq(result) }
    end
  end
end
