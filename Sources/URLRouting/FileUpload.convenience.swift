//
//  Multipart.FileUpload.convenience.swift
//  swift-multipart-form-coding
//
//  Created by Coen ten Thije Boonkkamp on 29/12/2024.
//

import Foundation

extension FileUpload {
    public static func csv(
        fieldName: String = "file",
        filename: String? = nil,
        maxSize: Measurement<UnitInformationStorage> = FileUpload.maxFileSize
    ) throws -> Self {
        try .init(
            fieldName: fieldName,
            filename: filename ?? "file.csv",
            fileType: .csv,
            maxSize: maxSize
        )
    }

    public static func pdf(
        fieldName: String = "file",
        filename: String? = nil,
        maxSize: Measurement<UnitInformationStorage> = FileUpload.maxFileSize
    ) throws -> Self {
        try .init(
            fieldName: fieldName,
            filename: filename ?? "file.pdf",
            fileType: .pdf,
            maxSize: maxSize
        )
    }

    public static func excel(
        fieldName: String = "file",
        filename: String? = nil,
        maxSize: Measurement<UnitInformationStorage> = FileUpload.maxFileSize
    ) throws -> Self {
        try .init(
            fieldName: fieldName,
            filename: filename ?? "file.xlsx",
            fileType: .excel,
            maxSize: maxSize
        )
    }

    public static func jpeg(
        fieldName: String = "file",
        filename: String? = nil,
        maxSize: Measurement<UnitInformationStorage> = FileUpload.maxFileSize
    ) throws -> Self {
        try .init(
            fieldName: fieldName,
            filename: filename ?? "file.jpg",
            fileType: .image(.jpeg),
            maxSize: maxSize
        )
    }
}
