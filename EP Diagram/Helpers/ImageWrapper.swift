//
//  ImageWrapper.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// Extend Codable to store images
struct ImageWrapper: Codable {
    let image: UIImage?

    enum CodingKeys: String, CodingKey {
        case image
        case null
    }

    init(image: UIImage?) {
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nullImage = try container.decode(Bool.self, forKey: .null)
        if nullImage {
            self.image = nil
            return
        }
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        guard let image = UIImage(data: data) else {
            throw FileIOError.decodingFailed
        }
        self.image = image
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard let image = image else {
            try container.encode(true, forKey: .null)
            return
        }
        try container.encode(false, forKey: .null)
        // We somewhat arbitrarily choose a jpeg file format (alternative is png).
        // At this point I don't know that there is any advantage, except probably jpeg is smaller.
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            throw FileIOError.encodingFailed
        }
        try container.encode(data, forKey: CodingKeys.image)
    }
}
