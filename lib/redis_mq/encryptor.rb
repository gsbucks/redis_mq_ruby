module RedisMQ
  class Encryptor

    def initialize(key, iv, key_size=128)
      @e_cipher = OpenSSL::Cipher::AES.new(key_size, :CBC)
      @e_cipher.encrypt
      @e_cipher.key = key
      @e_cipher.iv = iv

      @d_cipher = OpenSSL::Cipher::AES.new(key_size, :CBC)
      @d_cipher.decrypt
      @d_cipher.key = key
      @d_cipher.iv = iv
    end

    def encrypt(data)
      @e_cipher.reset
      @e_cipher.update(data) + @e_cipher.final
    end

    def decrypt(data)
      @d_cipher.reset
      @d_cipher.update(data) + @d_cipher.final
    end
  end

  class MockEncryptor
    def encrypt(data); data; end
    def decrypt(data); data; end
  end
end
