// md5_orig implementation courtesy of
// https://stackoverflow.com/questions/32163848/how-to-convert-string-to-md5-hash-using-ios-swift
// originally from
// http://iosdeveloperzone.com/2014/10/03/using-commoncrypto-in-swift/
// implicitly released under the CC by-SA license
func md5_orig(_ string: String) -> String {
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

import CryptoKit

// md5_new implementation courtesy of
// https://stackoverflow.com/questions/69491476/cc-md5-is-deprecated-first-deprecated-in-ios-13-0-this-function-is-cryptogr
// implicitly released under the CC by-SA license
@available(iOS 13.0, *)
func md5_new(_ string: String) -> String {
    let data = string.data(using: .utf8)!
    let digestData = Insecure.MD5.hash(data: data)
    let digestHex = String(digestData.map { String(format: "%02hhx", $0) }.joined().prefix(32))
    return digestHex
}

func md5(_ string: String) -> String {
    if #available(iOS 13.0, *) {
        return md5_new(string)
    } else {
        return md5_orig(string)
    }
}
