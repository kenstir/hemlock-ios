// MD5 implelementation courtesy of
// https://stackoverflow.com/questions/32163848/how-to-convert-string-to-md5-hash-using-ios-swift
// originally from
// http://iosdeveloperzone.com/2014/10/03/using-commoncrypto-in-swift/
// implicitly released under the CC by-SA license

func md5(_ string: String) -> String {
    let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
    var digest = Array<UInt8>(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    CC_MD5_Init(context)
    CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
    CC_MD5_Final(&digest, context)
    context.deallocate()
    var hexString = ""
    for byte in digest {
        hexString += String(format:"%02x", byte)
    }
    return hexString
}
