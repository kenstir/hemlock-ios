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
    return md5_new(string)
}
