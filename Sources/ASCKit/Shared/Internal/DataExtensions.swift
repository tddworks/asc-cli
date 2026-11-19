import CryptoKit
import Foundation
import zlib

extension Data {
    var md5HexString: String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func gunzipped() throws -> Data {
        guard !isEmpty else { throw GzipError.dataEmpty }

        var stream = z_stream()
        stream.next_in = UnsafeMutablePointer<Bytef>(mutating: (self as NSData).bytes.bindMemory(to: Bytef.self, capacity: count))
        stream.avail_in = uInt(count)

        // windowBits 15 + 32 enables automatic gzip/zlib header detection
        guard inflateInit2_(&stream, 15 + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else {
            throw GzipError.initFailed
        }
        defer { inflateEnd(&stream) }

        var decompressed = Data()
        let bufferSize = 65_536
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while true {
            stream.next_out = buffer
            stream.avail_out = uInt(bufferSize)
            let status = inflate(&stream, Z_NO_FLUSH)

            switch status {
            case Z_OK, Z_BUF_ERROR:
                let outputCount = bufferSize - Int(stream.avail_out)
                decompressed.append(buffer, count: outputCount)
            case Z_STREAM_END:
                let outputCount = bufferSize - Int(stream.avail_out)
                decompressed.append(buffer, count: outputCount)
                return decompressed
            default:
                throw GzipError.inflateFailed(status: status)
            }
        }
    }
}

public enum GzipError: Error {
    case dataEmpty
    case initFailed
    case inflateFailed(status: Int32)
}
