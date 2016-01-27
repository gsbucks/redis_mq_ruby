require 'spec_helper'

describe RedisMQ::RPC do
  describe '::package' do
    subject { described_class.package(method, params) }

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

      it { is_expected.to eq(['meth', nil]) }
    end

    context 'request with params' do
      let(:response) {{
        jsonrpc: '2.0',
        method: 'meth',
        params: [1],
        id: 'blahblah1234'
      }.to_json }

      it { is_expected.to eq(['meth', [1]]) }
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
