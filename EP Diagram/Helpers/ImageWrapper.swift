//
//  ImageWrapper.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct ImageWrapper: Codable {
    let image: UIImage?

    enum CodingKeys: String, CodingKey {
        case image
    }

    init(image: UIImage?) {
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        guard let image = UIImage(data: data) else {
            throw FileIOError.decodingFailed
        }
        self.image = image
    }

    public func encode(to encoder: Encoder) throws {
        guard let image = image else { return }
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            throw FileIOError.encodingFailed
        }
        try container.encode(data, forKey: CodingKeys.image)
    }
}
